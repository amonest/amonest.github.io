---
layout: post
title: Dubbo 源码分析 - Registry协议
---

RegistryProtocol实现的是Protocol接口，需要提供export和refer两种功能。

{% highlight java %}
public interface Protocol {
    <T> Exporter<T> export(Invoker<T> invoker) throws RpcException;
    <T> Invoker<T> refer(Class<T> serviceType, URL url) throws RpcException;
}
{% endhighlight %}

---

### Export 导出服务

export()在服务端使用，可以导出服务。

Invoker有一个getUrl()属性，在RegistryProtocol这里，该属性是registry://协议。

但是该Url有export属性，是编码后的提供者地址，使用dubbo://协议。

{% highlight java %}
public <T> Exporter<T> export(final Invoker<T> originInvoker) throws RpcException {
    // doLocalExport()，导出Invoker
    String key = getCacheKey(originInvoker);
    ExporterChangeableWrapper<T> exporter = (ExporterChangeableWrapper<T>) bounds.get(key);
    if (exporter == null) {
        synchronized (bounds) {
            exporter = (ExporterChangeableWrapper<T>) bounds.get(key);
            if (exporter == null) {

                // 这里getProviderUrl()是返回export属性
                final Invoker<?> invokerDelegete = 
                    new InvokerDelegete<T>(originInvoker, getProviderUrl(originInvoker));

                // 这里分两个步骤：
                // 1. 调用protocol.export()导出服务，因为invokerDelegete使用的是dubbo协议，
                //    所以，实际执行的是DubboProtocol
                // 2. 对DubboProtocol返回的Exporter用ExporterChangeableWrapper封装，
                //    目的是ExporterChangeableWrapper可以修改内部的Exporter

                exporter = new ExporterChangeableWrapper<T>(
                    (Exporter<T>)protocol.export(invokerDelegete), originInvoker);

                bounds.put(key, exporter);
            }
        }
    }

    // 注册提供者，在注册中心创建提供者路径
    final Registry registry = getRegistry(originInvoker);
    final URL registedProviderUrl = getRegistedProviderUrl(originInvoker); // 获取dubbo://提供者地址。
    registry.register(registedProviderUrl);

    // 订阅override数据
    final URL overrideSubscribeUrl = getSubscribedOverrideUrl(registedProviderUrl);
    final OverrideListener overrideSubscribeListener = new OverrideListener(overrideSubscribeUrl);
    overrideListeners.put(overrideSubscribeUrl, overrideSubscribeListener);
    registry.subscribe(overrideSubscribeUrl, overrideSubscribeListener);

    //保证每次export都返回一个新的exporter实例
    return new Exporter<T>() {
        public Invoker<T> getInvoker() {
            return exporter.getInvoker();
        }
        public void unexport() {
            exporter.unexport();
            registry.unregister(registedProviderUrl);

            overrideListeners.remove(overrideSubscribeUrl);
            registry.unsubscribe(overrideSubscribeUrl, overrideSubscribeListener);
        }
    };
}
{% endhighlight %}


提供者在注册的同时，也提供了订阅功能。订阅的目的是提供中心管理功能。

{% highlight java %}
private class OverrideListener implements NotifyListener {
        
    private volatile List<Configurator> configurators;
    
    private final URL subscribeUrl;

    public OverrideListener(URL subscribeUrl) {
        this.subscribeUrl = subscribeUrl;
    }

