---
layout: post
title: Dubbo 源码分析 - 交换层
---

交换层是协议层和传输层之间的一个层，有Exchanger、ExchangeServer和ExchangeClient三个接口。

Dubbo交换层的默认实现是Header，对应的实现类是HeaderExchanger、HeaderExchangeServer和HeaderExchangeClient。


---

### HeaderExchanger 工厂类

Exchanger接口的目的是作为工厂类使用，由它创建ExchangeServer和ExchangeClient。

所以，整个SPI里面暴露出来的只有Exchanger，ExchangeServer和ExchangeClient只能通过Exchanger创建。

{% highlight java %}
public class HeaderExchanger implements Exchanger {

    public ExchangeServer bind(URL url, ExchangeHandler handler) throws RemotingException {
        return new HeaderExchangeServer(Transporters.bind(url, new DecodeHandler(new HeaderExchangeHandler(handler))));
    }

    public ExchangeClient connect(URL url, ExchangeHandler handler) throws RemotingException {
        return new HeaderExchangeClient(Transporters.connect(url, new DecodeHandler(new HeaderExchangeHandler(handler))));
    }
}
{% endhighlight %}



---

### HeaderExchangeClient 客户端

HeaderExchangeClient是对底层Client的封装。

内部包含一个HeaderExchangeChannel实例，所有的请求都转发给这个channe。

{% highlight java %}
public class HeaderExchangeClient implements ExchangeClient {

    public HeaderExchangeClient(Client client) {
        this.client = client;
        this.channel = new HeaderExchangeChannel(client);
    }

    public ResponseFuture request(Object request) throws RemotingException {
        return channel.request(request);
    }

    public ResponseFuture request(Object request, int timeout) throws RemotingException {
        return channel.request(request, timeout);
    }
}
{% endhighlight %}


---

### HeaderExchangeChannel 通道

HeaderExchangeChannel是对底层Channel的封装。

它的实质是把上层(协议层)传来的Object类型，转换成下层(传输层)需要的Request类型，然后再调用底层的channel.send()发送出去。

{% highlight java %}
final class HeaderExchangeChannel implements ExchangeChannel {

    HeaderExchangeChannel(Channel channel) {
        this.channel = channel;
    }

    public ResponseFuture request(Object request) throws RemotingException {
        return request(request, channel.getUrl().getPositiveParameter(Constants.TIMEOUT_KEY, Constants.DEFAULT_TIMEOUT));
    }

    public ResponseFuture request(Object request, int timeout) throws RemotingException {
        Request req = new Request();
        req.setVersion("2.0.0");
        req.setTwoWay(true);
        req.setData(request);
        DefaultFuture future = new DefaultFuture(channel, req, timeout);
        try{
            channel.send(req);
        }catch (RemotingException e) {
            future.cancel();
            throw e;
        }
        return future;
    }
}
{% endhighlight %}


---

### HeaderExchangeHandler 处理器

HeaderExchangeHandler是对ExchangeHandler的封装。

注意，HeaderExchangeHandler实现的不是ExchangeHandler接口，它实现的是ChannelHandler和ChannelHandlerDelegate接口。

它是作为传输层的Server和Client构造参数使用的。

{% highlight java %}
public class HeaderExchangeHandler implements ChannelHandlerDelegate {

    private final ExchangeHandler handler;

    public HeaderExchangeHandler(ExchangeHandler handler){
        this.handler = handler;
    }
}
{% endhighlight %}


作为实现了ChannelHandler接口的HeaderExchangeHandler，要处理连接、发送、关闭等一系列的事件。

HeaderExchangeHandler将这些事件转移给内部的ExchangeHandler实例。

connected和disconnected处理：

{% highlight java %}
public void connected(Channel channel) throws RemotingException {
    channel.setAttribute(KEY_READ_TIMESTAMP, System.currentTimeMillis());
    channel.setAttribute(KEY_WRITE_TIMESTAMP, System.currentTimeMillis());
    ExchangeChannel exchangeChannel = HeaderExchangeChannel.getOrAddChannel(channel);

    try {

        // 转发给ExchangeHandler处理
        handler.connected(exchangeChannel);

    } finally {
        HeaderExchangeChannel.removeChannelIfDisconnected(channel);
    }
}

