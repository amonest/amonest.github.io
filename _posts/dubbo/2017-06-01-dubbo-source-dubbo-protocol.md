---
layout: post
title: Dubbo 源码分析 - Dubbo协议
---

Protocol是一个接口，提供export和refer两种功能。export是对于服务端而言的，导出服务。refer是对于客户端而言的，是引用服务端的服务。

{% highlight java %}
public interface Protocol {
    <T> Exporter<T> export(Invoker<T> invoker) throws RpcException;
    <T> Invoker<T> refer(Class<T> type, URL url) throws RpcException;
}
{% endhighlight %}


---

### Export 导出服务

export()在服务端使用，可以导出服务。

{% highlight java %}
public <T> Exporter<T> export(Invoker<T> invoker) throws RpcException {
    
    // url=提供者地址，以dubbo://协议
    URL url = invoker.getUrl();
    
    String key = serviceKey(url);

    // DubboExporter简单包装了Invoker
    // 通过getInvoker()方法将两者联系起来
    DubboExporter<T> exporter = new DubboExporter<T>(invoker, key, exporterMap);
    exporterMap.put(key, exporter);

    openServer(url);
    
    return exporter;
}
{% endhighlight %}


这里重点是调用openServer()启动Server，但是为了避免重复启动，使用serverMap保存已启动的Server。

{% highlight java %}
private void openServer(URL url) {
    String key = url.getAddress();
    boolean isServer = url.getParameter(Constants.IS_SERVER_KEY,true);
    if (isServer) {
        ExchangeServer server = serverMap.get(key);
        if (server == null) {
            serverMap.put(key, createServer(url));
        } else {
            server.reset(url);
        }
    }
}
{% endhighlight %}

createServer()负责创建具体的Server。

{% highlight java %}
private ExchangeServer createServer(URL url) {
    url = url.addParameterIfAbsent(Constants.CHANNEL_READONLYEVENT_SENT_KEY, Boolean.TRUE.toString());
    url = url.addParameterIfAbsent(Constants.HEARTBEAT_KEY, String.valueOf(Constants.DEFAULT_HEARTBEAT));

    // 默认Server类型=netty
    String str = url.getParameter(Constants.SERVER_KEY, Constants.DEFAULT_REMOTING_SERVER);
    if (str != null && str.length() > 0 
        && ! ExtensionLoader.getExtensionLoader(Transporter.class).hasExtension(str))
        throw new RpcException("Unsupported server type: " + str + ", url: " + url);

    // 解码器
    url = url.addParameter(Constants.CODEC_KEY, 
                Version.isCompatibleVersion() ? COMPATIBLE_CODEC_NAME : DubboCodec.NAME);

    ExchangeServer server;
    
    try {
        server = Exchangers.bind(url, requestHandler);
    } catch (RemotingException e) {
        throw new RpcException("Fail to start server(url: " + url + ") " + e.getMessage(), e);
    }

    return server;
}
{% endhighlight %}




---

### Refer 引用服务

refer()在客户端使用，可以引用服务端的服务。

{% highlight java %}
// 参数说明：
// serverType=服务接口，例如HelloService.class
// url=服务地址，例如dubbo://192.168.12.84:8199/suifeng.HelloService

public <T> Invoker<T> refer(Class<T> serviceType, URL url) throws RpcException {
    DubboInvoker<T> invoker = new DubboInvoker<T>(serviceType, url, getClients(url), invokers);
    invokers.add(invoker);
    return invoker;
}
{% endhighlight %}


getClients()用来获取一个连接列表。一个服务可以是单连接，也可以是多连接。

{% highlight java %}
private ExchangeClient[] getClients(URL url) {
    //是否共享连接
    boolean service_share_connect = false;

    //如果connections不配置，则共享连接，否则每服务每连接
    int connections = url.getParameter(Constants.CONNECTIONS_KEY, 0);    
    if (connections == 0) {
        service_share_connect = true;
        connections = 1;
    }
    
    ExchangeClient[] clients = new ExchangeClient[connections];
    for (int i = 0; i < clients.length; i++) {
        if (service_share_connect) {
            clients[i] = getSharedClient(url);
        } else {
            clients[i] = initClient(url);
        }
    }

    return clients;
}
{% endhighlight %}


getSharedClient()通过url获取共享连接。共享连接的意思是，相同的url，使用同一个Client。

{% highlight java %}
private ExchangeClient getSharedClient(URL url) {
    
    // 通过address判断是否是同一个地址？
    // 同一个地址使用相同的连接。
    String key = url.getAddress();

    ReferenceCountExchangeClient client = referenceClientMap.get(key);
    if ( client != null ) {
        if ( !client.isClosed()) {

            // 如果存在相同地址的Client？
            client.incrementAndGetCount();

            return client;
        } else {
            referenceClientMap.remove(key);
        }
    }

    // 没有相同地址的Client，则initClient()创建一个。
    ExchangeClient exchagneclient = initClient(url);    
    client = new ReferenceCountExchangeClient(exchagneclient, ghostClientMap);
    referenceClientMap.put(key, client);
    ghostClientMap.remove(key);

    return client; 
}
{% endhighlight %}


当连接不存在时，initClient()可以创建新连接。

