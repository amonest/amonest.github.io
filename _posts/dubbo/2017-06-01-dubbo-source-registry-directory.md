---
layout: post
title: Dubbo 源码分析 - 注册目录
---

Directory是一个接口，提供的list()方法可以根据传递进来的invocation参数，返回一个可用的Invoker列表。

所以在Directory的内部，需要保存一个Invoker列表。

{% highlight java %}
public interface Directory<T> extends Node {
    List<Invoker<T>> list(Invocation invocation) throws RpcException;
    Class<T> getInterface();
}
{% endhighlight %}


Directory接口的主要实现是RegistryDirectory类，提供有注册中心功能支持的接口服务。

{% highlight java %}
public class RegistryDirectory<T> extends AbstractDirectory<T> implements NotifyListener {

    // serviceType=HelloService.class
    // url=zookeeper://192.168.12.84:2181/
    // 这里的url是注册中心网址，协议是zookeeper，路径是com.alibaba.dubbo.registry.RegistryService
    // 注意注册中心网址里面有一个refer参数，是一个编码encode后的参数键值组合，不是网址，没有协议。

    public RegistryDirectory(Class<T> serviceType, URL url) {
        super(url);
        this.serviceType = serviceType;

        // com.alibaba.dubbo.registry.RegistryService
        this.serviceKey = url.getServiceKey();

        // ReferenceConfig传给来的引用参数
        this.queryMap = StringUtils.parseQueryString(url.getParameterAndDecoded(Constants.REFER_KEY));

        // zookeeper://192.168.12.84:2181
        this.overrideDirectoryUrl = this.directoryUrl = 
                url.setPath(url.getServiceInterface())
                    .clearParameters()
                    .addParameters(queryMap)
                    .removeParameter(Constants.MONITOR_KEY);

        String group = directoryUrl.getParameter( Constants.GROUP_KEY, "" );
        this.multiGroup = group != null && ("*".equals(group) || group.contains( "," ));

        // sayHello,sayBye
        String methods = queryMap.get(Constants.METHODS_KEY);
        this.serviceMethods = methods == null ? null : Constants.COMMA_SPLIT_PATTERN.split(methods);
    }
}
{% endhighlight %}


RegistryDirectory内部有一个registry属性，同时也实现了NotifyListener接口，所以它可以订阅注册中心，也可以接收注册中心点的变更通知。

{% highlight java %}
public void subscribe(URL url) {
    setConsumerUrl(url);

    // 订阅注册中心，并设置自己为变更通知接收者
    registry.subscribe(url, this);
}
{% endhighlight %}



当注册中心有变更时，触发RegistryDirectory的notify()方法。

{% highlight java %}
public synchronized void notify(List<URL> urls) {

    // RegistryDirectory目前支持三类服务：
    //   providers => Invoker，服务提供者
    //   router    => Router，路由器
    //   configurators => Configurator，配置管理

    List<URL> invokerUrls = new ArrayList<URL>();
    List<URL> routerUrls = new ArrayList<URL>();
    List<URL> configuratorUrls = new ArrayList<URL>();

    for (URL url : urls) {
        String protocol = url.getProtocol();
        String category = url.getParameter(Constants.CATEGORY_KEY, Constants.DEFAULT_CATEGORY);
        if (Constants.ROUTERS_CATEGORY.equals(category) 
                || Constants.ROUTE_PROTOCOL.equals(protocol)) {
            routerUrls.add(url);
        } else if (Constants.CONFIGURATORS_CATEGORY.equals(category) 
                || Constants.OVERRIDE_PROTOCOL.equals(protocol)) {
            configuratorUrls.add(url);
        } else if (Constants.PROVIDERS_CATEGORY.equals(category)) {
            invokerUrls.add(url);
        } else {
            logger.warn("Unsupported category " + category);
        }
    }

    // 路由器
    if (routerUrls != null && routerUrls.size() >0 ){
        List<Router> routers = toRouters(routerUrls);
        if(routers != null){ // null - do nothing
            setRouters(routers);
        }
    }

    // 配置
    if (configuratorUrls != null && configuratorUrls.size() >0 ){
        this.configurators = toConfigurators(configuratorUrls);
    }

    List<Configurator> localConfigurators = this.configurators; // local reference

    // 合并override参数
    this.overrideDirectoryUrl = directoryUrl;
    if (localConfigurators != null && localConfigurators.size() > 0) {
        for (Configurator configurator : localConfigurators) {
            this.overrideDirectoryUrl = configurator.configure(overrideDirectoryUrl);
        }
    }

    // 提供者
    refreshInvoker(invokerUrls);
}
{% endhighlight %}


