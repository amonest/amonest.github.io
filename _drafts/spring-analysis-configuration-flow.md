---
layout: post
title: Spring Analysis - @SpringBootApplication
---

### Spring Boot 应用程序模板

通常 Spring Boot 应用程序都用一个 **@SpringBootApplication** 注解进行标注。

{% highlight java %}
@SpringBootApplication
public class Application {

    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }
}
{% endhighlight %}

**@SpringBootApplication** 是一个组合注解，它组合了 **@SpringBootConfiguration**、**@EnableAutoConfiguration**、**@ComponentScan** 三个注解。

{% highlight java %}
@Target(ElementType.TYPE)
@Retention(RetentionPolicy.RUNTIME)
@Documented
@Inherited
@SpringBootConfiguration
@EnableAutoConfiguration
@ComponentScan(excludeFilters = {
        @Filter(type = FilterType.CUSTOM, classes = TypeExcludeFilter.class),
        @Filter(type = FilterType.CUSTOM, classes = AutoConfigurationExcludeFilter.class) })
public @interface SpringBootApplication { 
    ... ...
}
{% endhighlight %}

**@SpringBootConfiguration** 注解继承了 **@Configuration** 注解。

{% highlight java %}
@Target(ElementType.TYPE)
@Retention(RetentionPolicy.RUNTIME)
@Documented
@Configuration
public @interface SpringBootConfiguration {
    ... ...
}
{% endhighlight %}

---

### SpringApplication.run() - 创建ApplicationContext

应用程序入口需要调用 **SpringApplication.run()** 方法，将 **@SpringBootConfiguration** 注解标注的配置类作为参数传递给 **SpringApplication**。

{% highlight java %}
public static void main(String[] args) {
    SpringApplication.run(Application.class, args);
}
{% endhighlight %}

**run()** 方法最终的目的是返回一个 **ConfigurableApplicationContext** 类实例。

{% highlight java %}
public ConfigurableApplicationContext run(String... args) {
    SpringApplicationRunListeners listeners = getRunListeners(args);
    ApplicationArguments applicationArguments = new DefaultApplicationArguments(args);
    ConfigurableEnvironment environment = prepareEnvironment(listeners, applicationArguments);
    Banner printedBanner = printBanner(environment);

    ConfigurableApplicationContext context = createApplicationContext();
    prepareContext(context, environment, listeners, applicationArguments, printedBanner);
    refreshContext(context);
    afterRefresh(context, applicationArguments);

    return context;
}
{% endhighlight %}

**createApplicationContext()** 方法判断当前是否为WEB环境，创建不同的 **ConfigurableApplicationContext** 实例。

{% highlight java %}
public static final String DEFAULT_CONTEXT_CLASS = "org.springframework.context."
        + "annotation.AnnotationConfigApplicationContext";

public static final String DEFAULT_WEB_CONTEXT_CLASS = "org.springframework."
        + "boot.context.embedded.AnnotationConfigEmbeddedWebApplicationContext";

protected ConfigurableApplicationContext createApplicationContext() {
    Class<?> contextClass = this.applicationContextClass;
    if (contextClass == null) {
        try {
            // 通过webEnvironment判断当前是否是WEB环境
            contextClass = Class.forName(this.webEnvironment
                    ? DEFAULT_WEB_CONTEXT_CLASS : DEFAULT_CONTEXT_CLASS);
        }
        catch (ClassNotFoundException ex) {
            throw new IllegalStateException(
                    "Unable create a default ApplicationContext, "
                            + "please specify an ApplicationContextClass",
                    ex);
        }
    }
    return (ConfigurableApplicationContext) BeanUtils.instantiate(contextClass);
}
{% endhighlight %}

**prepareContext()** 方法对 **ApplicationContext** 对象做一些通用设置，然后调用 **load()** 方法。**load()** 方法的参数就是 **@SpringBootConfiguration** 注解标注的配置类。

{% highlight java %}
private void prepareContext(ConfigurableApplicationContext context,
        ConfigurableEnvironment environment, SpringApplicationRunListeners listeners,
        ApplicationArguments applicationArguments, Banner printedBanner) {
    context.setEnvironment(environment);
    postProcessApplicationContext(context);
    applyInitializers(context);

    listeners.contextPrepared(context);

    // Add boot specific singleton beans
    context.getBeanFactory().registerSingleton("springApplicationArguments",
            applicationArguments);

    if (printedBanner != null) {
        context.getBeanFactory().registerSingleton("springBootBanner", printedBanner);
    }

    // Load the sources
    Set<Object> sources = getSources();
    Assert.notEmpty(sources, "Sources must not be empty");

    // 这里的sources就是 @SpringBootConfiguration 注解标注的配置类
    load(context, sources.toArray(new Object[sources.size()]));

    listeners.contextLoaded(context);
}
{% endhighlight %}

