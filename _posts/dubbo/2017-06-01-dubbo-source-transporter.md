---
layout: post
title: Dubbo 源码分析 - 传输层
---

Dubbo的传输层有三个类组成：Transporter、Server和Client。Transporter作为工厂类，Server和Client负责具体实现。

传输层的默认实现是Netty，对应三个类：NettyTransporter、NettyServer和NettyClient。

{% highlight java %}
public class NettyTransporter implements Transporter {
    
    public Server bind(URL url, ChannelHandler listener) throws RemotingException {
        return new NettyServer(url, listener);
    }

    public Client connect(URL url, ChannelHandler listener) throws RemotingException {
        return new NettyClient(url, listener);
    }
}
{% endhighlight %}


---

### Server 服务端



---

### Client 客户端

NettyClient是Client的Netty实现。

{% highlight java %}
public class NettyClient extends AbstractClient {
    
    public AbstractPeer(URL url, ChannelHandler handler) {
        // AbstractPeer
        this.url = url;
        this.handler = handler;

        // AbstractEndpoint
        this.codec = ExtensionLoader.getExtensionLoader(Codec2.class).getExtension(codecName);

        // AbstractClient
        doOpen();
        connect();
    }
}
{% endhighlight %}

doOpen()和doConnect()是两个关键方法，它们负责开启netty连接。

{% highlight java %}
protected void doOpen() throws Throwable {
    NettyHelper.setNettyLoggerFactory();

    bootstrap = new ClientBootstrap(channelFactory);
    bootstrap.setOption("keepAlive", true);
    bootstrap.setOption("tcpNoDelay", true);
    bootstrap.setOption("connectTimeoutMillis", getTimeout());

    // nettyHandler会加到ChannelPipeline最后面
    // NettyClient实现了dubbo.ChannelHandler接口
    // NettyHandler在这里包装了NettyClient
    // 经过这样处理后：
    //   当netty有新连接过来时，
    //   首先被nettyHandler接收到，因为nettyHandler加到了ChannelPipeline
    //   然后nettyHandler根据接收到的jboss.channel创建dubbo.channel，通过getOrAddChannel(jboss.channel)
    //   将dubbo.channel添加到nettyHandler.channels
    //   最后调用nettyClient.channelConnected()，在nettyHandler里面通过handler.channelConnected()传递
    // 参考后面的《NettyHandler》

    final NettyHandler nettyHandler = new NettyHandler(getUrl(), this);


    // 注意这里的channels
    // 因为nettyHandler.getChannels()是直接返回内部的channels
    // 所以这里的nettyClient.channels和nettyHandler.channels是同一个引用
    
    channels = nettyHandler.getChannels();

    bootstrap.setPipelineFactory(new ChannelPipelineFactory() {
        public ChannelPipeline getPipeline() {
            ChannelPipeline pipeline = Channels.pipeline();

            // getCodec()返回codec实例，在AbstractEndpoint构造方法初始化
            NettyCodecAdapter adapter = new NettyCodecAdapter(getCodec(), getUrl(), NettyClient.this);

            pipeline.addLast("decoder", adapter.getDecoder()); // 解码器
            pipeline.addLast("encoder", adapter.getEncoder()); // 编码器
            pipeline.addLast("handler", nettyHandler); // 处理器

            return pipeline;
        }
    });
}

protected void doConnect() throws Throwable {
    long start = System.currentTimeMillis();

    ChannelFuture future = bootstrap.connect(getConnectAddress());

    try{
        boolean ret = future.awaitUninterruptibly(getConnectTimeout(), TimeUnit.MILLISECONDS);
        
        if (ret && future.isSuccess()) {
            Channel newChannel = future.getChannel();
            newChannel.setInterestOps(Channel.OP_READ_WRITE);

            try {
                // 关闭旧的连接
                Channel oldChannel = NettyClient.this.channel; // copy reference
                if (oldChannel != null) {
                    try {
                        oldChannel.close();
                    } finally {
                        NettyChannel.removeChannelIfDisconnected(oldChannel);
                    }
                }
            } finally {
                if (NettyClient.this.isClosed()) {
                    try {
                        if (logger.isInfoEnabled()) {
                            logger.info("Close new netty channel " + newChannel + ", because the client closed.");
                        }
                        newChannel.close();
                    } finally {
                        NettyClient.this.channel = null;
                        NettyChannel.removeChannelIfDisconnected(newChannel);
                    }
                } else {
                    NettyClient.this.channel = newChannel;
                }
            }
        } else if (future.getCause() != null) {
            throw new RemotingException("client failed to connect to server");
        } else {
            throw new RemotingException("client failed to connect to server");
        }
    }finally{
        if (! isConnected()) {
            future.cancel();
        }
    }
}
{% endhighlight %}


---

### NettyHandler处理器

NettyHandler继承了SimpleChannelHandler类，它包装了dubbo.ChannelHandler接口。

{% highlight java %}
public class NettyHandler extends org.jboss.netty.channel.SimpleChannelHandler {

    // <ip:port, channel>
    private final Map<String, dubbo.Channel> channels = 
        new ConcurrentHashMap<String, dubbo.Channel>(); 

    private final URL url;
    private final dubbo.ChannelHandler handler;
    
    public NettyHandler(URL url, dubbo.ChannelHandler handler) {
        this.url = url;
        this.handler = handler;
    }
}
{% endhighlight %}


以channelConnected()说明。

{% highlight java %}
public void channelConnected(org.jboss.netty.channel.ChannelHandlerContext ctx, 
                             org.jboss.netty.channel.ChannelStateEvent e) throws Exception {


    dubbo.NettyChannel channel = dubbo.NettyChannel.getOrAddChannel(ctx.getChannel(), url, handler);

    try {
        if (channel != null) {
            channels.put(
                NetUtils.toAddressString((InetSocketAddress) ctx.getChannel().getRemoteAddress()), 
                channel);
        }
        handler.connected(channel);
    } finally {
        NettyChannel.removeChannelIfDisconnected(ctx.getChannel());
    }
}
{% endhighlight %}


首先，调用NettyChannel.getOrAddChannel()，创建jboss.Channel到dubbo.Channel的一一对应。

{% highlight java %}
final class NettyChannel extends AbstractChannel {

    private static final ConcurrentMap<jboss.Channel, dubbo.NettyChannel> channelMap 
        = new ConcurrentHashMap<jboss.Channel, dubbo.NettyChannel>();

    static NettyChannel getOrAddChannel(org.jboss.netty.channel.Channel ch, 
                URL url, ChannelHandler handler) {

        NettyChannel ret = channelMap.get(ch);
        if (ret == null) {
            NettyChannel nc = new NettyChannel(ch, url, handler);
            if (ch.isConnected()) {
                ret = channelMap.putIfAbsent(ch, nc);
            }
            if (ret == null) {
                ret = nc;
            }
        }
        return ret;
    }
}
{% endhighlight %}

然后，将getOrAddChannel()返回的dubbo.Channel添加到channels。

{% highlight java %}
channels.put(
    NetUtils.toAddressString((InetSocketAddress) ctx.getChannel().getRemoteAddress()), 
    channel);
{% endhighlight %}

最后，将控制权交给dubbo.ChannelHandler。

{% highlight java %}
handler.connected(channel);
{% endhighlight %}
