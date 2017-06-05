---
layout: post
title: Dubbo 源码分析 - 配置规则
---

Configurator的作用是根据配置中心的设置，重置地址信息。

{% highlight java %}
public interface Configurator extends Comparable<Configurator> {
    URL getUrl();
    URL configure(URL url);

}
{% endhighlight %}


目前Configurator接口有两个实现类：OverrideConfigurator和AbsentConfigurator。例如，OverrideConfigurator是这样处理的：

{% highlight java %}
public class OverrideConfigurator extends AbstractConfigurator {    
    public OverrideConfigurator(URL url) {
        super(url);
    }

    // configuUrl=配置地址，例如：
    //      override://0.0.0.0:2145/
    //      override://192.168.12.30:2145/
    // currentUrl=需要重置的地址，例如，在RegistryDirectory被调用，
    //   传入的是注册中心地址overrideDirectoryUrl：zookeeper://1921.18.12.84:2181/   

    public URL doConfigure(URL currentUrl, URL configUrl) {
        return currentUrl.addParameters(configUrl.getParameters());
    }
}
{% endhighlight %}


配置规则有匹配条件。例如：

* override://0.0.0.0:2145/ 这个规则全局有效，所有提供者都适用

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


Route的使用主要是RegistryDirectory中，依据注册中心的变更信息，创建Configurator对象。

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

