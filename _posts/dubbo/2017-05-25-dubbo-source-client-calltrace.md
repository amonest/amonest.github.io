---
layout: post
title: Dubbo 源码分析 - 客户端调用列表
---

第一：客户端从服务调用开始。

{% highlight java %}
System.out.println(helloService.sayHello("test"));
{% endhighlight %}

---

第二：InvokerInvocationHandler。

{% highlight java %}
public class InvokerInvocationHandler implements InvocationHandler {

    private final Invoker<?> invoker;

    public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
        String methodName = method.getName();
        return invoker.invoke(new RpcInvocation(method, args)).recreate();
    }
}
{% endhighlight %}


---

第三：MockClusterInvoker。

{% highlight java %}
public class MockClusterInvoker<T> implements Invoker<T>{
    
    private final Directory<T> directory ;
    
    private final Invoker<T> invoker;

    public Result invoke(Invocation invocation) throws RpcException {
        Result result = null;
        
        String value = directory.getUrl().getMethodParameter(invocation.getMethodName(), 
                            Constants.MOCK_KEY, Boolean.FALSE.toString()).trim(); 

        // Mock这里有三种处理方式：no mock、force mock和fail mock。

        if (value.length() == 0 || value.equalsIgnoreCase("false")){
            //no mock
            result = this.invoker.invoke(invocation);
        } else if (value.startsWith("force")) {
            //force:direct mock
            result = doMockInvoke(invocation, null);
        } else {
            //fail-mock
            try {
                result = this.invoker.invoke(invocation);
            }catch (RpcException e) {
                if (e.isBiz()) {
                    throw e;
                } else {
                    result = doMockInvoke(invocation, e);
                }
            }
        }
        return result;
    }

    @SuppressWarnings({ "unchecked", "rawtypes" })
    private Result doMockInvoke(Invocation invocation,RpcException e){
        Result result = null;
        Invoker<T> minvoker ;
        
        List<Invoker<T>> mockInvokers = selectMockInvoker(invocation);
        if (mockInvokers == null || mockInvokers.size() == 0) {
            
            // MockInvoker 默认实现
            minvoker = (Invoker<T>) new MockInvoker(directory.getUrl());

        } else {
            minvoker = mockInvokers.get(0);
        }
        try {
            result = minvoker.invoke(invocation);
        } catch (RpcException me) {
            if (me.isBiz()) {
                result = new RpcResult(me.getCause());
            } else {
                throw new RpcException(me.getCode(), getMockExceptionMessage(e, me), me.getCause());
            }
        } catch (Throwable me) {
            throw new RpcException(getMockExceptionMessage(e, me), me.getCause());
        }
        return result;
    }

    private List<Invoker<T>> selectMockInvoker(Invocation invocation){
        if (invocation instanceof RpcInvocation){
            ((RpcInvocation)invocation).setAttachment(Constants.INVOCATION_NEED_MOCK, Boolean.TRUE.toString());
            List<Invoker<T>> invokers = directory.list(invocation);
            return invokers;
        } else {
            return null ;
        }
    }
}

// MockInvoker默认实现
final public class MockInvoker<T> implements Invoker<T> {

    public Result invoke(Invocation invocation) throws RpcException {
        String mock = getUrl().getParameter(invocation.getMethodName()+"."+Constants.MOCK_KEY);
        if (invocation instanceof RpcInvocation) {
            ((RpcInvocation) invocation).setInvoker(this);
        }
        if (StringUtils.isBlank(mock)){
            mock = getUrl().getParameter(Constants.MOCK_KEY);
        }
        
        if (StringUtils.isBlank(mock)){
            throw new RpcException(new IllegalAccessException("mock can not be null. url :" + url));
        }

        mock = normallizeMock(URL.decode(mock));

        if (Constants.RETURN_PREFIX.trim().equalsIgnoreCase(mock.trim())){
            RpcResult result = new RpcResult();
            result.setValue(null);
            return result;
        } else if (mock.startsWith(Constants.RETURN_PREFIX)) {
            mock = mock.substring(Constants.RETURN_PREFIX.length()).trim();
            mock = mock.replace('`', '"');
            try {
                Type[] returnTypes = RpcUtils.getReturnTypes(invocation);
                Object value = parseMockValue(mock, returnTypes);
                return new RpcResult(value);
            } catch (Exception ew) {
                throw new RpcException("mock return invoke error.");
            }
        } else if (mock.startsWith(Constants.THROW_PREFIX)) {
            mock = mock.substring(Constants.THROW_PREFIX.length()).trim();
            mock = mock.replace('`', '"');
            if (StringUtils.isBlank(mock)){
                throw new RpcException(" mocked exception for Service degradation. ");
            } else {
                Throwable t = getThrowable(mock);
                throw new RpcException(RpcException.BIZ_EXCEPTION, t);
            }
        } else { //impl mock
             try {
                 Invoker<T> invoker = getInvoker(mock);
                 return invoker.invoke(invocation);
             } catch (Throwable t) {
                 throw new RpcException("Failed to create mock implemention class " + mock , t);
             }
        }
    }

