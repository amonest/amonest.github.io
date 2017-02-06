---
layout: post
title: Spring Analysis - SpringApplicationRunListener
---

**SpringApplication** 启动时，执行 **run()** 方法，创建 **SpringApplicationRunListeners** 对象。

{% highlight java %}
public class SpringApplication {
    public ConfigurableApplicationContext run(String... args) {
        SpringApplicationRunListeners listeners = getRunListeners(args);
        listeners.starting();
        ... ...
    }
}
{% endhighlight %}

**SpringApplicationRunListeners** 用来管理 **SpringApplicationRunListener** 接口。

{% highlight java %}
package org.springframework.boot;

class SpringApplicationRunListeners {

    private final Log log;

    private final List<SpringApplicationRunListener> listeners;

    SpringApplicationRunListeners(Log log,
            Collection<? extends SpringApplicationRunListener> listeners) {
        this.log = log;
        this.listeners = new ArrayList<SpringApplicationRunListener>(listeners);
    }

    public void starting() {
        for (SpringApplicationRunListener listener : this.listeners) {
            listener.starting();
        }
    }

    public void environmentPrepared(ConfigurableEnvironment environment) {
        for (SpringApplicationRunListener listener : this.listeners) {
            listener.environmentPrepared(environment);
        }
    }

    public void contextPrepared(ConfigurableApplicationContext context) {
        for (SpringApplicationRunListener listener : this.listeners) {
            listener.contextPrepared(context);
        }
    }

    public void contextLoaded(ConfigurableApplicationContext context) {
        for (SpringApplicationRunListener listener : this.listeners) {
            listener.contextLoaded(context);
        }
    }

    public void finished(ConfigurableApplicationContext context, Throwable exception) {
        for (SpringApplicationRunListener listener : this.listeners) {
            callFinishedListener(listener, context, exception);
        }
    }

    private void callFinishedListener(SpringApplicationRunListener listener,
            ConfigurableApplicationContext context, Throwable exception) {
        try {
            listener.finished(context, exception);
        }
        catch (Throwable ex) {
            if (exception == null) {
                ReflectionUtils.rethrowRuntimeException(ex);
            }
            if (this.log.isDebugEnabled()) {
                this.log.error("Error handling failed", ex);
            }
            else {
                String message = ex.getMessage();
                message = (message == null ? "no error message" : message);
                this.log.warn("Error handling failed (" + message + ")");
            }
        }
    }
}
{% endhighlight %}

**SpringApplicationRunListener** 接口用来监听 **SpringApplication** 启动过程。

{% highlight java %}
package org.springframework.boot;

/**
 * Listener for the {@link SpringApplication} {@code run} method.
 * {@link SpringApplicationRunListener}s are loaded via the {@link SpringFactoriesLoader}
 * and should declare a public constructor that accepts a {@link SpringApplication}
 * instance and a {@code String[]} of arguments. A new
 * {@link SpringApplicationRunListener} instance will be created for each run.
 *
 * @author Phillip Webb
 * @author Dave Syer
 */
public interface SpringApplicationRunListener {

    void starting();

    void environmentPrepared(ConfigurableEnvironment environment);

    void contextPrepared(ConfigurableApplicationContext context);

    void contextLoaded(ConfigurableApplicationContext context);

    void finished(ConfigurableApplicationContext context, Throwable exception);
}
{% endhighlight %}

**SpringApplicationRunListener** 必须定义一个构造器，包含两个参数：第一个参数是 **SpringApplication**，第二个参数是 **String[] args**。

为什么必需这样的构造器？这是因为 **SpringApplication** 调用 **getSpringFactoriesInstances()** 返回 **SpringApplicationRunListener** 限定了。

{% highlight java %}
public class SpringApplication {

    private SpringApplicationRunListeners getRunListeners(String[] args) {
        // 构造器参数类型数组
        Class<?>[] types = new Class<?>[] { SpringApplication.class, String[].class };

        return new SpringApplicationRunListeners(logger, 
                // this 是第一个参数，args 是第二个参数，与 types 需要类型对应
                getSpringFactoriesInstances(SpringApplicationRunListener.class, types, this, args));
    }

    private <T> Collection<? extends T> getSpringFactoriesInstances(Class<T> type) {
        return getSpringFactoriesInstances(type, new Class<?>[] {});
    }

    private <T> Collection<? extends T> getSpringFactoriesInstances(Class<T> type,
            Class<?>[] parameterTypes, Object... args) {
        ClassLoader classLoader = Thread.currentThread().getContextClassLoader();

        // Use names and ensure unique to protect against duplicates
        Set<String> names = new LinkedHashSet<String>(
                SpringFactoriesLoader.loadFactoryNames(type, classLoader));

        List<T> instances = createSpringFactoriesInstances(type, parameterTypes,
                classLoader, args, names);

        AnnotationAwareOrderComparator.sort(instances);
        return instances;
    }

    @SuppressWarnings("unchecked")
    private <T> List<T> createSpringFactoriesInstances(Class<T> type,
            Class<?>[] parameterTypes, ClassLoader classLoader, Object[] args,
            Set<String> names) {
        List<T> instances = new ArrayList<T>(names.size());
        for (String name : names) {
            try {
                Class<?> instanceClass = ClassUtils.forName(name, classLoader);
                Assert.isAssignable(type, instanceClass);
                Constructor<?> constructor = instanceClass
                        .getDeclaredConstructor(parameterTypes);
                T instance = (T) BeanUtils.instantiateClass(constructor, args);
                instances.add(instance);
            }
            catch (Throwable ex) {
                throw new IllegalArgumentException(
                        "Cannot instantiate " + type + " : " + name, ex);
            }
        }
        return instances;
    }
}
{% endhighlight %}