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


---

### Directory 目录服务

Directory是一个接口，提供list的()方法可以根据传递进来的invocation参数，返回一个可用的Invoker列表。

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
    // url=zookeeper://192.168.12.84:2181/com.alibaba.dubbo.registry.RegistryService?application=dubbo-client&dubbo=2.5.4-SNAPSHOT&pid=10888&refer=application%3Ddubbo-client%26dubbo%3D2.5.4-SNAPSHOT%26interface%3Dnet.mingyang.simple_dubbo_server.HelloService%26methods%3DsayHello%2CsayBye%26pid%3D10888%26side%3Dconsumer%26timestamp%3D1495697621982&timestamp=1495697644516
    // 这里的url是注册中心网址，协议是zookeeper，路径是com.alibaba.dubbo.registry.RegistryService
    // 注意注册中心网址里面有一个refer参数，是一个编码encode后的参数键值组合，不是网址，没有协议。
    public RegistryDirectory(Class<T> serviceType, URL url) {
        super(url);
        this.serviceType = serviceType;

        // com.alibaba.dubbo.registry.RegistryService
        this.serviceKey = url.getServiceKey();

        this.queryMap = StringUtils.parseQueryString(url.getParameterAndDecoded(Constants.REFER_KEY));

        // zookeeper://192.168.12.84:2181/com.alibaba.dubbo.registry.RegistryService?application=dubbo-client&dubbo=2.5.4-SNAPSHOT&interface=net.mingyang.simple_dubbo_server.HelloService&methods=sayHello,sayBye&pid=10888&side=consumer&timestamp=1495697621982
        this.overrideDirectoryUrl = this.directoryUrl = url.setPath(url.getServiceInterface()).clearParameters().addParameters(queryMap).removeParameter(Constants.MONITOR_KEY);

        String group = directoryUrl.getParameter( Constants.GROUP_KEY, "" );
        this.multiGroup = group != null && ("*".equals(group) || group.contains( "," ));

        // sayHello,sayBye
        String methods = queryMap.get(Constants.METHODS_KEY);
        this.serviceMethods = methods == null ? null : Constants.COMMA_SPLIT_PATTERN.split(methods);
    }
}
{% endhighlight %}


RegistryDirectory实现类NotifyListener接口，所以可以作为订阅注册中心的通知接受者。

RegistryDirectory提供了subscribe()方法，该方法可以订阅注册中心。

{% highlight java %}
public void subscribe(URL url) {
    setConsumerUrl(url);
    registry.subscribe(url, this);
}
{% endhighlight %}

当注册中心检测到提供者地址有变化时，触发RegistryDirectory的notify()方法。

{% highlight java %}
public synchronized void notify(List<URL> urls) {

    // RegistryDirectory目前支持三类注册中心服务：
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
            logger.warn("Unsupported category " + category + " in notified url: " + url + " from registry " + getUrl().getAddress() + " to consumer " + NetUtils.getLocalHost());
        }
    }


    // 关于Router的处理，看后面的《路由规则》

    // routers
    if (routerUrls != null && routerUrls.size() >0 ){
        List<Router> routers = toRouters(routerUrls);
        if(routers != null){ // null - do nothing
            setRouters(routers);
        }
    }


    // 关于Configurator的处理，看后面的《配置规则》

    // configurators 
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

    // providers
    refreshInvoker(invokerUrls);
}
{% endhighlight %}


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
        Map<String, List<Invoker<T>>> newMethodInvokerMap = toMethodInvokers(newUrlInvokerMap); // 换方法名映射Invoker列表
        
        // state change
        //如果计算错误，则不进行处理.
        if (newUrlInvokerMap == null || newUrlInvokerMap.size() == 0 ){
            logger.error(new IllegalStateException("urls to invokers error .invokerUrls.size :"+invokerUrls.size() + ", invoker.size :0. urls :"+invokerUrls.toString()));
            return ;
        }
        this.methodInvokerMap = multiGroup ? toMergeMethodInvokerMap(newMethodInvokerMap) : newMethodInvokerMap;
        this.urlInvokerMap = newUrlInvokerMap;
        try{
            destroyUnusedInvokers(oldUrlInvokerMap,newUrlInvokerMap); // 关闭未使用的Invoker
        }catch (Exception e) {
            logger.warn("destroyUnusedInvokers error. ", e);
        }
    }
}
{% endhighlight %}