public void disconnected(Channel channel) throws RemotingException {
    channel.setAttribute(KEY_READ_TIMESTAMP, System.currentTimeMillis());
    channel.setAttribute(KEY_WRITE_TIMESTAMP, System.currentTimeMillis());
    ExchangeChannel exchangeChannel = HeaderExchangeChannel.getOrAddChannel(channel);

    try {

        // 转发给ExchangeHandler处理
        handler.disconnected(exchangeChannel);

    } finally {
        HeaderExchangeChannel.removeChannelIfDisconnected(channel);
    }
}
{% endhighlight %}


HeaderExchangeChannel提供了两个静态方法：getOrAddChannel()和removeChannelIfDisconnected()。

这两个方法为channel实例注入经过包装的ExchangeChannel属性，实现Channel和ExchangeChannel的一对一关系。

{% highlight java %}
static HeaderExchangeChannel getOrAddChannel(Channel ch) {
    HeaderExchangeChannel ret = (HeaderExchangeChannel) ch.getAttribute(CHANNEL_KEY);
    if (ret == null) {
        ret = new HeaderExchangeChannel(ch);
        if (ch.isConnected()) {
            ch.setAttribute(CHANNEL_KEY, ret);
        }
    }
    return ret;
}

static void removeChannelIfDisconnected(Channel ch) {
    if (ch != null && ! ch.isConnected()) {
        ch.removeAttribute(CHANNEL_KEY);
    }
}
{% endhighlight %}

总结一下，ExchangeHandler的处理流程：

**ExchangeHandler -> 包装成HeaderExchangeHandler -> HeaderExchangeHandler作为参数传递给Server和Client -> HeaderExchangeHandler接收到Channel信息 -> getOrAddChannel()实现Channel和ExchangeChannel对应 -> 回调ExchangeHandler对应方法**

send事件处理：

{% highlight java %}
public void sent(Channel channel, Object message) throws RemotingException {
    channel.setAttribute(KEY_WRITE_TIMESTAMP, System.currentTimeMillis());

    // channel对应到ExchangeChannel
    ExchangeChannel exchangeChannel = HeaderExchangeChannel.getOrAddChannel(channel);

    try {

        // 转发给ExchangeHandler处理
        handler.sent(exchangeChannel, message);

    } finally {
        HeaderExchangeChannel.removeChannelIfDisconnected(channel);
    }

    if (message instanceof Request) {
        Request request = (Request) message;
        DefaultFuture.sent(channel, request);
    }
}
{% endhighlight %}


received事件处理：

{% highlight java %}
public void received(Channel channel, Object message) throws RemotingException {
    channel.setAttribute(KEY_READ_TIMESTAMP, System.currentTimeMillis());

    ExchangeChannel exchangeChannel = HeaderExchangeChannel.getOrAddChannel(channel);

    try {

        if (message instanceof Request) {
            Request request = (Request) message;
            if (request.isEvent()) {
                handlerEvent(channel, request);
            } else {
                if (request.isTwoWay()) {
                    Response response = handleRequest(exchangeChannel, request);
                    channel.send(response);
                } else {
                    handler.received(exchangeChannel, request.getData());
                }
            }

        } else if (message instanceof Response) {
            handleResponse(channel, (Response) message);

        } else if (message instanceof String) {
            if (isClientSide(channel)) {
                Exception e = new Exception("Dubbo client can not supported string message: " + message + " in channel: " + channel + ", url: " + channel.getUrl());
                logger.error(e.getMessage(), e);
            } else {
                String echo = handler.telnet(channel, (String) message);
                if (echo != null && echo.length() > 0) {
                    channel.send(echo);
                }
            }

        } else {
            handler.received(exchangeChannel, message);
        }
    } finally {
        HeaderExchangeChannel.removeChannelIfDisconnected(channel);
    }
}
{% endhighlight %}

