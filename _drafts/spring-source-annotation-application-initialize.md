---
layout: post
title: Spring Source - SpringApplication初始化
---

SpringApplication初始化函数：

{% highlight java %}
private void initialize(Object[] sources) {
    if (sources != null && sources.length > 0) {
        this.sources.addAll(Arrays.asList(sources));
    }
    this.webEnvironment = deduceWebEnvironment();
    setInitializers((Collection) getSpringFactoriesInstances(
            ApplicationContextInitializer.class));
    setListeners((Collection) getSpringFactoriesInstances(ApplicationListener.class));
    this.mainApplicationClass = deduceMainApplicationClass();
}
{% endhighlight %}


---

### 第一步：设置配置对象

{% highlight java %}
//实例变量
//private final Set<Object> sources = new LinkedHashSet<Object>();

if (sources != null && sources.length > 0) {
    this.sources.addAll(Arrays.asList(sources));
}
{% endhighlight %}

实例变量sources用来保存配置对象，通常是一个配置类。


---

### 第二步：检查是否Web环境

{% highlight java %}
//实例变量
//private boolean webEnvironment;

this.webEnvironment = deduceWebEnvironment();
{% endhighlight %}

deduceWebEnvironment()通过检查Web环境必需的一些类是否存在来确定当前是否是Web环境。

{% highlight java %}
//实例变量
//private static final String[] WEB_ENVIRONMENT_CLASSES = { "javax.servlet.Servlet",
//            "org.springframework.web.context.ConfigurableWebApplicationContext" };

private boolean deduceWebEnvironment() {
    for (String className : WEB_ENVIRONMENT_CLASSES) {
        if (!ClassUtils.isPresent(className, null)) {
            return false;
        }
    }
    return true;
}
{% endhighlight %}


---

### 第三步：初始化ApplicationContextInitializer

{% highlight java %}
setInitializers((Collection) getSpringFactoriesInstances(
        ApplicationContextInitializer.class));
{% endhighlight %}





