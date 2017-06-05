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

### 首先，需要说明的是下面这条语句：

{% highlight java %}
invoker = refprotocol.refer(interfaceClass, url);
{% endhighlight %}

这里的url是注册地址：

{% highlight shell %}
registry://192.168.12.84:2181/com.alibaba.dubbo.registry.RegistryService?application=dubbo-client&dubbo=2.5.4-SNAPSHOT&pid=10888&refer=application%3Ddubbo-client%26dubbo%3D2.5.4-SNAPSHOT%26interface%3Dnet.mingyang.simple_dubbo_server.HelloService%26methods%3DsayHello%2CsayBye%26pid%3D10888%26side%3Dconsumer%26timestamp%3D1495697621982&registry=zookeeper&timestamp=1495697644516]
{% endhighlight %}

register是地址协议，192.168.12.84:2181是注册中心IP地址和端口。

参数registry=zookeeper，说明注册中心使用的是Zookeeper。

参数refer，是已经编码encode后的字符串，使用时需要解码decode才能用。

regprotocol是Protocol适配器，根据URL协议调用具体Protocol实现类。这里对应的是RegistryProtocol实现类。

{% highlight java %}
public class RegistryProtocol implements Protocol {

    public <T> Invoker<T> refer(Class<T> type, URL url) throws RpcException {        
        // 参数type=HelloService.class

        // 协议转换, url原先是registry协议，类似registry://0.0.0.0:0000/这样。
        // 这里获取转换成zookeeper://0.0.0.0:0000/这样
        url = url.setProtocol(url.getParameter(Constants.REGISTRY_KEY, Constants.DEFAULT_REGISTRY)).removeParameter(Constants.REGISTRY_KEY);

        // 获取ZookeeperRegistry实例
        Registry registry = registryFactory.getRegistry(url);
        if (RegistryService.class.equals(type)) {
            return proxyFactory.getInvoker((T) registry, type, url);
        }

        // 获取查询参数, 从ReferenceConfig来
        Map<String, String> qs = StringUtils.parseQueryString(url.getParameterAndDecoded(Constants.REFER_KEY));

        // group="a,b" or group="*"
        String group = qs.get(Constants.GROUP_KEY);
        if (group != null && group.length() > 0 ) {
            if ( ( Constants.COMMA_SPLIT_PATTERN.split( group ) ).length > 1
                    || "*".equals( group ) ) {
                return doRefer( getMergeableCluster(), registry, type, url );
            }
        }

        // 这里的cluster是一个Cluster适配器
        return doRefer(cluster, registry, type, url);
    }
}
{% endhighlight %}

doRefer()是RegistryProtocl内部的引用实现方法。

{% highlight java %}
private <T> Invoker<T> doRefer(Cluster cluster, Registry registry, Class<T> type, URL url) {
    // 注册目录，参考后面的《目录服务》
    RegistryDirectory<T> directory = new RegistryDirectory<T>(type, url);
    directory.setRegistry(registry);
    directory.setProtocol(protocol);

    // 订阅地址，注意是consumer://协议
    URL subscribeUrl = new URL(Constants.CONSUMER_PROTOCOL, NetUtils.getLocalHost(), 0, type.getName(), directory.getUrl().getParameters());

    // 是否需要在注册中心负责消费者，注册分类consumers
    if (! Constants.ANY_VALUE.equals(url.getServiceInterface())
            && url.getParameter(Constants.REGISTER_KEY, true)) {
        registry.register(subscribeUrl.addParameters(Constants.CATEGORY_KEY, Constants.CONSUMERS_CATEGORY,
                Constants.CHECK_KEY, String.valueOf(false)));
    }

    // 订阅注册中心，注意订阅了三个类别：providers、configurators、routers
    // 参考后面的《注册中心》
    directory.subscribe(subscribeUrl.addParameter(Constants.CATEGORY_KEY, 
            Constants.PROVIDERS_CATEGORY 
            + "," + Constants.CONFIGURATORS_CATEGORY 
            + "," + Constants.ROUTERS_CATEGORY));

    return cluster.join(directory);
}
{% endhighlight %}