**load()** 方法创建 **BeanDefinitionLoader** 对象，然后调用其 **load()** 方法。

{% highlight java %}
protected void load(ApplicationContext context, Object[] sources) {
    BeanDefinitionLoader loader = createBeanDefinitionLoader(
            getBeanDefinitionRegistry(context), sources);
    if (this.beanNameGenerator != null) {
        loader.setBeanNameGenerator(this.beanNameGenerator);
    }
    if (this.resourceLoader != null) {
        loader.setResourceLoader(this.resourceLoader);
    }
    if (this.environment != null) {
        loader.setEnvironment(this.environment);
    }

    loader.load();
}
{% endhighlight %}

**BeanDefinitionLoader** 从 **XML** 和 **JavaConfig** 中读取 **Bean** 定义。

{% highlight java %}
package org.springframework.boot;

class BeanDefinitionLoader {

    private final Object[] sources;

    private final AnnotatedBeanDefinitionReader annotatedReader;

    private final XmlBeanDefinitionReader xmlReader;

    private BeanDefinitionReader groovyReader;

    private final ClassPathBeanDefinitionScanner scanner;

    private ResourceLoader resourceLoader;

    BeanDefinitionLoader(BeanDefinitionRegistry registry, Object... sources) {
        Assert.notNull(registry, "Registry must not be null");
        Assert.notEmpty(sources, "Sources must not be empty");
        this.sources = sources;
        this.annotatedReader = new AnnotatedBeanDefinitionReader(registry);
        this.xmlReader = new XmlBeanDefinitionReader(registry);
        if (isGroovyPresent()) {
            this.groovyReader = new GroovyBeanDefinitionReader(registry);
        }
        this.scanner = new ClassPathBeanDefinitionScanner(registry);
        this.scanner.addExcludeFilter(new ClassExcludeFilter(sources));
    }

    public int load() {
        int count = 0;
        for (Object source : this.sources) {
            count += load(source);
        }
        return count;
    }

    private int load(Object source) {
        Assert.notNull(source, "Source must not be null");

        // 从JavaConfig配置类中读取Bean定义
        if (source instanceof Class<?>) {
            return load((Class<?>) source);
        }

        if (source instanceof Resource) {
            return load((Resource) source);
        }

        if (source instanceof Package) {
            return load((Package) source);
        }

        if (source instanceof CharSequence) {
            return load((CharSequence) source);
        }

        throw new IllegalArgumentException("Invalid source type " + source.getClass());
    }
}
{% endhighlight %}

**load(Class<?> source)** 实现从 **JavaConfig** 配置类中读取 **Bean** 定义，关键是调用 **AnnotatedGenericBeanDefinition.register()** 方法。

{% highlight java %}
private int load(Class<?> source) {
    if (isGroovyPresent()) {
        // Any GroovyLoaders added in beans{} DSL can contribute beans here
        if (GroovyBeanDefinitionSource.class.isAssignableFrom(source)) {
            GroovyBeanDefinitionSource loader = BeanUtils.instantiateClass(source,
                    GroovyBeanDefinitionSource.class);
            load(loader);
        }
    }

    // 判断是否包含@Component注解？
    if (isComponent(source)) {
        // annotatedReader 是构造器创建的 AnnotatedBeanDefinitionReader 实例
        this.annotatedReader.register(source);
        return 1;
    }

    return 0;
}

private boolean isComponent(Class<?> type) {
    // This has to be a bit of a guess. The only way to be sure that this type is
    // eligible is to make a bean definition out of it and try to instantiate it.
    if (AnnotationUtils.findAnnotation(type, Component.class) != null) {
        return true;
    }
    // Nested anonymous classes are not eligible for registration, nor are groovy
    // closures
    if (type.getName().matches(".*\\$_.*closure.*") || type.isAnonymousClass()
            || type.getConstructors() == null || type.getConstructors().length == 0) {
        return false;
    }
    return true;
}
{% endhighlight %}

**AnnotatedBeanDefinitionReader** 的 **register()** 方法：

{% highlight java %}
package org.springframework.context.annotation;

public class AnnotatedBeanDefinitionReader {

    public void register(Class<?>... annotatedClasses) {
        for (Class<?> annotatedClass : annotatedClasses) {
            registerBean(annotatedClass);
        }
    }

    public void registerBean(Class<?> annotatedClass) {
        registerBean(annotatedClass, null, (Class<? extends Annotation>[]) null);
    }

    public void registerBean(Class<?> annotatedClass, Class<? extends Annotation>... qualifiers) {
        registerBean(annotatedClass, null, qualifiers);
    }