---

### Registry 注册中心

Registry注册中心是一个接口，提供了注册和订阅两种功能，这里主要说明其中的订阅功能。

{% highlight java %}
public interface Registry {
    void subscribe(URL url, NotifyListener listener);
    void unsubscribe(URL url, NotifyListener listener);
}
{% endhighlight %}

ZookeeperRegistry是Registry接口的一个实现类，提供Zookeeper注册中心功能。

{% highlight java %}
public class ZookeeperRegistry extends FailbackRegistry {

    public void subscribe(URL url, NotifyListener listener) {
        //url=consumer://192.168.12.84/net.mingyang.simple_dubbo_server.HelloService?application=dubbo-client&category=providers,configurators,routers&dubbo=2.5.4-SNAPSHOT&interface=net.mingyang.simple_dubbo_server.HelloService&methods=sayHello,sayBye&pid=15260&side=consumer&timestamp=1496200522227

        // 将注册信息保存到subscribed
        // 这一段代码实质在AbstractRegistry
        Set<NotifyListener> listeners = subscribed.get(url);
        if (listeners == null) {
            subscribed.putIfAbsent(url, new ConcurrentHashSet<NotifyListener>());
            listeners = subscribed.get(url);
        }
        listeners.add(listener);

        List<URL> urls = new ArrayList<URL>();

        // 将URL转换成ZK路径，格式如下：
        //  /dubbo/net.mingyang.simple_dubbo_server.HelloService/providers
        //  /dubbo/net.mingyang.simple_dubbo_server.HelloService/configurators
        //  /dubbo/net.mingyang.simple_dubbo_server.HelloService/routers

        for (String path : toCategoriesPath(url)) {
            ConcurrentMap<NotifyListener, ChildListener> listeners = zkListeners.get(url);
            if (listeners == null) {
                zkListeners.putIfAbsent(url, new ConcurrentHashMap<NotifyListener, ChildListener>());
                listeners = zkListeners.get(url);
            }

            // 这里形成一个对应关系：
            //  listener(NotifyListener) -> zkListener(ChildListener)

            ChildListener zkListener = listeners.get(listener);
            if (zkListener == null) {
                listeners.putIfAbsent(listener, new ChildListener() {
                    public void childChanged(String parentPath, List<String> currentChilds) {
                        ZookeeperRegistry.this.notify(url, listener, toUrlsWithEmpty(url, parentPath, currentChilds));
                    }
                });
                zkListener = listeners.get(listener);
            }

            // 防御性处理, 有可能订阅的路径不存在, 这里可以先建立
            zkClient.create(path, false);

            List<String> children = zkClient.addChildListener(path, zkListener);
            if (children != null) {
                urls.addAll(toUrlsWithEmpty(url, path, children));
            }
        }

        // 最后, 调用notify()通知NotifyListener
        notify(url, listener, urls);
    }
}
{% endhighlight %}

在subscribe()的最后，用获取的URL列表调用了notify()，目的是回调NotifyListener的notify()方法。

{% highlight java %}
protected void notify(URL url, NotifyListener listener, List<URL> urls) {
    // url=是消费者URL，以consumer://开始
    // urls=是注册中心返回的网址列表

    // 最终的result是这样的一个结构：
    //  providers = [url1, url2, url3, ...]
    //  routers = [url1, url2, url3, ...]
    //  configurators = [url1, url2, url3, ...]

    Map<String, List<URL>> result = new HashMap<String, List<URL>>();

    for (URL u : urls) {
        // 检查提供者URL和消费者URL是否匹配?
        if (UrlUtils.isMatch(url, u)) {
            String category = u.getParameter(Constants.CATEGORY_KEY, Constants.DEFAULT_CATEGORY);
            List<URL> categoryList = result.get(category);
            if (categoryList == null) {
                categoryList = new ArrayList<URL>();
                result.put(category, categoryList);
            }
            categoryList.add(u);
        }
    }

    if (result.size() == 0) {
        return;
    }

    Map<String, List<URL>> categoryNotified = notified.get(url);
    if (categoryNotified == null) {
        notified.putIfAbsent(url, new ConcurrentHashMap<String, List<URL>>());
        categoryNotified = notified.get(url);
    }

    for (Map.Entry<String, List<URL>> entry : result.entrySet()) {
        String category = entry.getKey();
        List<URL> categoryList = entry.getValue();
        categoryNotified.put(category, categoryList);

        // 缓存notified到本地properties文件
        saveProperties(url);

        // 回调NotifyListener接口，比如RegistryDirectory
        listener.notify(categoryList);
    }
}
{% endhighlight %}




