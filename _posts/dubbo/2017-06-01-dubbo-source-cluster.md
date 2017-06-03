---
layout: post
title: Dubbo 源码分析 - 集群
---

Cluster是集群接口，它以Directory作为参数，返回一个Invoker接口。

{% highlight java %}
@SPI(FailoverCluster.NAME)
public interface Cluster {
    <T> Invoker<T> join(Directory<T> directory) throws RpcException;
}
{% endhighlight %}


Directory需要能够封装一个Invoker列表，然后根据调用请求，返回满足条件的Invoker列表。

{% highlight java %}
public interface Directory<T> extends Node {
    Class<T> getInterface();
    List<Invoker<T>> list(Invocation invocation) throws RpcException;    
}
{% endhighlight %}


为什么Cluster要返回Invoker接口呢？

我想这是因为Protocol接口的refer()方法返回的是Invoker接口，而Cluster通常是在Protocol中被调用，返回支持集群功能的Invoker。

{% highlight java %}
public class RegistryProtocol implements Protocol {
    
    private <T> Invoker<T> doRefer(Cluster cluster, Registry registry, Class<T> type, URL url) {
        RegistryDirectory<T> directory = new RegistryDirectory<T>(type, url);

        ... ...

        // 在refer()的最后被调用，返回支持集群功能的Invoker
        return cluster.join(directory);
    }
}
{% endhighlight %}


默认的Cluster是FailoverCluster，它返回的Invoker接口是FailoverClusterInvoker。

{% highlight java %}
public class FailoverCluster implements Cluster {

    public <T> Invoker<T> join(Directory<T> directory) throws RpcException {
        return new FailoverClusterInvoker<T>(directory);
    }
}
{% endhighlight %}


FailoverClusterInvoker内部的处理方式：

{% highlight java %}
public Result doInvoke(Invocation invocation, final List<Invoker<T>> invokers, 
            LoadBalance loadbalance) throws RpcException {

    List<Invoker<T>> copyinvokers = invokers;

    // 获取重试次数，默认只重试一次
    int len = getUrl().getMethodParameter(invocation.getMethodName(), 
            Constants.RETRIES_KEY, Constants.DEFAULT_RETRIES) + 1;
    if (len <= 0) {
        len = 1;
    }

    RpcException le = null; // last exception.
    List<Invoker<T>> invoked = new ArrayList<Invoker<T>>(copyinvokers.size()); // invoked invokers.
    Set<String> providers = new HashSet<String>(len);

    for (int i = 0; i < len; i++) {

        // 重试时，进行重新选择，避免重试时invoker列表已发生变化.
        // 注意：如果列表发生了变化，那么invoked判断会失效，因为invoker示例已经改变
        if (i > 0) {
            copyinvokers = list(invocation);
        }

        Invoker<T> invoker = select(loadbalance, invocation, copyinvokers, invoked);

        // invoked是已经调用过的Invoker，减少重复调用(碰撞)的几率
        invoked.add(invoker);

        RpcContext.getContext().setInvokers((List)invoked);

        try {

            // 将请求传递给选中的invoker，返回Result
            Result result = invoker.invoke(invocation);
            return result;

        } catch (RpcException e) {
            le = e;
        } catch (Throwable e) {
            le = new RpcException(e.getMessage(), e);
        } finally {
            providers.add(invoker.getUrl().getAddress());
        }
    }
    throw new RpcException("Failed to invoke the method");
}
{% endhighlight %}


先看一下list()方法，它的目的是根据invocation返回一个Invoker列表。它将这个功能交给了directory来处理。

{% highlight java %}
protected  List<Invoker<T>> list(Invocation invocation) throws RpcException {
    List<Invoker<T>> invokers = directory.list(invocation);
    return invokers;
}
{% endhighlight %}


再来看select()方法，它从Invoker列表中选择一个用来处理请求的Invoker。

{% highlight java %}
/**
 * 使用loadbalance选择invoker.</br>
 * a)先lb选择，如果在selected列表中 或者 不可用且做检验时，进入下一步(重选),否则直接返回</br>
 * b)重选验证规则：selected > available .保证重选出的结果尽量不在select中，并且是可用的 
 * 
 * @param availablecheck 如果设置true，在选择的时候先选invoker.available == true
 * @param selected 已选过的invoker.注意：输入保证不重复
 * 
 */