notify()提供了三类信息的处理方法：router、configurator和provider。

这里重点说明的是provider，router和configurator参考[《路由规则》](/2017/06/01/dubbo-source-router)和[《配置规则》](/2017/06/01/dubbo-source-configurator)。


在notify()的结尾，调用了refreshInvokers()方法，刷新invokerUrls。

{% highlight java %}
private void refreshInvoker(List<URL> invokerUrls){
    if (invokerUrls != null && invokerUrls.size() == 1 && invokerUrls.get(0) != null
            && Constants.EMPTY_PROTOCOL.equals(invokerUrls.get(0).getProtocol())) {
        this.forbidden = true; // 禁止访问
        this.methodInvokerMap = null; // 置空列表
        destroyAllInvokers(); // 关闭所有Invoker
    } else {

        this.forbidden = false; // 允许访问

        Map<String, Invoker<T>> oldUrlInvokerMap = this.urlInvokerMap; // local reference
        if (invokerUrls.size() == 0 && this.cachedInvokerUrls != null){
            invokerUrls.addAll(this.cachedInvokerUrls);
        } else {
            this.cachedInvokerUrls = new HashSet<URL>();
            this.cachedInvokerUrls.addAll(invokerUrls);//缓存invokerUrls列表，便于交叉对比
        }
        if (invokerUrls.size() ==0 ){
            return;
        }

        // 将URL列表转成Invoker列表
        Map<String, Invoker<T>> newUrlInvokerMap = toInvokers(invokerUrls) ;

        // 换方法名映射Invoker列表
        Map<String, List<Invoker<T>>> newMethodInvokerMap = toMethodInvokers(newUrlInvokerMap); 
        
        // state change
        //如果计算错误，则不进行处理.
        if (newUrlInvokerMap == null || newUrlInvokerMap.size() == 0 ){
            logger.error(new IllegalStateException("urls to invokers error"));
            return ;
        }
        this.methodInvokerMap = multiGroup ? 
                    toMergeMethodInvokerMap(newMethodInvokerMap) : newMethodInvokerMap;
        this.urlInvokerMap = newUrlInvokerMap;
        try{
            destroyUnusedInvokers(oldUrlInvokerMap,newUrlInvokerMap); // 关闭未使用的Invoker
        }catch (Exception e) {
            logger.warn("destroyUnusedInvokers error. ", e);
        }
    }
}
{% endhighlight %}


第一步，调用toInvokers()将URL转换成Invoker对象，返回Url到Invoker的映射关系。

