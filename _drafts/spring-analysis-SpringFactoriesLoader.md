---
layout: post
title: Spring Analysis - SpringFactoriesLoader
---

**SpringApplication** 使用 **META-INF/spring.factories** 作为配置文件，用来配置各种接口的实现。该文件用 **SpringFactoriesLoader** 类来操作。

{% highlight java %}
package org.springframework.core.io.support;

public abstract class SpringFactoriesLoader {

    public static final String FACTORIES_RESOURCE_LOCATION = "META-INF/spring.factories";

    public static List<String> loadFactoryNames(Class<?> factoryClass, ClassLoader classLoader) {
        String factoryClassName = factoryClass.getName();
        try {
            Enumeration<URL> urls = (classLoader != null ? classLoader.getResources(FACTORIES_RESOURCE_LOCATION) :
                    ClassLoader.getSystemResources(FACTORIES_RESOURCE_LOCATION));
            List<String> result = new ArrayList<String>();

            while (urls.hasMoreElements()) {
                URL url = urls.nextElement();
                Properties properties = PropertiesLoaderUtils.loadProperties(new UrlResource(url));

                // 用接口类名作为KEY
                String factoryClassNames = properties.getProperty(factoryClassName);

                // 多个实现类之间用逗号分割
                result.addAll(Arrays.asList(StringUtils.commaDelimitedListToStringArray(factoryClassNames)));
            }

            return result;
        }
        catch (IOException ex) {
            throw new IllegalArgumentException("Unable to load [" + factoryClass.getName() +
                    "] factories from location [" + FACTORIES_RESOURCE_LOCATION + "]", ex);
        }
    }

    public static <T> List<T> loadFactories(Class<T> factoryClass, ClassLoader classLoader) {
        Assert.notNull(factoryClass, "'factoryClass' must not be null");
        ClassLoader classLoaderToUse = classLoader;
        if (classLoaderToUse == null) {
            classLoaderToUse = SpringFactoriesLoader.class.getClassLoader();
        }

        // 获取实现类名列表
        List<String> factoryNames = loadFactoryNames(factoryClass, classLoaderToUse);
        if (logger.isTraceEnabled()) {
            logger.trace("Loaded [" + factoryClass.getName() + "] names: " + factoryNames);
        }

        // 创建实现类实例列表
        List<T> result = new ArrayList<T>(factoryNames.size());
        for (String factoryName : factoryNames) {
            result.add(instantiateFactory(factoryName, factoryClass, classLoaderToUse));
        }

        AnnotationAwareOrderComparator.sort(result);
        return result;
    }

    private static <T> T instantiateFactory(String instanceClassName, Class<T> factoryClass, ClassLoader classLoader) {
        try {
            Class<?> instanceClass = ClassUtils.forName(instanceClassName, classLoader);
            if (!factoryClass.isAssignableFrom(instanceClass)) {
                throw new IllegalArgumentException(
                        "Class [" + instanceClassName + "] is not assignable to [" + factoryClass.getName() + "]");
            }

            // 获取无参数构造器，创建类实例
            Constructor<?> constructor = instanceClass.getDeclaredConstructor();
            ReflectionUtils.makeAccessible(constructor);
            return (T) constructor.newInstance();
        }
        catch (Throwable ex) {
            throw new IllegalArgumentException("Unable to instantiate factory class: " + factoryClass.getName(), ex);
        }
    }
}
{% endhighlight %}

假设，**META-INF/spring.factories** 文件中有如下内容：

{% highlight ini %}
org.springframework.context.ApplicationContextInitializer=\
org.springframework.boot.autoconfigure.SharedMetadataReaderFactoryContextInitializer,\
org.springframework.boot.autoconfigure.logging.AutoConfigurationReportLoggingInitializer
{% endhighlight %}

就可以使用下面代码初始化 **ApplicationContextInitializer** 实例列表：

{% highlight java %}
List<ApplicationContextInitializer> initializers = 
    SpringFactoriesLoader.loadFactories(ApplicationContextInitializer.class, null);
{% endhighlight %}
