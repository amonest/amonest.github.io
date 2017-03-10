---
layout: post
title: Spring Source - 解析XML配置
---

{% include block/spring-source-list.html %}

---

**ClassPathXmlApplicationContext** 使用方法： 

{% highlight java %}
public class Application {

    public static void main(String[] args) {
        ApplicationContext ctx = new ClassPathXmlApplicationContext("beanFactoryTest.xml");
        MyTestBean bean = ctx.getBean(MyTestBean.class);
        System.out.println(bean.getTestStr());
    }
}
{% endhighlight %}


---

**ClassPathXmlApplicationContext** 继承关系：

{% highlight shell %}
AbstractApplicationContext
    AbstractRefreshableApplicationContext
        AbstractRefreshableConfigApplicationContext
            AbstractXmlApplicationContext        
                ClassPathXmlApplicationContext
{% endhighlight %}


---

调用关系说明：

{% highlight java %}
ClassPathXmlApplicationContext {
    void refresh() {
        void obtainFreshBeanFactory() {
            void refreshBeanFactory() {
                void loadBeanDefinitions(DefaultListableBeanFactory beanFactory) {
                    XmlBeanDefinitionReader beanDefinitionReader = new XmlBeanDefinitionReader(beanFactory);
                    void initBeanDefinitionReader(beanDefinitionReader);
                    void loadBeanDefinitions(beanDefinitionReader) {
                        // 转移到XmlBeanDefinitionReader去处理
                        beanDefinitionReader.loadBeanDefinitions(getConfigLocations());
                    }   
                }
            }
        }
    }
}

