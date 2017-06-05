---
layout: post
title: Dubbo 源码分析 - 路由规则
---

Router的作用是根据调用信息，在多个Invoker中做一次过滤，选出一个子集。

{% highlight java %}
public interface Router extends Comparable<Router> {
    URL getUrl();
    <T> List<Invoker<T>> route(List<Invoker<T>> invokers, 
            URL url, Invocation invocation) throws RpcException;

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

    public <T> List<Invoker<T>> route(List<Invoker<T>> invokers, 
                URL url, Invocation invocation) throws RpcException {
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
            logger.error("route error");
            return invokers;
        }
    }
}
{% endhighlight %}


Route的使用主要是RegistryDirectory中，依据注册中心的变更信息，创建Router对象。

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
        RouterFactory routerFactory = ExtensionLoader.getExtensionLoader(RouterFactory.class)
                    .getExtension(routerkey);
        routers.add(routerFactory.getRouter(url));
    }

    // 这里加入了一个通用的MockInvokersSelector对象。
    // MockInvokersSelector类的compareTo()方法有点特殊，统统返回1，保证排在最前面。
    routers.add(new MockInvokersSelector());

    // Router实现了Comparable，可以排序
    // 目前是根据URL中提供的priority排序。
    Collections.sort(routers);

    this.routers = routers;
}
{% endhighlight %}


最后，RegistryDirectory的list()方法被调用时，依次调用所有的Router，过滤Invoker列表。

{% highlight java %}
public List<Invoker<T>> list(Invocation invocation) throws RpcException {
    List<Invoker<T>> invokers = doList(invocation);

    List<Router> localRouters = this.routers; // local reference
    if (localRouters != null && localRouters.size() > 0) {

        // 依次调用所有的Router
        for (Router router: localRouters){
            try {
                if (router.getUrl() == null || router.getUrl().getParameter(Constants.RUNTIME_KEY, true)) {
                    invokers = router.route(invokers, getConsumerUrl(), invocation);
                }
            } catch (Throwable t) {
                logger.error("Failed to execute router: " + getUrl() + ", cause: " + t.getMessage(), t);
            }
        }
    }

    return invokers;
}
{% endhighlight %}