protected Invoker<T> select(LoadBalance loadbalance, Invocation invocation, 
                List<Invoker<T>> invokers, List<Invoker<T>> selected) throws RpcException {

    // invokers=从FailoverClusterInvoker传递过来的copyinvokers
    // selected=从FailoverClusterInvoker传递过来的invoked
    
    String methodName = invocation.getMethodName();
    
    // 这里处理sticky粘性问题
    // 粘性是指相同的请求要发给后台同一个服务器来处理
    boolean sticky = invokers.get(0).getUrl().getMethodParameter(methodName,
                        Constants.CLUSTER_STICKY_KEY, Constants.DEFAULT_CLUSTER_STICKY) ;

    // ignore overloaded method
    if ( stickyInvoker != null && !invokers.contains(stickyInvoker) ){
        stickyInvoker = null;
    }

    // ignore cucurrent problem
    if (sticky && stickyInvoker != null && (selected == null || !selected.contains(stickyInvoker))){
        if (availablecheck && stickyInvoker.isAvailable()){
            return stickyInvoker;
        }
    }

    // 调用doselect()处理选择
    Invoker<T> invoker = doselect(loadbalance, invocation, invokers, selected);
    
    if (sticky) {
        stickyInvoker = invoker;
    }

    return invoker;
}

private Invoker<T> doselect(LoadBalance loadbalance, Invocation invocation, 
            List<Invoker<T>> invokers, List<Invoker<T>> selected) throws RpcException {

    // 如果只有一个Invoker可用，则直接返回
    if (invokers.size() == 1)
        return invokers.get(0);

    // 如果只有两个invoker，退化成轮循
    if (invokers.size() == 2 && selected != null && selected.size() > 0) {
        return selected.get(0) == invokers.get(0) ? invokers.get(1) : invokers.get(0);
    }

    Invoker<T> invoker = loadbalance.select(invokers, getUrl(), invocation);
    
    // 如果 selected中包含（优先判断） 或者 不可用&&availablecheck=true 则重试.
    // selected.contains(invoker)，说明这个Invoker已经被选过了，这次又选择了它，重复了。
    // invoker.isAvailable()，说明这个Invoker不可用
    // 上面情况都需要重新选择

    if ( (selected != null && selected.contains(invoker))
            || (!invoker.isAvailable() && getUrl()!=null && availablecheck)){
        try {

            // 调用reselect()重新选择
            Invoker<T> rinvoker = reselect(loadbalance, invocation, invokers, selected, availablecheck);

            if (rinvoker != null) {
                invoker =  rinvoker;
            } else {

                // 看下第一次选的位置，如果不是最后，选+1位置.
                int index = invokers.indexOf(invoker);
                try{
                    //最后在避免碰撞
                    invoker = index < invokers.size() - 1 ? invokers.get(index + 1) : invoker;
                }catch (Exception e) {
                    logger.warn(e.getMessage()+" may because invokers list dynamic change, ignore.",e);
                }

            }
        } catch (Throwable t){
            logger.error("clustor relselect fail reason is :"+t.getMessage());
        }
    }
    return invoker;
}

/**
 * 重选，先从非selected的列表中选择，没有在从selected列表中选择.
 * @param loadbalance
 * @param invocation
 * @param invokers
 * @param selected
 * @return
 * @throws RpcException
 */
private Invoker<T> reselect(LoadBalance loadbalance,Invocation invocation,
                            List<Invoker<T>> invokers, List<Invoker<T>> selected ,boolean availablecheck)
        throws RpcException {
    
    // 预先分配一个，这个列表是一定会用到的.
    List<Invoker<T>> reselectInvokers = new ArrayList<Invoker<T>>(
            invokers.size() > 1? (invokers.size() - 1) : invokers.size());
    
    // 先从非select中选
    if ( availablecheck ) { //选isAvailable 的非select
        for (Invoker<T> invoker : invokers) {
            if (invoker.isAvailable()) {
                if (selected == null || !selected.contains(invoker)) {
                    reselectInvokers.add(invoker);
                }
            }
        }
        if (reselectInvokers.size() > 0) {
            return loadbalance.select(reselectInvokers, getUrl(), invocation);
        }
    } else { //选全部非select
        for (Invoker<T> invoker : invokers) {
            if (selected == null || !selected.contains(invoker)) {
                reselectInvokers.add(invoker);
            }
        }
        if (reselectInvokers.size() > 0) {
            return loadbalance.select(reselectInvokers, getUrl(), invocation);
        }
    }

    // 最后从select中选可用的. 
    {
        if (selected != null) {
            for (Invoker<T> invoker : selected) {
                if ((invoker.isAvailable()) //优先选available 
                        && !reselectInvokers.contains(invoker)){
                    reselectInvokers.add(invoker);
                }
            }
        }
        if(reselectInvokers.size() > 0) {
            return loadbalance.select(reselectInvokers, getUrl(), invocation);
        }
    }

    return null;
} 
{% endhighlight %}


**到此，我们从directory返回的Invoker列表中选择了一个可用的Invoker，**

**可以将传递过来的Invocation参数再传给这个被选中的Invoker进行处理，返回处理的结果。**

**整个Cluster的作用就到这里了。**

{% highlight java %}
Invoker<T> invoker = select(loadbalance, invocation, copyinvokers, invoked);
return invoker.invoke(invocation);
{% endhighlight %}