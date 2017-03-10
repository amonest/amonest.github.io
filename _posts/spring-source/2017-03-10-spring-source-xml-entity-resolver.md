---
layout: post
title: Spring Source - 验证XML文件
---

{% include block/spring-source-list.html %}

---

**org.xml.sax.EntityResolver** 是XML文件的验证接口。


---

**AbstractXmlApplicationContext.loadBeanDefinitions()** 方法在创建XmlBeanDefinitionReader实例时，提供了一个 **ResourceEntityResolver** 对象。

{% highlight java %}
@Override
protected void loadBeanDefinitions(DefaultListableBeanFactory beanFactory) throws BeansException, IOException {
    // Create a new XmlBeanDefinitionReader for the given BeanFactory.
    XmlBeanDefinitionReader beanDefinitionReader = new XmlBeanDefinitionReader(beanFactory);

    // Configure the bean definition reader with this context's
    // resource loading environment.
    beanDefinitionReader.setEnvironment(this.getEnvironment());
    beanDefinitionReader.setResourceLoader(this);

    // ---------------------------[ ****** ]---------------------------
    beanDefinitionReader.setEntityResolver(new ResourceEntityResolver(this)); // <<<这里<<<

    // Allow a subclass to provide custom initialization of the reader,
    // then proceed with actually loading the bean definitions.
    initBeanDefinitionReader(beanDefinitionReader);
    loadBeanDefinitions(beanDefinitionReader);
}

{% endhighlight %}


---

**ResourceEntityResolver** 继承自 **DelegatingEntityResolver**，而后者实现了 **EntityResoulver** 接口。

**DelegatingEntityResolver** 实质上是一个代理对象，内部封装了 **PluggableSchemaResolver** 和 **BeansDtdResolver** 两个实现类，根据不对的文件类型，调用不同的实现类。

对应 **.xml** 后缀文件，调用的是 **PluggableSchemaResolver** 实现类。

{% highlight java %}
public class DelegatingEntityResolver implements EntityResolver {

    public static final String DTD_SUFFIX = ".dtd";
    public static final String XSD_SUFFIX = ".xsd";

    private final EntityResolver dtdResolver;
    private final EntityResolver schemaResolver;

    public DelegatingEntityResolver(ClassLoader classLoader) {
        this.dtdResolver = new BeansDtdResolver();
        this.schemaResolver = new PluggableSchemaResolver(classLoader);
    }

    @Override
    public InputSource resolveEntity(String publicId, String systemId) throws SAXException, IOException {
        if (systemId != null) {
            if (systemId.endsWith(DTD_SUFFIX)) {
                return this.dtdResolver.resolveEntity(publicId, systemId);
            }
            else if (systemId.endsWith(XSD_SUFFIX)) {
                return this.schemaResolver.resolveEntity(publicId, systemId);
            }
        }
        return null;
    }
}
{% endhighlight %}


---

**PluggableSchemaResolver** 从 **META-INF/spring.schemas** 路径读取Schema的映射信息，作为 **EntityResolver** 接口的 **resolveEntity()** 方法返回结果。

{% highlight java %}
public class PluggableSchemaResolver implements EntityResolver {

    public static final String DEFAULT_SCHEMA_MAPPINGS_LOCATION = "META-INF/spring.schemas";

    private final ClassLoader classLoader;

    private final String schemaMappingsLocation;

    /** Stores the mapping of schema URL -> local schema path */
    private volatile Map<String, String> schemaMappings;

    public PluggableSchemaResolver(ClassLoader classLoader) {
        this.classLoader = classLoader;
        this.schemaMappingsLocation = DEFAULT_SCHEMA_MAPPINGS_LOCATION;
    }}

    @Override
    public InputSource resolveEntity(String publicId, String systemId) throws IOException {
        if (systemId != null) {
            // ---------------------------[ ****** ]---------------------------
            String resourceLocation = getSchemaMappings().get(systemId); // <<<这里<<<

            if (resourceLocation != null) {
                Resource resource = new ClassPathResource(resourceLocation, this.classLoader);
                InputSource source = new InputSource(resource.getInputStream());
                source.setPublicId(publicId);
                source.setSystemId(systemId);
                return source;
            }
        }
        return null;
    }

    private Map<String, String> getSchemaMappings() {
        if (this.schemaMappings == null) {
            synchronized (this) {
                if (this.schemaMappings == null) {

                    // ---------------------------[ ****** ]---------------------------
                    // 从schemaMappingsLocation位置读取Schema映射信息
                    // 默认位置是META-INF/spring.schemas
                    Properties mappings =
                            PropertiesLoaderUtils.loadAllProperties(this.schemaMappingsLocation, this.classLoader);

                    Map<String, String> schemaMappings = new ConcurrentHashMap<String, String>(mappings.size());
                    CollectionUtils.mergePropertiesIntoMap(mappings, schemaMappings);
                    this.schemaMappings = schemaMappings;
                }
            }
        }
        return this.schemaMappings;
    }
}
{% endhighlight %}


---

Spring 提供的 **META-INF/spring.schemas** 文件内容：

{% highlight ini %}
http\://www.springframework.org/schema/beans/spring-beans-2.0.xsd=org/springframework/beans/factory/xml/spring-beans-2.0.xsd
http\://www.springframework.org/schema/beans/spring-beans-2.5.xsd=org/springframework/beans/factory/xml/spring-beans-2.5.xsd
http\://www.springframework.org/schema/beans/spring-beans-3.0.xsd=org/springframework/beans/factory/xml/spring-beans-3.0.xsd
http\://www.springframework.org/schema/beans/spring-beans-3.1.xsd=org/springframework/beans/factory/xml/spring-beans-3.1.xsd
http\://www.springframework.org/schema/beans/spring-beans-3.2.xsd=org/springframework/beans/factory/xml/spring-beans-3.2.xsd
http\://www.springframework.org/schema/beans/spring-beans-4.0.xsd=org/springframework/beans/factory/xml/spring-beans-4.0.xsd
http\://www.springframework.org/schema/beans/spring-beans-4.1.xsd=org/springframework/beans/factory/xml/spring-beans-4.1.xsd
http\://www.springframework.org/schema/beans/spring-beans-4.2.xsd=org/springframework/beans/factory/xml/spring-beans-4.2.xsd
http\://www.springframework.org/schema/beans/spring-beans-4.3.xsd=org/springframework/beans/factory/xml/spring-beans-4.3.xsd
http\://www.springframework.org/schema/beans/spring-beans.xsd=org/springframework/beans/factory/xml/spring-beans-4.3.xsd
{% endhighlight %}
