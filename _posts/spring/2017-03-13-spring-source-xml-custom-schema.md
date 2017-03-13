---
layout: post
title: Spring Source - 自定义XML Schema
---

{% include block/spring-source-list.html %}


---

参考：[自定义XML Schema](/2017/03/13/spring-config-custom-xml-schema)


---

**AbstractXmlApplicationContext.loadBeanDefinitions()** 方法创建了一个 **XmlBeanDefinitionReader** 实例。

{% highlight java %}
@Override
protected void loadBeanDefinitions(DefaultListableBeanFactory beanFactory) throws BeansException, IOException {
    // Create a new XmlBeanDefinitionReader for the given BeanFactory.
    XmlBeanDefinitionReader beanDefinitionReader = new XmlBeanDefinitionReader(beanFactory);

    // Configure the bean definition reader with this context's
    // resource loading environment.
    beanDefinitionReader.setEnvironment(this.getEnvironment());
    beanDefinitionReader.setResourceLoader(this);
    beanDefinitionReader.setEntityResolver(new ResourceEntityResolver(this));

    // Allow a subclass to provide custom initialization of the reader,
    // then proceed with actually loading the bean definitions.
    initBeanDefinitionReader(beanDefinitionReader);
    loadBeanDefinitions(beanDefinitionReader);
}

{% endhighlight %}



---

**XmlBeanDefinitionReader** 有一个 **NamespaceHandlerResolver** 属性，**DefaultNamespaceHandlerResolver** 是其默认实现。

{% highlight java %}
public class XmlBeanDefinitionReader extends AbstractBeanDefinitionReader {
    public NamespaceHandlerResolver getNamespaceHandlerResolver() {
        if (this.namespaceHandlerResolver == null) {
            this.namespaceHandlerResolver = createDefaultNamespaceHandlerResolver();
        }
        return this.namespaceHandlerResolver;
    }

    protected NamespaceHandlerResolver createDefaultNamespaceHandlerResolver() {
        return new DefaultNamespaceHandlerResolver(getResourceLoader().getClassLoader());
    }
}
{% endhighlight %}



---

**NamespaceHandlerResolver** 的目的是提供一个 **NamespaceHandler** 注册表功能，key是XML namespaceURI。

**DefaultNamespaceHandlerResolver** 实现从 **META-INF/spring.handlers** 读取这个注册表。

{% highlight java %}
public class DefaultNamespaceHandlerResolver implements NamespaceHandlerResolver {

    public static final String DEFAULT_HANDLER_MAPPINGS_LOCATION = "META-INF/spring.handlers";

    @Override
    public NamespaceHandler resolve(String namespaceUri) {
        Map<String, Object> handlerMappings = getHandlerMappings();
        Object handlerOrClassName = handlerMappings.get(namespaceUri);
        if (handlerOrClassName == null) {
            return null;
        }
        else if (handlerOrClassName instanceof NamespaceHandler) {
            return (NamespaceHandler) handlerOrClassName;
        }
        else {
            String className = (String) handlerOrClassName;
            Class<?> handlerClass = ClassUtils.forName(className, this.classLoader);
            if (!NamespaceHandler.class.isAssignableFrom(handlerClass)) {
                throw new FatalBeanException("Class [" + className + "] for namespace [" + namespaceUri +
                        "] does not implement the [" + NamespaceHandler.class.getName() + "] interface");
            }
            NamespaceHandler namespaceHandler = (NamespaceHandler) BeanUtils.instantiateClass(handlerClass);
            namespaceHandler.init();
            handlerMappings.put(namespaceUri, namespaceHandler);
            return namespaceHandler;
        }
    }

    private Map<String, Object> getHandlerMappings() {
        if (this.handlerMappings == null) {
            synchronized (this) {
                if (this.handlerMappings == null) {
                    Properties mappings =
                            PropertiesLoaderUtils.loadAllProperties(this.handlerMappingsLocation, this.classLoader);
                    Map<String, Object> handlerMappings = new ConcurrentHashMap<String, Object>(mappings.size());
                    CollectionUtils.mergePropertiesIntoMap(mappings, handlerMappings);
                    this.handlerMappings = handlerMappings;
                }
            }
        }
        return this.handlerMappings;
    }
}
{% endhighlight %}



---

**DefaultBeanDefinitionDocumentReader.parseBeanDefinitions()** 在解析自定义XML节点时，会调用 **BeanDefinitionParserDelegate.parseCustomElement()**。

{% highlight java %}
public class DefaultBeanDefinitionDocumentReader implements BeanDefinitionDocumentReader {
    protected void parseBeanDefinitions(Element root, BeanDefinitionParserDelegate delegate) {
        if (delegate.isDefaultNamespace(root)) {
            NodeList nl = root.getChildNodes();
            for (int i = 0; i < nl.getLength(); i++) {
                Node node = nl.item(i);
                if (node instanceof Element) {
                    Element ele = (Element) node;
                    if (delegate.isDefaultNamespace(ele)) {
                        parseDefaultElement(ele, delegate);
                    }
                    else {
                        delegate.parseCustomElement(ele); // <<<这里<<<
                    }
                }
            }
        }
        else {
            delegate.parseCustomElement(root);
        }
    }
}
{% endhighlight %}


---

**BeanDefinitionParserDelegate.parseCustomElement()** 依据XML namespace，调用 **NamespaceHandlerResolver.resolve()**，获取该namespace对应的 **NamespaceHandler**。


{% highlight java %}
public class BeanDefinitionParserDelegate {
    public BeanDefinition parseCustomElement(Element ele, BeanDefinition containingBd) {
        String namespaceUri = getNamespaceURI(ele);
        NamespaceHandler handler = this.readerContext.getNamespaceHandlerResolver().resolve(namespaceUri); // <<<这里<<<
        if (handler == null) {
            error("Unable to locate Spring NamespaceHandler for XML schema namespace [" + namespaceUri + "]", ele);
            return null;
        }
        return handler.parse(ele, new ParserContext(this.readerContext, this, containingBd));
    }
}
{% endhighlight %}


---

**NamespaceHandler** 也是提供一个 **BeanDefinitionParser** 注册表功能，key是element name。

**NamespaceHandlerSupport** 是实现 **NamespaceHandler** 接口的一个虚拟类，实际应用时多继承该类。例如：

{% highlight java %}
public class OrganizationNamespaceHandler extends NamespaceHandlerSupport {
    public void init() {
        registerBeanDefinitionParser("company", new CompanyBeanDefinitionParser());
        registerBeanDefinitionParser("employee", new EmployeeBeanDefinitionParser());
        registerBeanDefinitionParser("helloBean", new HelloBeanDefinitionParser());
    }
}
{% endhighlight %}



---

**BeanDefinitionParser** 是最终的 **XML element** 解析类，实际应用时可以继承 **AbstractSingleBeanDefinitionParser**。例如：

{% highlight java %}
public class HelloBeanDefinitionParser extends AbstractSingleBeanDefinitionParser {

    protected Class<?> getBeanClass(Element element) {
        return HelloBean.class;
    }

    protected void doParse(Element element, BeanDefinitionBuilder bean) {
        String message = element.getAttribute("message");

        if (StringUtils.hasText(message)) {
            bean.addPropertyValue("message", message);
        }
    }
}
{% endhighlight %}