---

### Configurator 配置规则

如果注册中心返回的网址是override://协议或者category=configurators，说明这是一个配置规则，通过toConfigurators()转化成Configurator对象。

{% highlight java %}
public static List<Configurator> toConfigurators(List<URL> urls){
    List<Configurator> configurators = new ArrayList<Configurator>(urls.size());
    if (urls == null || urls.size() == 0){
        return configurators;
    }

    for(URL url : urls){
        if (Constants.EMPTY_PROTOCOL.equals(url.getProtocol())) {
            configurators.clear();
            break;
        }

        Map<String,String> override = new HashMap<String, String>(url.getParameters());

        //override 上的anyhost可能是自动添加的，不能影响改变url判断
        override.remove(Constants.ANYHOST_KEY);

        if (override.size() == 0){
            configurators.clear();
            continue;
        }
        configurators.add(configuratorFactory.getConfigurator(url));
    }

    // Configurator实现了Comparable接口，可以排序
    // 目前的排序实现是比较getUrl().getHost()
    Collections.sort(configurators);

    return configurators;
}
{% endhighlight %}

配置规则的目的是修改directoryUrl，对所有的Configurator依次调用：

{% highlight java %}
List<Configurator> localConfigurators = this.configurators;
this.overrideDirectoryUrl = directoryUrl;
if (localConfigurators != null && localConfigurators.size() > 0) {
    for (Configurator configurator : localConfigurators) {
        this.overrideDirectoryUrl = configurator.configure(overrideDirectoryUrl);
    }
}
{% endhighlight %}

目前Configurator接口有两个实现类：OverrideConfigurator和AbsentConfigurator。例如，OverrideConfigurator是这样处理的：

{% highlight java %}
public class OverrideConfigurator extends AbstractConfigurator {    
    public OverrideConfigurator(URL url) {
        super(url);
    }

    public URL doConfigure(URL currentUrl, URL configUrl) {
        return currentUrl.addParameters(configUrl.getParameters());
    }
}
{% endhighlight %}

配置规则有匹配条件。例如：

* override://0.0.0.0:2145/ 这个规则全局有效，所有提供者都试用

* override://192.168.12.30:2145/ 这个规则只针对192.168.12.30提供者有效

{% highlight java %}
public abstract class AbstractConfigurator implements Configurator {    
    private final URL configuratorUrl;

    public AbstractConfigurator(URL url) {
        this.configuratorUrl = url;
    }

    public URL configure(URL url) {
        // 1. 比较host
        if (Constants.ANYHOST_VALUE.equals(configuratorUrl.getHost()) 
                || url.getHost().equals(configuratorUrl.getHost())) {

            // 2. 比较application
            String configApplication = configuratorUrl.getParameter(Constants.APPLICATION_KEY, configuratorUrl.getUsername());
            String currentApplication = url.getParameter(Constants.APPLICATION_KEY, url.getUsername());
            if (configApplication == null || Constants.ANY_VALUE.equals(configApplication) 
                    || configApplication.equals(currentApplication)) {

                // 3. 比较host
                if (configuratorUrl.getPort() == 0 || url.getPort() == configuratorUrl.getPort()) {

                    Set<String> condtionKeys = new HashSet<String>();
                    condtionKeys.add(Constants.CATEGORY_KEY);
                    condtionKeys.add(Constants.CHECK_KEY);
                    condtionKeys.add(Constants.DYNAMIC_KEY);
                    condtionKeys.add(Constants.ENABLED_KEY);
                    for (Map.Entry<String, String> entry : configuratorUrl.getParameters().entrySet()) {
                        String key = entry.getKey();
                        String value = entry.getValue();
                        if (key.startsWith("~") || Constants.APPLICATION_KEY.equals(key) 
                                || Constants.SIDE_KEY.equals(key)) {
                            condtionKeys.add(key);

                            // 4. 比较其它的查询参数
                            if (value != null && ! Constants.ANY_VALUE.equals(value)
                                    && ! value.equals(url.getParameter(key.startsWith("~") ? key.substring(1) : key))) {
                                return url;
                            }
                        }
                    }

                    return doConfigure(url, configuratorUrl.removeParameters(condtionKeys));
                }
            }
        }
        return url;
    }
}
{% endhighlight %}