{% highlight java %}
private Map<String, Invoker<T>> toInvokers(List<URL> urls) {
    Map<String, Invoker<T>> newUrlInvokerMap = new HashMap<String, Invoker<T>>();
    if(urls == null || urls.size() == 0){
        return newUrlInvokerMap;
    }

    Set<String> keys = new HashSet<String>();
    String queryProtocols = this.queryMap.get(Constants.PROTOCOL_KEY);

    for (URL providerUrl : urls) {

        // 如果reference端配置了protocol，则只选择匹配的protocol
        if (queryProtocols != null && queryProtocols.length() >0) {
            boolean accept = false;
            String[] acceptProtocols = queryProtocols.split(",");
            for (String acceptProtocol : acceptProtocols) {
                if (providerUrl.getProtocol().equals(acceptProtocol)) {
                    accept = true;
                    break;
                }
            }
            if (!accept) {
                continue;
            }
        }

        if (Constants.EMPTY_PROTOCOL.equals(providerUrl.getProtocol())) {
            continue;
        }

        if (! ExtensionLoader.getExtensionLoader(Protocol.class).hasExtension(providerUrl.getProtocol())) {
            logger.error(new IllegalStateException("Unsupported protocol " + providerUrl.getProtocol()));
            continue;
        }

        URL url = mergeUrl(providerUrl);
        
        String key = url.toFullString(); // URL参数是排序的
        if (keys.contains(key)) { // 重复URL
            continue;
        }

        keys.add(key);

        // 缓存key为没有合并消费端参数的URL，不管消费端如何合并参数，如果服务端URL发生变化，则重新refer
        Map<String, Invoker<T>> localUrlInvokerMap = this.urlInvokerMap; // local reference
        Invoker<T> invoker = localUrlInvokerMap == null ? null : localUrlInvokerMap.get(key);
        if (invoker == null) { // 缓存中没有，重新refer
            try {
                boolean enabled = true;
                if (url.hasParameter(Constants.DISABLED_KEY)) {
                    enabled = ! url.getParameter(Constants.DISABLED_KEY, false);
                } else {
                    enabled = url.getParameter(Constants.ENABLED_KEY, true);
                }

                if (enabled) {

                    // 创建实际的Invoker对象，外面用InvokerDelegete包装
                    invoker = new InvokerDelegete<T>(protocol.refer(serviceType, url), url, providerUrl);

                }

            } catch (Throwable t) {
                logger.error("Failed to refer invoker for interface");
            }

            if (invoker != null) { // 将新的引用放入缓存
                newUrlInvokerMap.put(key, invoker);
            }
        } else {
            newUrlInvokerMap.put(key, invoker);
        }
    }
    keys.clear();
    return newUrlInvokerMap;
}
{% endhighlight %}

这里的mergeUrl()方法对providerUrl做合并处理。

{% highlight java %}
private URL mergeUrl(URL providerUrl) {

    // 合并Reference配置参数
    providerUrl = ClusterUtils.mergeUrl(providerUrl, queryMap);
    
    // 合并Configurator对象
    List<Configurator> localConfigurators = this.configurators; // local reference
    if (localConfigurators != null && localConfigurators.size() > 0) {
        for (Configurator configurator : localConfigurators) {
            providerUrl = configurator.configure(providerUrl);
        }
    }
    
    // 不检查连接是否成功，总是创建Invoker！
    providerUrl = providerUrl.addParameter(Constants.CHECK_KEY, String.valueOf(false)); 
    
    // directoryUrl 与 override 合并是在notify的最后，这里不能够处理
    this.overrideDirectoryUrl = this.overrideDirectoryUrl
            .addParametersIfAbsent(providerUrl.getParameters()); // 合并提供者参数 

    return providerUrl;
}
{% endhighlight %}


实际的Invoker是通过protocol.refer()创建的，参考[《Dubbo协议》](/2017/06/01/dubbo-source-dubbo-protocol)。

{% highlight java %}
protocol.refer(serviceType, url)
{% endhighlight %}


外面包装了一个InvokerDelegete代理：

{% highlight java %}
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
{% endhighlight %}


第二步：调用toMethodInvokers()，依据Url到Invoker的映射关系，建立method name到Invoker List映射关系。

