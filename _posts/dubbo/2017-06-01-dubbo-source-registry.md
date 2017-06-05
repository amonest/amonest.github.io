---
layout: post
title: Dubbo 源码分析 - 注册中心
---

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