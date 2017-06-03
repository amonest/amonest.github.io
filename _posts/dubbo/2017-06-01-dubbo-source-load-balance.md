---
layout: post
title: Dubbo 源码分析 - 负载均衡
---

LoadBalance是负载均衡接口，它以Invoker列表作为参数，根据不同的策略，返回一个Invoker。

{% highlight java %}
@SPI(RandomLoadBalance.NAME)
public interface LoadBalance {
    <T> Invoker<T> select(List<Invoker<T>> invokers, 
            URL url, Invocation invocation) throws RpcException;
}
{% endhighlight %}


默认的LoadBalance是RoundRobinLoadBalance，它采用轮询策略。

{% highlight java %}
public class RoundRobinLoadBalance extends AbstractLoadBalance {

    protected <T> Invoker<T> doSelect(List<Invoker<T>> invokers, URL url, Invocation invocation) {
        String key = invokers.get(0).getUrl().getServiceKey() + "." + invocation.getMethodName();
        int length = invokers.size(); // 总个数
        int maxWeight = 0; // 最大权重
        int minWeight = Integer.MAX_VALUE; // 最小权重
        final LinkedHashMap<Invoker<T>, IntegerWrapper> invokerToWeightMap = new LinkedHashMap<Invoker<T>, IntegerWrapper>();
        int weightSum = 0;

        for (int i = 0; i < length; i++) {
            int weight = getWeight(invokers.get(i), invocation);
            maxWeight = Math.max(maxWeight, weight); // 累计最大权重
            minWeight = Math.min(minWeight, weight); // 累计最小权重
            if (weight > 0) {
                invokerToWeightMap.put(invokers.get(i), new IntegerWrapper(weight));
                weightSum += weight;
            }
        }

        AtomicPositiveInteger sequence = sequences.get(key);
        if (sequence == null) {
            sequences.putIfAbsent(key, new AtomicPositiveInteger());
            sequence = sequences.get(key);
        }

        int currentSequence = sequence.getAndIncrement();

        if (maxWeight > 0 && minWeight < maxWeight) { // 权重不一样
            int mod = currentSequence % weightSum;

            for (int i = 0; i < maxWeight; i++) {
                for (Map.Entry<Invoker<T>, IntegerWrapper> each : invokerToWeightMap.entrySet()) {
                    final Invoker<T> k = each.getKey();
                    final IntegerWrapper v = each.getValue();
                    if (mod == 0 && v.getValue() > 0) {
                        return k;
                    }
                    if (v.getValue() > 0) {
                        v.decrement();
                        mod--;
                    }
                }
            }
        }

        // 取模轮循
        return invokers.get(currentSequence % length);
    }
}
{% endhighlight %}


这里的轮询算法说实话，看得不是很明白。

后面附一个关于算法的链接，供参考：

+ [《几种简单的负载均衡算法及其Java代码实现》](http://www.cnblogs.com/szlbm/p/5588555.html)

+ [《负载均衡加权轮询算法RoundRobin》](http://www.oschina.net/code/snippet_593721_27586)

+ [《一致性哈希算法与Java实现》](http://www.blogjava.net/hello-yun/archive/2012/10/10/389289.html)