XmlBeanDefinitionReader {                            
    int loadBeanDefinitions(String... locations) {
        int loadBeanDefinitions(String location) {
            int loadBeanDefinitions(String location, Set<Resource> actualResources) {
                int loadBeanDefinitions(Resource... resources) {
                    int loadBeanDefinitions(Resource resource) {
                        int loadBeanDefinitions(EncodedResource encodedResource) {
                            int doLoadBeanDefinitions(InputSource inputSource, Resource resource) {
                                int registerBeanDefinitions(Document doc, Resource resource) {
                                    BeanDefinitionDocumentReader documentReader = new DefaultBeanDefinitionDocumentReader();
                                    // 转移到DefaultBeanDefinitionDocumentReader去处理
                                    documentReader.registerBeanDefinitions(doc, createReaderContext(resource));
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

DefaultBeanDefinitionDocumentReader {
    void registerBeanDefinitions(Document doc, XmlReaderContext readerContext) {
        Element root = doc.getDocumentElement();
        void doRegisterBeanDefinitions(Element root) {
            BeanDefinitionParserDelegate delegate = new BeanDefinitionParserDelegate();
            void parseBeanDefinitions(Element root, BeanDefinitionParserDelegate delegate) {
                foreach (Element ele in root.getChildNodes()) {
                    if (delegate.isDefaultNamespace(ele)) {
                        void parseDefaultElement(Element ele, BeanDefinitionParserDelegate delegate) {
                            if (delegate.nodeNameEquals(ele, IMPORT_ELEMENT)) {
                                void importBeanDefinitionResource(Element ele) {
                                    String location = ele.getAttribute(RESOURCE_ATTRIBUTE);
                                    getReaderContext().getReader().loadBeanDefinitions(location, actualResources);
                                }
                            }
                            else if (delegate.nodeNameEquals(ele, ALIAS_ELEMENT)) {
                                void processAliasRegistration(Element ele) {
                                    String name = ele.getAttribute(NAME_ATTRIBUTE);
                                    String alias = ele.getAttribute(ALIAS_ATTRIBUTE);
                                    getReaderContext().getRegistry().registerAlias(name, alias);
                                }
                            }
                            else if (delegate.nodeNameEquals(ele, BEAN_ELEMENT)) {
                                void processBeanDefinition(Element ele, BeanDefinitionParserDelegate delegate) {
                                    // 转到BeanDefinitionParserDelegate，返回BeanDefinitionHolder，然后注册
                                    BeanDefinitionHolder bdHolder = delegate.parseBeanDefinitionElement(ele);
                                    BeanDefinitionReaderUtils.registerBeanDefinition(bdHolder, getReaderContext().getRegistry());
                                }
                            }
                            else if (delegate.nodeNameEquals(ele, NESTED_BEANS_ELEMENT)) {
                                doRegisterBeanDefinitions(ele);
                            }
                        }
                    }
                    else {
                        delegate.parseCustomElement(ele);
                    }
                }
            }
        }
    }
}

BeanDefinitionParserDelegate {
    BeanDefinitionHolder parseBeanDefinitionElement(Element ele) {
        BeanDefinition containingBean = null;
        BeanDefinitionHolder parseBeanDefinitionElement(Element ele, BeanDefinition containingBean) {
            string beanName = ele.getAttribute(ID_ATTRIBUTE); // 读取beanName，这里为了说明简写了
            AbstractBeanDefinition beanDefinition = parseBeanDefinitionElement(ele, beanName, containingBean) {
                AbstractBeanDefinition bd = new GenericBeanDefinition();
                parseBeanDefinitionAttributes(ele, beanName, containingBean, bd);
                parseMetaElements(ele, bd);
                parseLookupOverrideSubElements(ele, bd.getMethodOverrides());
                parseReplacedMethodSubElements(ele, bd.getMethodOverrides());
                parseConstructorArgElements(ele, bd);
                parsePropertyElements(ele, bd);
                parseQualifierElements(ele, bd);
                return bd;
            }
            return new BeanDefinitionHolder(beanDefinition, beanName, aliasesArray);
        }
    }
}
{% endhighlight %}


---

**ClassPathXmlApplicationContext** 构造器通过 **refresh()** 调用 **loadBeanDefinitions(BeanFactory)**。

{% highlight java %}
public class ClassPathXmlApplicationContext {

    public ClassPathXmlApplicationContext(String configLocation) throws BeansException {
        this(new String[] {configLocation}, true, null);
    }

    public ClassPathXmlApplicationContext(String[] configLocations, boolean refresh, ApplicationContext parent)
            throws BeansException {
        super(parent);
        setConfigLocations(configLocations);

        // ---------------------------[ STEP 1 ]---------------------------
        // 注意这里，调用了refresh()。
        // refresh()在AbstractApplicationContext中定义。
        if (refresh) {
            refresh(); // <<<这里<<<
        }
    }

    @Override
    [AbstractApplicationContext]
    public void refresh() throws BeansException, IllegalStateException {
        prepareRefresh();

        // ---------------------------[ STEP 2 ]---------------------------
        // 调用obtainFreshBeanFactory()，刷新内部的BeanFactory实例。
        ConfigurableListableBeanFactory beanFactory = obtainFreshBeanFactory(); // <<<这里<<<

        ... ...
    }

    [AbstractApplicationContext]
    protected ConfigurableListableBeanFactory obtainFreshBeanFactory() {
        // ---------------------------[ STEP 3 ]---------------------------
        // refreshBeanFactory()是AbstractApplicationContext的一个虚拟方法，
        refreshBeanFactory(); // <<<这里<<<

        ConfigurableListableBeanFactory beanFactory = getBeanFactory();
        return beanFactory;
    }

    @Override
    [AbstractRefreshableApplicationContext]
    protected final void refreshBeanFactory() throws BeansException {
        if (hasBeanFactory()) {
            destroyBeans();
            closeBeanFactory();
        }
        DefaultListableBeanFactory beanFactory = createBeanFactory();
        beanFactory.setSerializationId(getId());
        customizeBeanFactory(beanFactory);

        // ---------------------------[ STEP 4 ]---------------------------
        // 调用loadBeanDefinitions()，装入BeanDefinitions。
        loadBeanDefinitions(beanFactory); // <<<这里<<<
        this.beanFactory = beanFactory;
    }

    @Override
    [AbstractXmlApplicationContext]
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

        // ---------------------------[ STEP 5 ]---------------------------
        loadBeanDefinitions(beanDefinitionReader); // <<<这里<<<
    }

    [AbstractXmlApplicationContext]
    protected void loadBeanDefinitions(XmlBeanDefinitionReader reader) throws BeansException, IOException {
        Resource[] configResources = getConfigResources();
        if (configResources != null) {
            reader.loadBeanDefinitions(configResources);
        }

        String[] configLocations = getConfigLocations();
        if (configLocations != null) {
            // 交给XmlBeanDefinitionReader去处理
            reader.loadBeanDefinitions(configLocations); // <<<这里<<<
        }
    }
}
{% endhighlight %}


---

**loadBeanDefinitions(XmlBeanDefinitionReader)** 将控制权交给 **XmlBeanDefinitionReader**。

**XmlBeanDefinitionReader** 定义了一系列的 **loadBeanDefinitions()** 方法，使用 **location** 或 **resource** 作为参数。

{% highlight java %}
public class XmlBeanDefinitionReader 
    extends AbstractBeanDefinitionReader 
    implements BeanDefinitionReader {

    @Override
    // BeanDefinitionReader接口方法，XmlBeanDefinitionReader实现
    public int loadBeanDefinitions(Resource resource) throws BeanDefinitionStoreException {
        return loadBeanDefinitions(new EncodedResource(resource));
    }

    @Override
    // BeanDefinitionReader接口方法，AbstractBeanDefinitionReader实现
    public int loadBeanDefinitions(Resource... resources) throws BeanDefinitionStoreException {
        int counter = 0;
        for (Resource resource : resources) {
            counter += loadBeanDefinitions(resource);
        }
        return counter;
    }

    @Override
    // BeanDefinitionReader接口方法，AbstractBeanDefinitionReader实现
    public int loadBeanDefinitions(String location) throws BeanDefinitionStoreException {
        return loadBeanDefinitions(location, null);
    }

    @Override
    // BeanDefinitionReader接口方法，AbstractBeanDefinitionReader实现
    public int loadBeanDefinitions(String... locations) throws BeanDefinitionStoreException {
        int counter = 0;
        for (String location : locations) {
            counter += loadBeanDefinitions(location);
        }
        return counter;
    }

    // ---------------------------[ ****** ]---------------------------
    // 所有的loadBeanDefintions()都会交给doLoadBeanDefinitions()来处理
    // XmlBeanDefinitionReader
    protected int doLoadBeanDefinitions(InputSource inputSource, Resource resource) {
        Document doc = doLoadDocument(inputSource, resource);
        return registerBeanDefinitions(doc, resource); // <<<这里<<<
    }

    // XmlBeanDefinitionReader
    public int registerBeanDefinitions(Document doc, Resource resource) throws BeanDefinitionStoreException {
        BeanDefinitionDocumentReader documentReader = createBeanDefinitionDocumentReader(); // <<<这里<<<
        int countBefore = getRegistry().getBeanDefinitionCount();

        // -----------------------[ ****** ]---------------------------
        // 将控制权交给BeanDefinitionDocumentReader
        documentReader.registerBeanDefinitions(doc, createReaderContext(resource)); // <<<这里<<<
        return getRegistry().getBeanDefinitionCount() - countBefore;
    }
}
{% endhighlight %}


---

**XmlBeanDefinitionReader.registerBeanDefinitions(Document, Resource)** 将控制权再交给 **BeanDefinitionDocumentReader**。

**BeanDefinitionDocumentReader** 是一个接口，这里的实例是 **DefaultBeanDefinitionDocumentReader** 类型。

{% highlight java %}
public class DefaultBeanDefinitionDocumentReader implements BeanDefinitionDocumentReader {
    
    @Override
    // BeanDefinitionDocumentReader接口方法
    // XmlBeanDefinitionReader将控制权转过来后，这里是入口。
    public void registerBeanDefinitions(Document doc, XmlReaderContext readerContext) {
        this.readerContext = readerContext;
        Element root = doc.getDocumentElement();

        // ---------------------------[ STEP 1 ]---------------------------
        doRegisterBeanDefinitions(root); // <<<这里<<<
    }

    protected void doRegisterBeanDefinitions(Element root) {
        // Any nested <beans> elements will cause recursion in this method. In
        // order to propagate and preserve <beans> default-* attributes correctly,
        // keep track of the current (parent) delegate, which may be null. Create
        // the new (child) delegate with a reference to the parent for fallback purposes,
        // then ultimately reset this.delegate back to its original (parent) reference.
        // this behavior emulates a stack of delegates without actually necessitating one.
        BeanDefinitionParserDelegate parent = this.delegate;
        this.delegate = createDelegate(getReaderContext(), root, parent);

        // 这里的root参数可以理解为<beans>元素

        // 检查<beans>元素是否包含profile属性，然后和当前环境做匹配。
        // 如果匹配失败，则不处理此XML文件
        if (this.delegate.isDefaultNamespace(root)) {
            String profileSpec = root.getAttribute(PROFILE_ATTRIBUTE);
            if (StringUtils.hasText(profileSpec)) {
                String[] specifiedProfiles = StringUtils.tokenizeToStringArray(
                        profileSpec, BeanDefinitionParserDelegate.MULTI_VALUE_ATTRIBUTE_DELIMITERS);
                if (!getReaderContext().getEnvironment().acceptsProfiles(specifiedProfiles)) {
                    if (logger.isInfoEnabled()) {
                        logger.info("Skipped XML bean definition file due to specified profiles [" + profileSpec +
                                "] not matching: " + getReaderContext().getResource());
                    }
                    return;
                }
            }
        }

        // 前置处理，目前为空
        preProcessXml(root);

        // ---------------------------[ STEP 2 ]---------------------------
        // 解析root下的子节点，依次处理
        parseBeanDefinitions(root, this.delegate); // <<<这里<<<

        // 后置处理，目前为空
        postProcessXml(root);

        this.delegate = parent;
    }

    // 解析root下的子节点，依次调用parseDefaultElement()或parseCustomElement()
    protected void parseBeanDefinitions(Element root, BeanDefinitionParserDelegate delegate) {
        if (delegate.isDefaultNamespace(root)) {
            NodeList nl = root.getChildNodes();
            for (int i = 0; i < nl.getLength(); i++) {
                Node node = nl.item(i);
                if (node instanceof Element) {
                    Element ele = (Element) node;

                    // ---------------[ STEP 3 ]---------------------------

                    // 子节点分default和custom两种方式处理
                    // <import/>、<alias/>、<bean/>、<beans/>，这些用default处理，就是内置处理方式
                    // 其他子节点用custom处理方式

                    if (delegate.isDefaultNamespace(ele)) {
                        parseDefaultElement(ele, delegate); // <<<这里<<<
                    }
                    else {
                        delegate.parseCustomElement(ele);
                    }
                }
            }
        }
        else {
            delegate.parseCustomElement(root);
        }
    }

    // 默认子节点调度器，包括<import/>、<alias/>、<bean/>、<beans/>
    private void parseDefaultElement(Element ele, BeanDefinitionParserDelegate delegate) {

        // ---------------------------[ STEP 4 ]---------------------------
        // 依据nodeName调用不同的子方法
        if (delegate.nodeNameEquals(ele, IMPORT_ELEMENT)) {
            importBeanDefinitionResource(ele);
        }
        else if (delegate.nodeNameEquals(ele, ALIAS_ELEMENT)) {
            processAliasRegistration(ele);
        }
        else if (delegate.nodeNameEquals(ele, BEAN_ELEMENT)) {
            processBeanDefinition(ele, delegate); // <<<这里<<<
        }
        else if (delegate.nodeNameEquals(ele, NESTED_BEANS_ELEMENT)) {
            // recurse
            doRegisterBeanDefinitions(ele);
        }
    }

    // 处理<bean/>节点
    protected void processBeanDefinition(Element ele, BeanDefinitionParserDelegate delegate) {

        // ---------------------------[ STEP 5 ]---------------------------
        // 将控制权交给BeanDefinitionParserDelegate处理
        // 这里转到BeanDefinitionParserDelegate处理，
        BeanDefinitionHolder bdHolder = delegate.parseBeanDefinitionElement(ele); // <<<这里<<<

        if (bdHolder != null) {
            // 装饰decorate返回的bdHolder，是什么意思？没有明白
            bdHolder = delegate.decorateBeanDefinitionIfRequired(ele, bdHolder);

            // 调用registerBeanDefinition()和registerAlias()，注册beanDefinition
            BeanDefinitionReaderUtils.registerBeanDefinition(bdHolder, getReaderContext().getRegistry());

            // Send registration event.
            getReaderContext().fireComponentRegistered(new BeanComponentDefinition(bdHolder));
        }
    }
}
{% endhighlight %}



---

**DefaultBeanDefinitionDocumentReader.processBeanDefinition(Element, BeanDefinitionParserDelegate)** 在将控制权交给 **BeanDefinitionParserDelegate**。

{% highlight java %}
package org.springframework.beans.factory.xml;

public class BeanDefinitionParserDelegate {

    // parseBeanDefinitionElement()定义两个重载方法：
    //      parseBeanDefinitionElement(Element ele, BeanDefinition containingBean)
    //      parseBeanDefinitionElement(Element ele, String beanName, BeanDefinition containingBean)
    // 首先进入的方法一，在这里通过id或aliases确定beanName
    // 确定beanName后，再调用方法二

    public BeanDefinitionHolder parseBeanDefinitionElement(Element ele, BeanDefinition containingBean) {        
        // 读取element的id和name属性
        String id = ele.getAttribute(ID_ATTRIBUTE);
        String nameAttr = ele.getAttribute(NAME_ATTRIBUTE);

        // name属性用来指定别名，如果有这样的设置：
        //  <bean id="myTestBean" name="foo,bar,xyz,abc" class="xxx" />
        // 则aliases[]=[foo,bar,xyz,abc]

        List<String> aliases = new ArrayList<String>();
        if (StringUtils.hasLength(nameAttr)) {
            String[] nameArr = StringUtils.tokenizeToStringArray(nameAttr, MULTI_VALUE_ATTRIBUTE_DELIMITERS);
            aliases.addAll(Arrays.asList(nameArr));
        }

        // id就是beanName
        // 如果没有指定id，但是有指定aliases，则aliases里面的第一项是beanName

        String beanName = id;
        if (!StringUtils.hasText(beanName) && !aliases.isEmpty()) {
            beanName = aliases.remove(0);
        }

        // containingBean是什么意思？
        // checkNameUniqueness()检查beanName和aliases是否已经存在

        if (containingBean == null) {
            checkNameUniqueness(beanName, aliases, ele);
        }

        // 注意：这里调用方法二
        AbstractBeanDefinition beanDefinition = parseBeanDefinitionElement(ele, beanName, containingBean);
        if (beanDefinition != null) {
            if (!StringUtils.hasText(beanName)) {
                if (containingBean != null) {
                    beanName = BeanDefinitionReaderUtils.generateBeanName(
                            beanDefinition, this.readerContext.getRegistry(), true);
                }
                else {
                    beanName = this.readerContext.generateBeanName(beanDefinition);
                    // Register an alias for the plain bean class name, if still possible,
                    // if the generator returned the class name plus a suffix.
                    // This is expected for Spring 1.2/2.0 backwards compatibility.
                    String beanClassName = beanDefinition.getBeanClassName();
                    if (beanClassName != null &&
                            beanName.startsWith(beanClassName) && beanName.length() > beanClassName.length() &&
                            !this.readerContext.getRegistry().isBeanNameInUse(beanClassName)) {
                        aliases.add(beanClassName);
                    }
                }
            }
            String[] aliasesArray = StringUtils.toStringArray(aliases);
            return new BeanDefinitionHolder(beanDefinition, beanName, aliasesArray);
        }

        return null;
    }

    public AbstractBeanDefinition parseBeanDefinitionElement(
            Element ele, String beanName, BeanDefinition containingBean) {

        // 读取<bean/>的class属性
        String className = null;
        if (ele.hasAttribute(CLASS_ATTRIBUTE)) {
            className = ele.getAttribute(CLASS_ATTRIBUTE).trim();
        }

        // 读取<bean/>的parent属性
        String parent = null;
        if (ele.hasAttribute(PARENT_ATTRIBUTE)) {
            parent = ele.getAttribute(PARENT_ATTRIBUTE);
        }

        // 创建GenericBeanDefinition对象
        //      createBeanDefinition():
        //          GenericBeanDefinition bd = new GenericBeanDefinition();
        //          bd.setParentName(parentName);
        //          if (className != null) {
        //              if (classLoader != null) {
        //                  bd.setBeanClass(ClassUtils.forName(className, classLoader));
        //              }
        //              else {
        //                  bd.setBeanClassName(className);
        //              }
        //          }

        AbstractBeanDefinition bd = createBeanDefinition(className, parent);

        // 读取<bean/>通用属性
        parseBeanDefinitionAttributes(ele, beanName, containingBean, bd);

        // 读取description属性
        bd.setDescription(DomUtils.getChildElementValueByTagName(ele, DESCRIPTION_ELEMENT));

        // 读取meta子节点
        parseMetaElements(ele, bd);

        // 读取lookup-method子节点
        parseLookupOverrideSubElements(ele, bd.getMethodOverrides());

        // 读取replace-method子节点
        parseReplacedMethodSubElements(ele, bd.getMethodOverrides());

        // 读取constructor-arg子节点
        parseConstructorArgElements(ele, bd);

        // 读取property子节点
        parsePropertyElements(ele, bd);

        // 读取qualifier子节点
        parseQualifierElements(ele, bd);

        bd.setResource(this.readerContext.getResource());
        bd.setSource(extractSource(ele));

        return bd;
    }

    // 读取通用属性
    public AbstractBeanDefinition parseBeanDefinitionAttributes(Element ele, String beanName,
            BeanDefinition containingBean, AbstractBeanDefinition bd) {

        // singleton或scope属性，标识bean的使用范围
        if (ele.hasAttribute(SINGLETON_ATTRIBUTE)) {
            error("Old 1.x 'singleton' attribute in use - upgrade to 'scope' declaration", ele);
        }
        else if (ele.hasAttribute(SCOPE_ATTRIBUTE)) {
            bd.setScope(ele.getAttribute(SCOPE_ATTRIBUTE));
        }
        else if (containingBean != null) {
            // Take default from containing bean in case of an inner bean definition.
            // containingBean应该是指上级bean，或者说是父bean
            bd.setScope(containingBean.getScope());
        }

        // abstract属性：表示bean是否是虚拟的？
        if (ele.hasAttribute(ABSTRACT_ATTRIBUTE)) {
            bd.setAbstract(TRUE_VALUE.equals(ele.getAttribute(ABSTRACT_ATTRIBUTE)));
        }

        // lazy-init属性
        String lazyInit = ele.getAttribute(LAZY_INIT_ATTRIBUTE);
        if (DEFAULT_VALUE.equals(lazyInit)) {
            lazyInit = this.defaults.getLazyInit();
        }
        bd.setLazyInit(TRUE_VALUE.equals(lazyInit));

        // autowire属性：自动注入属性的方法
        String autowire = ele.getAttribute(AUTOWIRE_ATTRIBUTE);
        bd.setAutowireMode(getAutowireMode(autowire));

        // dependency-check属性：
        String dependencyCheck = ele.getAttribute(DEPENDENCY_CHECK_ATTRIBUTE);
        bd.setDependencyCheck(getDependencyCheck(dependencyCheck));

        // depends-on属性
        if (ele.hasAttribute(DEPENDS_ON_ATTRIBUTE)) {
            String dependsOn = ele.getAttribute(DEPENDS_ON_ATTRIBUTE);
            bd.setDependsOn(StringUtils.tokenizeToStringArray(dependsOn, MULTI_VALUE_ATTRIBUTE_DELIMITERS));
        }

        // autowire-candidate属性：是否可以作为候选bean自动注入到其它包含autowire属性的bean？
        String autowireCandidate = ele.getAttribute(AUTOWIRE_CANDIDATE_ATTRIBUTE);
        if ("".equals(autowireCandidate) || DEFAULT_VALUE.equals(autowireCandidate)) {
            String candidatePattern = this.defaults.getAutowireCandidates();
            if (candidatePattern != null) {
                String[] patterns = StringUtils.commaDelimitedListToStringArray(candidatePattern);
                bd.setAutowireCandidate(PatternMatchUtils.simpleMatch(patterns, beanName));
            }
        }
        else {
            bd.setAutowireCandidate(TRUE_VALUE.equals(autowireCandidate));
        }

        // primary属性：自动装配时，如果出现多个候选bean，以包含primary属性的候选bean作为首选
        if (ele.hasAttribute(PRIMARY_ATTRIBUTE)) {
            bd.setPrimary(TRUE_VALUE.equals(ele.getAttribute(PRIMARY_ATTRIBUTE)));
        }

        // init-method属性
        if (ele.hasAttribute(INIT_METHOD_ATTRIBUTE)) {
            String initMethodName = ele.getAttribute(INIT_METHOD_ATTRIBUTE);
            if (!"".equals(initMethodName)) {
                bd.setInitMethodName(initMethodName);
            }
        }
        else {
            if (this.defaults.getInitMethod() != null) {
                bd.setInitMethodName(this.defaults.getInitMethod());
                bd.setEnforceInitMethod(false);
            }
        }

        // destory-method属性
        if (ele.hasAttribute(DESTROY_METHOD_ATTRIBUTE)) {
            String destroyMethodName = ele.getAttribute(DESTROY_METHOD_ATTRIBUTE);
            bd.setDestroyMethodName(destroyMethodName);
        }
        else {
            if (this.defaults.getDestroyMethod() != null) {
                bd.setDestroyMethodName(this.defaults.getDestroyMethod());
                bd.setEnforceDestroyMethod(false);
            }
        }

        // factory-method和factory-bean属性：处理工厂模式，静态工厂和实例工厂
        if (ele.hasAttribute(FACTORY_METHOD_ATTRIBUTE)) {
            bd.setFactoryMethodName(ele.getAttribute(FACTORY_METHOD_ATTRIBUTE));
        }
        if (ele.hasAttribute(FACTORY_BEAN_ATTRIBUTE)) {
            bd.setFactoryBeanName(ele.getAttribute(FACTORY_BEAN_ATTRIBUTE));
        }

        return bd;
    }

    // 读取meta属性
    public void parseMetaElements(Element ele, BeanMetadataAttributeAccessor attributeAccessor) {
        NodeList nl = ele.getChildNodes();
        for (int i = 0; i < nl.getLength(); i++) {
            Node node = nl.item(i);
            if (isCandidateElement(node) && nodeNameEquals(node, META_ELEMENT)) {

                // meta属性可以这样描述:
                //      <bean class="xxxx.Foo">
                //          <meta key="foo" value="abc" />
                //          <meta key="bar" value="xyz" />
                //      </beans>

                Element metaElement = (Element) node;
                String key = metaElement.getAttribute(KEY_ATTRIBUTE);
                String value = metaElement.getAttribute(VALUE_ATTRIBUTE);
                BeanMetadataAttribute attribute = new BeanMetadataAttribute(key, value);
                attribute.setSource(extractSource(metaElement));
                attributeAccessor.addMetadataAttribute(attribute);
            }
        }
    }

    // 读取lookup-method属性
    public void parseLookupOverrideSubElements(Element beanEle, MethodOverrides overrides) {
        NodeList nl = beanEle.getChildNodes();
        for (int i = 0; i < nl.getLength(); i++) {
            Node node = nl.item(i);
            if (isCandidateElement(node) && nodeNameEquals(node, LOOKUP_METHOD_ELEMENT)) {
                Element ele = (Element) node;
                String methodName = ele.getAttribute(NAME_ATTRIBUTE);
                String beanRef = ele.getAttribute(BEAN_ELEMENT);
                LookupOverride override = new LookupOverride(methodName, beanRef);
                override.setSource(extractSource(ele));
                overrides.addOverride(override);
            }
        }
    }

    // 读取replace-method属性
    public void parseReplacedMethodSubElements(Element beanEle, MethodOverrides overrides) {
        NodeList nl = beanEle.getChildNodes();
        for (int i = 0; i < nl.getLength(); i++) {
            Node node = nl.item(i);
            if (isCandidateElement(node) && nodeNameEquals(node, REPLACED_METHOD_ELEMENT)) {
                Element replacedMethodEle = (Element) node;
                String name = replacedMethodEle.getAttribute(NAME_ATTRIBUTE);
                String callback = replacedMethodEle.getAttribute(REPLACER_ATTRIBUTE);
                ReplaceOverride replaceOverride = new ReplaceOverride(name, callback);
                // Look for arg-type match elements.
                List<Element> argTypeEles = DomUtils.getChildElementsByTagName(replacedMethodEle, ARG_TYPE_ELEMENT);
                for (Element argTypeEle : argTypeEles) {
                    String match = argTypeEle.getAttribute(ARG_TYPE_MATCH_ATTRIBUTE);
                    match = (StringUtils.hasText(match) ? match : DomUtils.getTextValue(argTypeEle));
                    if (StringUtils.hasText(match)) {
                        replaceOverride.addTypeIdentifier(match);
                    }
                }
                replaceOverride.setSource(extractSource(replacedMethodEle));
                overrides.addOverride(replaceOverride);
            }
        }
    }

    // 读取constructor-arg属性
    public void parseConstructorArgElements(Element beanEle, BeanDefinition bd) {
        NodeList nl = beanEle.getChildNodes();
        for (int i = 0; i < nl.getLength(); i++) {
            Node node = nl.item(i);
            if (isCandidateElement(node) && nodeNameEquals(node, CONSTRUCTOR_ARG_ELEMENT)) {
                parseConstructorArgElement((Element) node, bd);
            }
        }
    }

    // 读取property属性
    public void parsePropertyElements(Element beanEle, BeanDefinition bd) {
        NodeList nl = beanEle.getChildNodes();
        for (int i = 0; i < nl.getLength(); i++) {
            Node node = nl.item(i);
            if (isCandidateElement(node) && nodeNameEquals(node, PROPERTY_ELEMENT)) {
                parsePropertyElement((Element) node, bd);
            }
        }
    }

    // 读取qualifier属性
    public void parseQualifierElements(Element beanEle, AbstractBeanDefinition bd) {
        NodeList nl = beanEle.getChildNodes();
        for (int i = 0; i < nl.getLength(); i++) {
            Node node = nl.item(i);
            if (isCandidateElement(node) && nodeNameEquals(node, QUALIFIER_ELEMENT)) {
                parseQualifierElement((Element) node, bd);
            }
        }
    }
}
{% endhighlight %}

**BeanDefinitionParserDelegate.parseBeanDefinitionElement()** 返回 **BeanDefinitionHolder**，

**DefaultBeanDefinitionDocumentReader.processBeanDefinition()** 接收到以后，注册到 **BeanFactory**。














{% highlight java %}

{% endhighlight %}