    /*
     *  provider 端可识别的override url只有这两种.
     *  override://0.0.0.0/serviceName?timeout=10
     *  override://0.0.0.0/?timeout=10
     */
    public void notify(List<URL> urls) {
        List<URL> result = new ArrayList<URL>(urls);

        for (URL url : urls) {
            URL overrideUrl = url;
            if (!UrlUtils.isMatch(subscribeUrl, overrideUrl)) {
                result.remove(overrideUrl);
            }
        }

        // 转换成Configurator对象
        this.configurators = RegistryDirectory.toConfigurators(result);

        List<ExporterChangeableWrapper<?>> exporters = 
                new ArrayList<ExporterChangeableWrapper<?>>(bounds.values());

        for (ExporterChangeableWrapper<?> exporter : exporters){
            Invoker<?> invoker = exporter.getOriginInvoker();
            final Invoker<?> originInvoker ;
            if (invoker instanceof InvokerDelegete){
                originInvoker = ((InvokerDelegete<?>)invoker).getInvoker();
            } else {
                originInvoker = invoker;
            }

            // 原始Url，从registry://地址里面读取export参数
            URL originUrl = 
                URL.valueOf(origininvoker.getUrl().getParameterAndDecoded(Constants.EXPORT_KEY));

            // 新的Url，通过Configurator重新配置
            URL newUrl = getNewInvokerUrl(originUrl);
            
            // 如果URL有变化，则重新导出
            if (! originUrl.equals(newUrl)) {
                RegistryProtocol.this.doChangeLocalExport(originInvoker, newUrl);
            }
        }
    }
    
    // 通过Configurator重新配置Url
    private URL getNewInvokerUrl(URL url) {
        List<Configurator> localConfigurators = this.configurators; // local reference
        // 合并override参数
        if (localConfigurators != null && localConfigurators.size() > 0) {
            for (Configurator configurator : localConfigurators) {
                url = configurator.configure(url);
            }
        }
        return url;
    }

    // RegistryProtocol
    // 重新导出
    private <T> void doChangeLocalExport(final Invoker<T> originInvoker, URL newInvokerUrl) {
        String key = getCacheKey(originInvoker);
        final ExporterChangeableWrapper<T> exporter = (ExporterChangeableWrapper<T>) bounds.get(key);
        if (exporter == null){
            logger.warn(new IllegalStateException("error state, exporter should not be null"));
            return ;//不存在是异常场景 直接返回 
        } else {

            // 1. 使用protocol.export()重新导出
            // 2. 修改ExporterChangeableWrapper的Exporter，这样的目的应该是保持原先的exporter引用不变
            final Invoker<T> invokerDelegete = new InvokerDelegete<T>(originInvoker, newInvokerUrl);
            exporter.setExporter(protocol.export(invokerDelegete));
        }
    }
}
{% endhighlight %}


---

### Refer 引用服务

refer()在客户端被调用，需要提供两个参数。

第一个参数serviceType, 这是需要引用的服务接口类型。

第二个参数url，这是注册中心的地址，使用registry://协议：

{% highlight shell %}
registry://192.168.12.84:2181/com.alibaba.dubbo.registry.RegistryService?application=dubbo-client&dubbo=2.5.4-SNAPSHOT&pid=10888&refer=application%3Ddubbo-client%26dubbo%3D2.5.4-SNAPSHOT%26interface%3Dnet.mingyang.simple_dubbo_server.HelloService%26methods%3DsayHello%2CsayBye%26pid%3D10888%26side%3Dconsumer%26timestamp%3D1495697621982&registry=zookeeper&timestamp=1495697644516]
{% endhighlight %}

register是地址协议，192.168.12.84:2181是注册中心IP地址和端口。

参数registry=zookeeper，说明注册中心使用的是Zookeeper。

参数refer，是已经编码encode后的字符串，使用时需要解码decode才能用。


