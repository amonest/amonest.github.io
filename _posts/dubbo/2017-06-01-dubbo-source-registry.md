---
layout: post
title: Dubbo 源码分析 - 注册中心
---

Registry注册中心是一个接口，提供注册和订阅两种功能。ZookeeperRegistry就是该接口的一个实现类，提供Zookeeper注册中心功能。


{% highlight java %}
public interface Registry {

    void register(URL url);
    void unregister(URL url);

    void subscribe(URL url, NotifyListener listener);
    void unsubscribe(URL url, NotifyListener listener);
}
{% endhighlight %}


---

### Register 注册

注册功能实际是由doRegister()方法完成的。

{% highlight java %}
protected void doRegister(URL url) {
    zkClient.create(toUrlPath(url), url.getParameter(Constants.DYNAMIC_KEY, true));
}
{% endhighlight %}

这里注意的是toUrlPath()。doRegister()传入的参数是提供者URL，类似这样：

{% highlight java %}
dubbo://192.168.12.84:8199/net.mingyang.simple_dubbo_server.HelloService?id=0&proxy=jdk&server=netty
{% endhighlight %}

toUrlPath()目的是要将Url转换成Zk的路径格式。

{% highlight java %}
private String toUrlPath(URL url) {
    return "/dubbo" 
        + Constants.PATH_SEPARATOR + url.getServiceInterface()
        + Constants.PATH_SEPARATOR + url.getParameter(Constants.CATEGORY_KEY, "providers")
        + Constants.PATH_SEPARATOR + URL.encode(url.toFullString());
}
{% endhighlight %}




---

### Subscribe 订阅

{% highlight java %}
public void subscribe(URL url, NotifyListener listener) {
    //url=consumer://192.168.12.84/net.mingyang.simple_dubbo_server.HelloService
    //        ?category=providers,configurators,routers

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

### Recover 恢复

所谓恢复功能，是指当注册中心连接断开后，再重新连接成功，这时候需要恢复登记的注册和订阅。

此功能在AbstractRegister实现。

首先，在register()和subscribe()调用时，需要将登记的注册和订阅记录下来。

{% highlight java %}
public void register(URL url) {
    registered.add(url);
}

public void subscribe(URL url, NotifyListener listener) {
    Set<NotifyListener> listeners = subscribed.get(url);
    if (listeners == null) {
        subscribed.putIfAbsent(url, new ConcurrentHashSet<NotifyListener>());
        listeners = subscribed.get(url);
    }
    listeners.add(listener);
}
{% endhighlight %}


然后，定义了一个recover()方法，恢复登记的注册和订阅，供在重连成功时调用。

{% highlight java %}
protected void recover() throws Exception {
    // register
    Set<URL> recoverRegistered = new HashSet<URL>(getRegistered());
    if (! recoverRegistered.isEmpty()) {
        for (URL url : recoverRegistered) {
            register(url);
        }
    }

    // subscribe
    Map<URL, Set<NotifyListener>> recoverSubscribed = 
                new HashMap<URL, Set<NotifyListener>>(getSubscribed());
    if (! recoverSubscribed.isEmpty()) {
        for (Map.Entry<URL, Set<NotifyListener>> entry : recoverSubscribed.entrySet()) {
            URL url = entry.getKey();
            for (NotifyListener listener : entry.getValue()) {
                subscribe(url, listener);
            }
        }
    }
}
{% endhighlight %}


最后，需要调用recover()方法，这是通过添加ZookeeperRegister的StateListener实现的。

{% highlight java %}
public ZookeeperRegistry(URL url, ZookeeperTransporter zookeeperTransporter) {
    ... ...
    zkClient = zookeeperTransporter.connect(url);
    zkClient.addStateListener(new StateListener() {
        public void stateChanged(int state) {
            if (state == RECONNECTED) {
                try {
                    recover();
                } catch (Exception e) {
                    logger.error(e.getMessage(), e);
                }
            }
        }
    });
}
{% endhighlight %}


---

### Failback 容错

所谓容错，是指当注册或订阅失败时，可以定时重试，直到成功位置。

此功能在FailbackRegister实现。

首先，当注册或订阅失败时，需要记录本次操作。以注册为例：

{% highlight java %}
public void register(URL url) {
    failedRegistered.remove(url);
    failedUnregistered.remove(url);

    try {
        doRegister(url);
    } catch (Exception e) {        

        // 将失败的注册请求记录到失败列表，定时重试
        failedRegistered.add(url);

    }
}
{% endhighlight %}


然后，定义一个retry()方法，重试失败列表。

{% highlight java %}
protected void retry() {
    if (! failedRegistered.isEmpty()) {
        Set<URL> failed = new HashSet<URL>(failedRegistered);
        if (failed.size() > 0) {
            try {
                for (URL url : failed) {
                    try {
                        doRegister(url);
                        failedRegistered.remove(url);
                    } catch (Throwable t) { 
                        // 忽略所有异常，等待下次重试
                    }
                }
            } catch (Throwable t) { 
                // 忽略所有异常，等待下次重试
            }
        }
    }

    if(! failedUnregistered.isEmpty()) {
        Set<URL> failed = new HashSet<URL>(failedUnregistered);
        if (failed.size() > 0) {
            try {
                for (URL url : failed) {
                    try {
                        doUnregister(url);
                        failedUnregistered.remove(url);
                    } catch (Throwable t) { 
                        // 忽略所有异常，等待下次重试
                    }
                }
            } catch (Throwable t) { 
                // 忽略所有异常，等待下次重试
            }
        }
    }

    ... ...
}
{% endhighlight %}


最后，启动一个线程，定时重试。

{% highlight java %}
public FailbackRegistry(URL url) {
    int retryPeriod = url.getParameter(Constants.REGISTRY_RETRY_PERIOD_KEY, 
                        Constants.DEFAULT_REGISTRY_RETRY_PERIOD);
    this.retryFuture = retryExecutor.scheduleWithFixedDelay(new Runnable() {
        public void run() {
            try {
                retry();
            } catch (Throwable t) {
                logger.error("Unexpected error occur at failed retry, cause: " + t.getMessage(), t);
            }
        }
    }, retryPeriod, retryPeriod, TimeUnit.MILLISECONDS);
}
{% endhighlight %}