    private Invoker<T> getInvoker(String mockService){
        Invoker<T> invoker =(Invoker<T>) mocks.get(mockService);
        if (invoker != null ){
            return invoker;
        } else {
            Class<T> serviceType = (Class<T>)ReflectUtils.forName(url.getServiceInterface());

            // Mock服务类：serverInterface + Mock
            if (ConfigUtils.isDefault(mockService)) {
                mockService = serviceType.getName() + "Mock";
            }
            
            Class<?> mockClass = ReflectUtils.forName(mockService);

            T mockObject = (T) mockClass.newInstance();
            invoker = proxyFactory.getInvoker(mockObject, (Class<T>)serviceType, url);
            if (mocks.size() < 10000) {
                mocks.put(mockService, invoker);
            }
            return invoker;
        }
    }
}
{% endhighlight %}


---

第四：FailoverClusterInvoker。

{% highlight java %}
public class FailoverClusterInvoker<T> extends AbstractClusterInvoker<T> {

    public Result invoke(final Invocation invocation) throws RpcException {
        LoadBalance loadbalance;
        
        List<Invoker<T>> invokers = list(invocation);

        if (invokers != null && invokers.size() > 0) {
            loadbalance = ExtensionLoader.getExtensionLoader(LoadBalance.class)
                    .getExtension(invokers.get(0).getUrl()
                            .getMethodParameter(invocation.getMethodName(),
                                Constants.LOADBALANCE_KEY, Constants.DEFAULT_LOADBALANCE));
        } else {
            loadbalance = ExtensionLoader.getExtensionLoader(LoadBalance.class)
                    .getExtension(Constants.DEFAULT_LOADBALANCE);
        }

        return doInvoke(invocation, invokers, loadbalance);
    }

    public Result doInvoke(Invocation invocation, final List<Invoker<T>> invokers, 
                    LoadBalance loadbalance) throws RpcException {
        List<Invoker<T>> copyinvokers = invokers;

        int len = getUrl().getMethodParameter(invocation.getMethodName(), 
                        Constants.RETRIES_KEY, Constants.DEFAULT_RETRIES) + 1;
        
        RpcException le = null; // last exception.
        List<Invoker<T>> invoked = new ArrayList<Invoker<T>>(copyinvokers.size()); // invoked invokers.
        Set<String> providers = new HashSet<String>(len);

        for (int i = 0; i < len; i++) {
            
            // 通过LoadBalance规则，从Invoker列表中选择一个执行的Invoker
            Invoker<T> invoker = select(loadbalance, invocation, copyinvokers, invoked);

            invoked.add(invoker);
            RpcContext.getContext().setInvokers((List)invoked);
            try {
                Result result = invoker.invoke(invocation);
                return result;
            } catch (RpcException e) {
                if (e.isBiz()) { // biz exception.
                    throw e;
                }
                le = e;
            } catch (Throwable e) {
                le = new RpcException(e.getMessage(), e);
            } finally {
                providers.add(invoker.getUrl().getAddress());
            }
        }
    }
}
{% endhighlight %}


---

第五：RegistryDirectory$InvokerDelegete，它是通过RegistryDirectory的toInvokers()创建的。

{% highlight java %}
public class RegistryDirectory<T> extends AbstractDirectory<T> implements NotifyListener {
    
    private void refreshInvoker(List<URL> invokerUrls){
        ... ...

        Map<String, Invoker<T>> newUrlInvokerMap = toInvokers(invokerUrls);

        ... ...
    }

    private static class InvokerDelegete<T> extends InvokerWrapper<T>{
        private URL providerUrl;

        public InvokerDelegete(Invoker<T> invoker, URL url, URL providerUrl) {
            super(invoker, url);
            this.providerUrl = providerUrl;
        }

        public URL getProviderUrl() {
            return providerUrl;
        }
    }
}
{% endhighlight %}


---

第六：DubboInvoker。

{% highlight java %}

public class DubboInvoker<T> extends AbstractInvoker<T> {
    
    private final ExchangeClient[]      clients;

    private final Set<Invoker<?>> invokers;
    
    public DubboInvoker(Class<T> serviceType, URL url, 
                ExchangeClient[] clients, Set<Invoker<?>> invokers){
        this.clients = clients;
        this.invokers = invokers; 
    }