{% highlight java %}
public <T> Invoker<T> refer(Class<T> type, URL url) throws RpcException {

    // 参数type=HelloService.class

    // 转换地址协议
    // 传进来的是registry://192.168.12.84:2181/RegistryService?registry=zookeeper
    // 转化成zookeeper:////192.168.12.84:2181/RegistryService
    url = url.setProtocol(url.getParameter(Constants.REGISTRY_KEY, Constants.DEFAULT_REGISTRY))
            .removeParameter(Constants.REGISTRY_KEY);

    // 获取注册中心对象
    // registryFactory是适配器对象，
    // 根据地址协议，实际调用的是ZookeeperRegistryFactory类型
    // 创建的注册中心对象是ZookeeperRegistry类型
    Registry registry = registryFactory.getRegistry(url);

    if (RegistryService.class.equals(type)) {
        return proxyFactory.getInvoker((T) registry, type, url);
    }

    // group="a,b" or group="*"
    // 获取查询参数, 从ReferenceConfig来
    Map<String, String> qs = StringUtils.parseQueryString(url.getParameterAndDecoded(Constants.REFER_KEY));
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
{% endhighlight %}


doRefer()是RegistryProtocl内部的引用实现方法。

{% highlight java %}
private <T> Invoker<T> doRefer(Cluster cluster, Registry registry, Class<T> type, URL url) {

    // 注册目录
    RegistryDirectory<T> directory = new RegistryDirectory<T>(type, url);
    directory.setRegistry(registry);
    directory.setProtocol(protocol);

    // 订阅地址，注意是consumer://协议
    URL subscribeUrl = new URL(Constants.CONSUMER_PROTOCOL, NetUtils.getLocalHost(), 0, 
        type.getName(), directory.getUrl().getParameters());

    // 是否需要在注册中心注册消费者，注册分类consumers
    if (! Constants.ANY_VALUE.equals(url.getServiceInterface())
            && url.getParameter(Constants.REGISTER_KEY, true)) {
        registry.register(subscribeUrl.addParameters(Constants.CATEGORY_KEY, Constants.CONSUMERS_CATEGORY,
                Constants.CHECK_KEY, String.valueOf(false)));
    }

    // 订阅注册中心，注意订阅了三个类别：providers、configurators、routers
    directory.subscribe(subscribeUrl.addParameter(Constants.CATEGORY_KEY, 
            Constants.PROVIDERS_CATEGORY 
            + "," + Constants.CONFIGURATORS_CATEGORY 
            + "," + Constants.ROUTERS_CATEGORY));

    return cluster.join(directory);
}
{% endhighlight %}


第一步，创建注册目录对象。关于注册目录，参考《[注册目录](/2017/06/01/dubbo-source-registry-directory)》。

{% highlight java %}
RegistryDirectory<T> directory = new RegistryDirectory<T>(type, url);
directory.setRegistry(registry); //registry是实际对象，在refer()里面攒尖顶
directory.setProtocol(protocol); //protocol是适配器对象
{% endhighlight %}


第二步：创建订阅地址定制，或者说是消费者地址，该地址是consumer://协议。

{% highlight java %}
URL subscribeUrl = new URL(Constants.CONSUMER_PROTOCOL, NetUtils.getLocalHost(), 0, 
        type.getName(), directory.getUrl().getParameters());
{% endhighlight %}


第三步，检查是否需要在注册中心注册消费者。注册的目的是在zookeeper创建一个对应该消费者的地址，目的是为管理后台使用。

{% highlight java %}
if (! Constants.ANY_VALUE.equals(url.getServiceInterface())
        && url.getParameter(Constants.REGISTER_KEY, true)) {
    registry.register(subscribeUrl.addParameters(Constants.CATEGORY_KEY, Constants.CONSUMERS_CATEGORY,
            Constants.CHECK_KEY, String.valueOf(false)));
}
{% endhighlight %}


第四步，订阅注册中心，注意这里订阅了三个类别：providers、configurators、routers，说明当这三个类别任意一个有变化时，都会通知到directory。

{% highlight java %}
directory.subscribe(subscribeUrl.addParameter(Constants.CATEGORY_KEY, 
        Constants.PROVIDERS_CATEGORY 
        + "," + Constants.CONFIGURATORS_CATEGORY 
        + "," + Constants.ROUTERS_CATEGORY));
{% endhighlight %}


第四步，将directory作为参数传递给cluster，返回一个支持集群功能功能的Invoker。关于集群，参考《[集群](/2017/06/01/dubbo-source-cluster)》。

{% highlight java %}
return cluster.join(directory);
{% endhighlight %}