{% highlight java %}
private Map<String, List<Invoker<T>>> toMethodInvokers(Map<String, Invoker<T>> invokersMap) {

    // 参数invokersMap，key=url string, value=invoker

    Map<String, List<Invoker<T>>> newMethodInvokerMap = new HashMap<String, List<Invoker<T>>>();
    List<Invoker<T>> invokersList = new ArrayList<Invoker<T>>();

    // 这里区分两类Invoker

    if (invokersMap != null && invokersMap.size() > 0) {
        for (Invoker<T> invoker : invokersMap.values()) {

            String parameter = invoker.getUrl().getParameter(Constants.METHODS_KEY);
            if (parameter != null && parameter.length() > 0) {
                String[] methods = Constants.COMMA_SPLIT_PATTERN.split(parameter);
                if (methods != null && methods.length > 0) {
                    for (String method : methods) {
                        if (method != null && method.length() > 0 
                                && ! Constants.ANY_VALUE.equals(method)) {
                            List<Invoker<T>> methodInvokers = newMethodInvokerMap.get(method);
                            if (methodInvokers == null) {
                                methodInvokers = new ArrayList<Invoker<T>>();
                                newMethodInvokerMap.put(method, methodInvokers);
                            }
                            methodInvokers.add(invoker);
                        }
                    }
                }
            }

            invokersList.add(invoker);
        }
    }

    newMethodInvokerMap.put(Constants.ANY_VALUE, invokersList);

    // serviceMethods实在RegistryDirectory构造方法中从reference端配置参数里面获取的
    if (serviceMethods != null && serviceMethods.length > 0) {
        for (String method : serviceMethods) {
            List<Invoker<T>> methodInvokers = newMethodInvokerMap.get(method);
            if (methodInvokers == null || methodInvokers.size() == 0) {
                methodInvokers = invokersList;
            }

            // 注意，这里调用route()方法对method过滤路由。
            newMethodInvokerMap.put(method, route(methodInvokers, method));
        }
    }

    // sort and unmodifiable
    for (String method : new HashSet<String>(newMethodInvokerMap.keySet())) {
        List<Invoker<T>> methodInvokers = newMethodInvokerMap.get(method);
        Collections.sort(methodInvokers, InvokerComparator.getComparator());
        newMethodInvokerMap.put(method, Collections.unmodifiableList(methodInvokers));
    }

    return Collections.unmodifiableMap(newMethodInvokerMap);
}
{% endhighlight %}

注意，这里调用route()方法对method过滤路由。

{% highlight java %}
private List<Invoker<T>> route(List<Invoker<T>> invokers, String method) {
    Invocation invocation = new RpcInvocation(method, new Class<?>[0], new Object[0]);
    List<Router> routers = getRouters(); 
    if (routers != null) {
        for (Router router : routers) {
            if (router.getUrl() != null && ! router.getUrl().getParameter(Constants.RUNTIME_KEY, true)) {
                invokers = router.route(invokers, getConsumerUrl(), invocation);
            }
        }
    }
    return invokers;
}
{% endhighlight %}


第三步：调用toMergeMethodInvokerMap()。

{% highlight java %}
private Map<String, List<Invoker<T>>> toMergeMethodInvokerMap(Map<String, List<Invoker<T>>> methodMap) {
    Map<String, List<Invoker<T>>> result = new HashMap<String, List<Invoker<T>>>();

    for (Map.Entry<String, List<Invoker<T>>> entry : methodMap.entrySet()) {
        String method = entry.getKey();
        List<Invoker<T>> invokers = entry.getValue();        
        Map<String, List<Invoker<T>>> groupMap = new HashMap<String, List<Invoker<T>>>();

        for (Invoker<T> invoker : invokers) {
            String group = invoker.getUrl().getParameter(Constants.GROUP_KEY, "");
            List<Invoker<T>> groupInvokers = groupMap.get(group);
            if (groupInvokers == null) {
                groupInvokers = new ArrayList<Invoker<T>>();
                groupMap.put(group, groupInvokers);
            }
            groupInvokers.add(invoker);
        }

        if (groupMap.size() == 1) {
            result.put(method, groupMap.values().iterator().next());
        } else if (groupMap.size() > 1) {
            List<Invoker<T>> groupInvokers = new ArrayList<Invoker<T>>();
            for (List<Invoker<T>> groupList : groupMap.values()) {
                groupInvokers.add(cluster.join(new StaticDirectory<T>(groupList)));
            }
            result.put(method, groupInvokers);
        } else {
            result.put(method, invokers);
        }
    }
    return result;
}
{% endhighlight %}