---

### Router 路由规则

如果注册中心返回的网址是router://协议或者category=routers，说明这是一个路由规则，通过toRouters()转化成Router对象。

{% highlight java %}
private List<Router> toRouters(List<URL> urls) {
    List<Router> routers = new ArrayList<Router>();
    if(urls == null || urls.size() < 1){
        return routers ;
    }

    if (urls != null && urls.size() > 0) {
        for (URL url : urls) {
            if (Constants.EMPTY_PROTOCOL.equals(url.getProtocol())) {
                continue;
            }

            String routerType = url.getParameter(Constants.ROUTER_KEY);
            if (routerType != null && routerType.length() > 0){
                url = url.setProtocol(routerType);
            }

            try{
                Router router = routerFactory.getRouter(url);
                if (!routers.contains(router))
                    routers.add(router);
            } catch (Throwable t) {
                logger.error("convert router url to router error, url: "+ url, t);
            }
        }
    }
    return routers;
}
{% endhighlight %}

toRouters()转化后的Router对象列表通过setRouters()注入到RegistryDirectory。

{% highlight java %}
protected void setRouters(List<Router> routers){
    // copy list
    routers = routers == null ? new  ArrayList<Router>() : new ArrayList<Router>(routers);

    // append url router
    String routerkey = url.getParameter(Constants.ROUTER_KEY);
    if (routerkey != null && routerkey.length() > 0) {
        RouterFactory routerFactory = ExtensionLoader.getExtensionLoader(RouterFactory.class).getExtension(routerkey);
        routers.add(routerFactory.getRouter(url));
    }

    // append mock invoker selector
    // 这里加入了一个通用的MockInvokersSelector对象。
    // MockInvokersSelector类的compareTo()方法有点特殊，统统返回1，这是放在最后，还是放在最前面？
    routers.add(new MockInvokersSelector());

    // Router实现了Comparable，可以排序
    // 目前是根据URL中提供的priority排序。
    Collections.sort(routers);

    this.routers = routers;
}
{% endhighlight %}

目前Router接口有三个实现类：ScriptRouter、ConditionRouter和MockInvokersSelector。例如，ScriptRouter是这样处理的：

{% highlight java %}
public class ScriptRouter implements Router {

    public ScriptRouter(URL url) {
        this.url = url;
        String type = url.getParameter(Constants.TYPE_KEY);
        this.priority = url.getParameter(Constants.PRIORITY_KEY, 0);
        this.rule = url.getParameterAndDecoded(Constants.RULE_KEY);
        this.engine = ScriptEngineManager().getEngineByName(type);
    }

    public <T> List<Invoker<T>> route(List<Invoker<T>> invokers, URL url, Invocation invocation) throws RpcException {
        try {
            List<Invoker<T>> invokersCopy = new ArrayList<Invoker<T>>(invokers);
            Compilable compilable = (Compilable) engine;

            // 编译脚本执行环境参数
            Bindings bindings = engine.createBindings();
            bindings.put("invokers", invokersCopy);
            bindings.put("invocation", invocation);
            bindings.put("context", RpcContext.getContext());

            // 调用编译脚本
            CompiledScript function = compilable.compile(rule);
            Object obj = function.eval(bindings);

            // 处理脚本返回结果
            if (obj instanceof Invoker[]) {
                invokersCopy = Arrays.asList((Invoker<T>[]) obj);
            } else if (obj instanceof Object[]) {
                invokersCopy = new ArrayList<Invoker<T>>();
                for (Object inv : (Object[]) obj) {
                    invokersCopy.add((Invoker<T>)inv);
                }
            } else {
                invokersCopy = (List<Invoker<T>>) obj;
            }

            return invokersCopy;
        } catch (ScriptException e) {
            //fail then ignore rule .invokers.
            logger.error("route error , rule has been ignored. rule: " + rule + ", method:" + invocation.getMethodName() + ", url: " + RpcContext.getContext().getUrl(), e);
            return invokers;
        }
    }
}
{% endhighlight %}



