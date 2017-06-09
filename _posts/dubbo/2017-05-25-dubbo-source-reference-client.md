---
layout: post
title: Dubbo 源码分析 - 客户端配置
---

最简单的Dubbo客户端：

{% highlight java %}
public class DubboClientTest {

    public static void main(String[] args) throws Exception {
        ReferenceConfig<HelloService> referenceConfig = new ReferenceConfig<HelloService>();
        referenceConfig.setInterface(HelloService.class);
        referenceConfig.setRegistry(new RegistryConfig("zookeeper://192.168.12.84:2181"));
        referenceConfig.setApplication(new ApplicationConfig("dubbo-client"));
        HelloService helloClient = referenceConfig.get();
        System.out.println(helloClient.sayHello("world"));
    }
}
{% endhighlight %}


---


第一步：从get()开始。

{% highlight java %}
public synchronized T get() {
    if (ref == null) {
        init();
    }
    return ref;
}
{% endhighlight %}

这是一个单例方法，调用init()创建实例。


---

第二步：在init()里面，初始化一个Map实例，合并各种来源的属性，最后调用createProxy()创建代理。

{% highlight java %}
private void init() {

    // 这里是读取系统环境设置
    appendProperties(this);

    Map<String, String> map = new HashMap<String, String>();
    map.put(Constants.SIDE_KEY, Constants.CONSUMER_SIDE);
    map.put(Constants.DUBBO_VERSION_KEY, Version.getVersion());
    map.put(Constants.TIMESTAMP_KEY, String.valueOf(System.currentTimeMillis()));
    map.put(Constants.INTERFACE_KEY, interfaceName);
    appendParameters(map, application);
    appendParameters(map, module);
    appendParameters(map, consumer, Constants.DEFAULT_KEY);
    appendParameters(map, this);

    ref = createProxy(map);
}
{% endhighlight %}


---

第三步：createProxy()调用。

{% highlight java %}
private T createProxy(Map<String, String> map) {
    URL tmpUrl = new URL("temp", "localhost", 0, map);
    
    // 用户指定URL，指定的URL可能是点对点直连地址，也可能是注册中心URL
    // url可以是dubbo://1921.68.12.84:8893/这样，说明是直连地址
    // 也可以是registry://192.168.12.84:2181/这样，说明是注册中心地址

    if (url != null && url.length() > 0) { 
        String[] us = Constants.SEMICOLON_SPLIT_PATTERN.split(url);
        if (us != null && us.length > 0) {
            for (String u : us) {
                URL url = URL.valueOf(u);

                if (url.getPath() == null || url.getPath().length() == 0) {
                    url = url.setPath(interfaceName);
                }

                // registry协议，必需带上refer参数                
                if (Constants.REGISTRY_PROTOCOL.equals(url.getProtocol())) {
                    urls.add(url.addParameterAndEncoded(
                            Constants.REFER_KEY, StringUtils.toQueryString(map)));
                } else {
                    urls.add(ClusterUtils.mergeUrl(url, map));
                }
            }
        }
    } else { 

        // 通过注册中心配置拼装URL
        // 执行到这里，说明没有指定URL，只能通过RegistryConfig获取注册中心地址
        // 所以，loadRegistries()返回的一定是registry://协议的地址

        List<URL> us = loadRegistries(false);
        if (us != null && us.size() > 0) {
            for (URL u : us) {
                URL monitorUrl = loadMonitor(u);
                if (monitorUrl != null) {
                    map.put(Constants.MONITOR_KEY, URL.encode(monitorUrl.toFullString()));
                }

                // registry协议，必需带上refer参数
                urls.add(u.addParameterAndEncoded(Constants.REFER_KEY, StringUtils.toQueryString(map)));
            }
        }

        if (urls == null || urls.size() == 0) {
            throw new IllegalStateException("No such any registry to reference " + interfaceName);
        }
    }

    // 地址列表，注意它可能是registry://，可能是dubbo://，都不能确定
    // 地址使用的协议不同，refprotocol处理也不同，因为refprotocol是一个适配器类
    // 当dubbo协议时，调用的是DubboProtocol，返回的是简单的Invoker
    // 当Registry协议时，调用的是RegistryProtocol，返回的是支持集群功能的Invoker
    // 但是，不管那种协议，结果都是Invoker

    if (urls.size() == 1) {
        invoker = refprotocol.refer(interfaceClass, urls.get(0));
    } else {
        List<Invoker<?>> invokers = new ArrayList<Invoker<?>>();
        URL registryURL = null;
        for (URL url : urls) {
            invokers.add(refprotocol.refer(interfaceClass, url));
            if (Constants.REGISTRY_PROTOCOL.equals(url.getProtocol())) {
                registryURL = url; // 用了最后一个registry url
            }
        }

        if (registryURL != null) { // 有 注册中心协议的URL
            // 对有注册中心的Cluster 只用 AvailableCluster
            URL u = registryURL.addParameter(Constants.CLUSTER_KEY, AvailableCluster.NAME); 
            invoker = cluster.join(new StaticDirectory(u, invokers));
        }  else { // 不是 注册中心的URL
            invoker = cluster.join(new StaticDirectory(invokers));
        }
    }

    // 创建服务代理
    return (T) proxyFactory.getProxy(invoker);
}
{% endhighlight %}


---

第四步：调用proxyFactory的getProxy()方法，包装invoker，返回代理实例。

{% highlight java %}
public class JdkProxyFactory extends AbstractProxyFactory {

    public <T> T getProxy(Invoker<T> invoker, Class<?>[] interfaces) {
        return (T) Proxy.newProxyInstance(
                Thread.currentThread().getContextClassLoader(), 
                interfaces, 
                new InvokerInvocationHandler(invoker));
    }

}
{% endhighlight %}

InvokerInvocationHandler可以将方法调用封装成Invocation，由invoker完成调用处理。

{% highlight java %}
public class InvokerInvocationHandler implements InvocationHandler {
    private final Invoker<?> invoker;
    
    public InvokerInvocationHandler(Invoker<?> handler){
        this.invoker = handler;
    }

    public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
        String methodName = method.getName();
        Class<?>[] parameterTypes = method.getParameterTypes();
        if (method.getDeclaringClass() == Object.class) {
            return method.invoke(invoker, args);
        }
        if ("toString".equals(methodName) && parameterTypes.length == 0) {
            return invoker.toString();
        }
        if ("hashCode".equals(methodName) && parameterTypes.length == 0) {
            return invoker.hashCode();
        }
        if ("equals".equals(methodName) && parameterTypes.length == 1) {
            return invoker.equals(args[0]);
        }
        return invoker.invoke(new RpcInvocation(method, args)).recreate();
    }
}
{% endhighlight %}