第四步：调用destroyUnusedInvokers()，删除失效的Invoker。

{% highlight java %}
 private void destroyUnusedInvokers(Map<String, Invoker<T>> oldUrlInvokerMap, 
                                Map<String, Invoker<T>> newUrlInvokerMap) {
    if (newUrlInvokerMap == null || newUrlInvokerMap.size() == 0) {
        destroyAllInvokers();
        return;
    }

    // check deleted invoker
    List<String> deleted = null;
    if (oldUrlInvokerMap != null) {
        Collection<Invoker<T>> newInvokers = newUrlInvokerMap.values();
        for (Map.Entry<String, Invoker<T>> entry : oldUrlInvokerMap.entrySet()){
            if (! newInvokers.contains(entry.getValue())) {
                if (deleted == null) {
                    deleted = new ArrayList<String>();
                }
                deleted.add(entry.getKey());
            }
        }
    }
    
    if (deleted != null) {
        for (String url : deleted){
            if (url != null ) {
                Invoker<T> invoker = oldUrlInvokerMap.remove(url);
                if (invoker != null) {
                    try {
                        invoker.destroy();
                    } catch (Exception e) {
                        logger.warn("destory invoker faild. ");
                    }
                }
            }
        }
    }
}
{% endhighlight %}


到这里，RegistryDirectory的notity()就通知完毕，urlInvokerMap和methodInvokerMap有了最新的Invoker。

RegistryDirectory除了notify()，另外一个关键是list()，这里面就用到了更新后的methodInvokerMap。

{% highlight java %}
public List<Invoker<T>> list(Invocation invocation) throws RpcException {
    // 调用doList()方法
    List<Invoker<T>> invokers = doList(invocation);

    // 循环所有Router，过滤Invoker
    List<Router> localRouters = this.routers; // local reference
    if (localRouters != null && localRouters.size() > 0) {
        for (Router router: localRouters){
            try {
                if (router.getUrl() == null || router.getUrl().getParameter(Constants.RUNTIME_KEY, true)) {
                    invokers = router.route(invokers, getConsumerUrl(), invocation);
                }
            } catch (Throwable t) {
                logger.error("Failed to execute router: " + getUrl());
            }
        }
    }

    return invokers;
}

public List<Invoker<T>> doList(Invocation invocation) {
    if (forbidden) {
        throw new RpcException(RpcException.FORBIDDEN_EXCEPTION);
    }

    List<Invoker<T>> invokers = null;
    Map<String, List<Invoker<T>>> localMethodInvokerMap = this.methodInvokerMap; // local reference
    if (localMethodInvokerMap != null && localMethodInvokerMap.size() > 0) {
        String methodName = RpcUtils.getMethodName(invocation);
        Object[] args = RpcUtils.getArguments(invocation);

        if(args != null && args.length > 0 && args[0] != null
                && (args[0] instanceof String || args[0].getClass().isEnum())) {
            // 可根据第一个参数枚举路由
            invokers = localMethodInvokerMap.get(methodName + "." + args[0]);
        }

        if(invokers == null) {
            invokers = localMethodInvokerMap.get(methodName);
        }

        if(invokers == null) {
            invokers = localMethodInvokerMap.get(Constants.ANY_VALUE);
        }

        if(invokers == null) {
            Iterator<List<Invoker<T>>> iterator = localMethodInvokerMap.values().iterator();
            if (iterator.hasNext()) {
                invokers = iterator.next();
            }
        }
    }
    return invokers == null ? new ArrayList<Invoker<T>>(0) : invokers;
}
{% endhighlight %}