    public void registerBean(Class<?> annotatedClass, String name, Class<? extends Annotation>... qualifiers) {
        AnnotatedGenericBeanDefinition abd = new AnnotatedGenericBeanDefinition(annotatedClass);

        if (this.conditionEvaluator.shouldSkip(abd.getMetadata())) {
            return;
        }

        ScopeMetadata scopeMetadata = this.scopeMetadataResolver.resolveScopeMetadata(abd);
        abd.setScope(scopeMetadata.getScopeName());
        String beanName = (name != null ? name : this.beanNameGenerator.generateBeanName(abd, this.registry));
        AnnotationConfigUtils.processCommonDefinitionAnnotations(abd);
        if (qualifiers != null) {
            for (Class<? extends Annotation> qualifier : qualifiers) {
                if (Primary.class == qualifier) {
                    abd.setPrimary(true);
                }
                else if (Lazy.class == qualifier) {
                    abd.setLazyInit(true);
                }
                else {
                    abd.addQualifier(new AutowireCandidateQualifier(qualifier));
                }
            }
        }

        BeanDefinitionHolder definitionHolder = new BeanDefinitionHolder(abd, beanName);
        definitionHolder = AnnotationConfigUtils.applyScopedProxyMode(scopeMetadata, definitionHolder, this.registry);
        BeanDefinitionReaderUtils.registerBeanDefinition(definitionHolder, this.registry);
    }
}
{% endhighlight %}

**AnnotatedGenericBeanDefinition** 用来表示注解标注的 **BeanDefinition**。

{% highlight java %}
package org.springframework.beans.factory.annotation;

public class AnnotatedGenericBeanDefinition extends GenericBeanDefinition implements AnnotatedBeanDefinition {

    private final AnnotationMetadata metadata;

    public AnnotatedGenericBeanDefinition(Class<?> beanClass) {
        setBeanClass(beanClass);
        this.metadata = new StandardAnnotationMetadata(beanClass, true);
    }
}
{% endhighlight %}

**StandardAnnotationMetadata** 用来表示类的 **Metadata** 信息。

{% highlight java %}
package org.springframework.core.type;

public class StandardAnnotationMetadata extends StandardClassMetadata implements AnnotationMetadata {

    private final Annotation[] annotations;

    private final boolean nestedAnnotationsAsMap;

    public StandardAnnotationMetadata(Class<?> introspectedClass) {
        this(introspectedClass, false);
    }

    public StandardAnnotationMetadata(Class<?> introspectedClass, boolean nestedAnnotationsAsMap) {
        super(introspectedClass);
        this.annotations = introspectedClass.getAnnotations();
        this.nestedAnnotationsAsMap = nestedAnnotationsAsMap;
    }
}
{% endhighlight %}

在 **AnnotatedBeanDefinitionReader** 的 **registerBean()** 方法里面，可以看到有这样一段：

{% highlight java %}
AnnotatedGenericBeanDefinition abd = new AnnotatedGenericBeanDefinition(annotatedClass);
if (this.conditionEvaluator.shouldSkip(abd.getMetadata())) {
    return;
}
{% endhighlight %}

这里调用了 **conditionEvaluator.shouldSkip()** 方法，目的是检查是否有包含 **@Conditional** 注解，执行对应的 **Condition** 检查。

{% highlight java %}
package org.springframework.context.annotation;

class ConditionEvaluator {
    
    public boolean shouldSkip(AnnotatedTypeMetadata metadata) {
        return shouldSkip(metadata, null);
    }

    /**
     * Determine if an item should be skipped based on {@code @Conditional} annotations.
     * @param metadata the meta data
     * @param phase the phase of the call
     * @return if the item should be skipped
     */
    public boolean shouldSkip(AnnotatedTypeMetadata metadata, ConfigurationPhase phase) {
        if (metadata == null || !metadata.isAnnotated(Conditional.class.getName())) {
            return false;
        }

        if (phase == null) {
            if (metadata instanceof AnnotationMetadata &&
                    ConfigurationClassUtils.isConfigurationCandidate((AnnotationMetadata) metadata)) {
                return shouldSkip(metadata, ConfigurationPhase.PARSE_CONFIGURATION);
            }
            return shouldSkip(metadata, ConfigurationPhase.REGISTER_BEAN);
        }

        List<Condition> conditions = new ArrayList<Condition>();
        for (String[] conditionClasses : getConditionClasses(metadata)) {
            for (String conditionClass : conditionClasses) {
                Condition condition = getCondition(conditionClass, this.context.getClassLoader());
                conditions.add(condition);
            }
        }

        AnnotationAwareOrderComparator.sort(conditions);

        for (Condition condition : conditions) {
            ConfigurationPhase requiredPhase = null;
            if (condition instanceof ConfigurationCondition) {
                requiredPhase = ((ConfigurationCondition) condition).getConfigurationPhase();
            }
            if (requiredPhase == null || requiredPhase == phase) {
                if (!condition.matches(this.context, metadata)) {
                    return true;
                }
            }
        }

        return false;
    }
}
{% endhighlight %}