    public Result invoke(final Invocation invocation) throws Throwable {
        RpcInvocation inv = (RpcInvocation) invocation;
        final String methodName = RpcUtils.getMethodName(invocation);
        inv.setAttachment(Constants.PATH_KEY, getUrl().getPath());
        inv.setAttachment(Constants.VERSION_KEY, version);
        
        // 选择一个ExchangeClient执行
        ExchangeClient currentClient;
        if (clients.length == 1) {
            currentClient = clients[0];
        } else {
            currentClient = clients[index.getAndIncrement() % clients.length];
        }

        boolean isAsync = RpcUtils.isAsync(getUrl(), invocation);
        boolean isOneway = RpcUtils.isOneway(getUrl(), invocation);
        int timeout = getUrl().getMethodParameter(methodName, Constants.TIMEOUT_KEY,Constants.DEFAULT_TIMEOUT);
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


---

第七：ReferenceCountExchangeClient。

{% highlight java %}
final class ReferenceCountExchangeClient implements ExchangeClient {

    private ExchangeClient client;
    
    private final AtomicInteger refenceCount = new AtomicInteger(0);    
    
    public ReferenceCountExchangeClient(ExchangeClient client) {
        this.client = client;
        refenceCount.incrementAndGet();
    }

    public ResponseFuture request(Object request, int timeout) throws RemotingException {
        return client.request(request, timeout);
    }
}
{% endhighlight %}


---

第八：HeaderExchangeClient。

{% highlight java %}
public class HeaderExchangeClient implements ExchangeClient {

    private final Client client;

    private final ExchangeChannel channel;

    public HeaderExchangeClient(Client client){
        this.client = client;
        this.channel = new HeaderExchangeChannel(client);
    }

    public ResponseFuture request(Object request) throws RemotingException {
        return channel.request(request);
    }
}
{% endhighlight %}


---

第九：HeaderExchangeChannel。

{% highlight java %}
final class HeaderExchangeChannel implements ExchangeChannel {

    private final Channel       channel;

    HeaderExchangeChannel(Channel channel) {
        this.channel = channel;
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


第十：NettyClient。

{% highlight java %}
public class NettyClient extends AbstractClient {

    private final dubbo.ChannelHandler handler;

    private final dubbo.Channel       channel;

    public NettyClient(final URL url, final ChannelHandler handler) throws RemotingException{
        this.url = url;
        this.handler = handler;

        doOpen();
        doConnect();
    }

    public void send(Object message, boolean sent) throws RemotingException {
        dubbo.Channel channel = getChannel();
        channel.send(message, sent);
    }


    // NettyClient内部保留了一个jboss.Channel实例
    // 这个实例通过NettyChannel.getOrAddChannel()静态方法，
    // 实现了jboss.Channel到dubbo.NettyChannel的一对一关系

    protected void doConnect() throws Throwable {
        ChannelFuture future = bootstrap.connect(getConnectAddress());
        this.channel = future.getChannel();
    }

    protected com.alibaba.dubbo.remoting.Channel getChannel() {
        Channel c = channel;
        return NettyChannel.getOrAddChannel(c, getUrl(), this);
    }
}
{% endhighlight %}

NettyChannel.getOrAddChannel()实现了jboss.Channel到dubbo.NettyChannel的一对一关系。

{% highlight java %}
final class NettyChannel extends AbstractChannel {

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


---


第十一：NettyChannel。

{% highlight java %}
final class NettyChannel extends AbstractChannel {

    private final org.jboss.netty.channel.Channel channel;

    private NettyChannel(org.jboss.netty.channel.Channel channel, URL url, ChannelHandler handler) {
        super(url, handler);
        this.channel = channel;
    }

    public void send(Object message, boolean sent) throws RemotingException {
        boolean success = true;
        int timeout = 0;

        // 对应jboss的Channel和ChannelFuture
        // 到这里，message就发送出去了，
        // 后面剩下的就是接收数据。
        ChannelFuture future = channel.write(message);

        if (sent) {
            timeout = getUrl().getPositiveParameter(Constants.TIMEOUT_KEY, Constants.DEFAULT_TIMEOUT);
            success = future.await(timeout);
        }

        Throwable cause = future.getCause();
        if (cause != null) {
            throw cause;
        }
    }
}
{% endhighlight %}


到这里为止，数据通过jboss.channel.write()发送了出去，下面就是数据接收了。


---

第十三：NettyHandler。

NettyHandler是一个处理器，当数据发送成功时调用writeRequested()。

writeRequested()根据NettyChannel.getOrAddChannel()建立的jboss.Channel到dubbo.Channel对应关系，

找到dubbo.Channel，将它作为参数传递给handler。

这里的handler=NettyClient。

流程：nettyChannel.send() -> jboss.channel.send() -> nettyHandler.writeRequested() -> nettyClient.sent()

{% highlight java %}
public class NettyHandler extends SimpleChannelHandler {
    
    private final ChannelHandler handler;
    
    public NettyHandler(URL url, ChannelHandler handler) {
        this.url = url;
        this.handler = handler;
    }

    public void writeRequested(ChannelHandlerContext ctx, MessageEvent e) throws Exception {
        super.writeRequested(ctx, e);
        NettyChannel channel = NettyChannel.getOrAddChannel(ctx.getChannel(), url, handler);
        try {
            handler.sent(channel, e.getMessage());
        } finally {
            NettyChannel.removeChannelIfDisconnected(ctx.getChannel());
        }
    }
}
{% endhighlight %}