{% highlight java %}
private ExchangeClient initClient(URL url) {
    
    // client类型，默认是netty
    String str = url.getParameter(Constants.CLIENT_KEY, 
            url.getParameter(Constants.SERVER_KEY, Constants.DEFAULT_REMOTING_CLIENT));

    if (str != null && str.length() > 0 
        && ! ExtensionLoader.getExtensionLoader(Transporter.class).hasExtension(str)) {
        throw new RpcException("Unsupported client type: " + str + "," +
                " supported client type is " 
                + StringUtils.join(ExtensionLoader.getExtensionLoader(Transporter.class)
                                                .getSupportedExtensions(), " "));
    }

    String version = url.getParameter(Constants.DUBBO_VERSION_KEY);

    // Codec类型，默认是DubboCodec
    boolean compatible = (version != null && version.startsWith("1.0."));
    url = url.addParameter(Constants.CODEC_KEY, 
            Version.isCompatibleVersion() && compatible ? COMPATIBLE_CODEC_NAME : DubboCodec.NAME);
    
    // 默认开启heartbeat, DEFAULT_HEARTBEAT=60*1000=60秒
    url = url.addParameterIfAbsent(Constants.HEARTBEAT_KEY, String.valueOf(Constants.DEFAULT_HEARTBEAT));
    
    ExchangeClient client;
    try {
        // 设置连接是lazy的？
        if (url.getParameter(Constants.LAZY_CONNECT_KEY, false)) {
            client = new LazyConnectExchangeClient(url ,requestHandler);
        } else {
            client = Exchangers.connect(url, requestHandler);
        }
    } catch (RemotingException e) {
        throw new RpcException("Fail to create remoting client for service(" + url
                + "): " + e.getMessage(), e);
    }
    return client;
}
{% endhighlight %}


创建连接的方式有两种，一种是Lazy方式，另外一种是非Lazy方式。

LazyConnectExchangeClient是Lazy连接方式的实现，在创建时不初始化连接，只有在请求发生时才初始化。

{% highlight java %}
final class LazyConnectExchangeClient implements ExchangeClient {
    
    public LazyConnectExchangeClient(URL url, ExchangeHandler requestHandler) {
        //lazy connect ,need set send.reconnect = true, to avoid channel bad status. 
        this.url = url.addParameter(Constants.SEND_RECONNECT_KEY, Boolean.TRUE.toString());
        this.requestHandler = requestHandler;
    }
    
    // 真正初始化连接处理
    private void initClient() throws RemotingException {
        if (client != null )
            return;
        client = Exchangers.connect(url, requestHandler);
    }

    public ResponseFuture request(Object request) throws RemotingException {
        initClient(); // 检查连接是否初始化？
        return client.request(request);
    }

    public ResponseFuture request(Object request, int timeout) throws RemotingException {
        initClient(); // 检查连接是否初始化？
        return client.request(request, timeout);
    }
}
{% endhighlight %}


不管是哪种连接方式，最后都会归结到创建ExchangeClient实例。ExchangeClient是通过Exhcnagers静态方法创建创建。

{% highlight java %}
ExchangeClient client = Exchangers.connect(url, requestHandler);
{% endhighlight %}

关于Exchangers的详细信息请参考[《交换层》](/2017/06/01/dubbo-source-exchangers)。


DubboInvoker是Invoker接口的实现，refer()的目的就是返回Invoker接口。

{% highlight java %}
public interface Invoker<T> {
    Class<T> getInterface();
    Result invoke(Invocation invocation) throws RpcException;
}
{% endhighlight %}


DubboInvoker内部封装了一个连接列表，invoke()调用发生时，从连接列表中选择一个连接进行处理。

{% highlight java %}
public class DubboInvoker<T> extends AbstractInvoker<T> {

    private final ExchangeClient[]      clients;
    
    public DubboInvoker(Class<T> serviceType, URL url, ExchangeClient[] clients) {
        super(serviceType, url);
        this.clients = clients;
    }

    @Override
    public Result invoke(final Invocation invocation) throws Throwable {
        RpcInvocation inv = (RpcInvocation) invocation;
        final String methodName = RpcUtils.getMethodName(invocation);
        inv.setAttachment(Constants.PATH_KEY, getUrl().getPath());
        inv.setAttachment(Constants.VERSION_KEY, version);
        
        // 从连接列表中选择一个连接
        ExchangeClient currentClient;
        if (clients.length == 1) {
            currentClient = clients[0];
        } else {
            currentClient = clients[index.getAndIncrement() % clients.length];
        }

        boolean isAsync = RpcUtils.isAsync(getUrl(), invocation);
        boolean isOneway = RpcUtils.isOneway(getUrl(), invocation);
        int timeout = getUrl().getMethodParameter(methodName, 
                            Constants.TIMEOUT_KEY, Constants.DEFAULT_TIMEOUT);
        if (isOneway) {
            boolean isSent = getUrl().getMethodParameter(methodName, Constants.SENT_KEY, false);
            currentClient.send(inv, isSent);
            RpcContext.getContext().setFuture(null);
            return new RpcResult();
        } else if (isAsync) {
            ResponseFuture future = currentClient.request(inv, timeout) ;
            RpcContext.getContext().setFuture(new FutureAdapter<Object>(future));
            return new RpcResult();
        } else {
            RpcContext.getContext().setFuture(null);
            return (Result) currentClient.request(inv, timeout).get();
        }
    }
}
{% endhighlight %}