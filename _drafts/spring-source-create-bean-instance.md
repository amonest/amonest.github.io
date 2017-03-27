---
layout: post
title: Spring Source - 创建Bean实例
---

{% include block/spring-source-list.html %}


---

ApplicationContext有一个getBean()方法，可以返回Bean实例。

{% highlight java %}
ApplicationContext ctx = new ClassPathXmlApplicationContext("applicationContext.xml");
Animal animal = ctx.getBean("animal", Animal.class);
{% endhighlight %}


---

getBean()方法是在AbstractBeanFactory类实现的。

{% highlight java %}
public class AbstractBeanFactory extends ... {

    @Override
    public <T> T getBean(String name, Class<T> requiredType) throws BeansException {
        return doGetBean(name, requiredType, null, false);
    }
}
{% endhighlight %}


---

getBean()调用了内部方法doGetBean()。

{% highlight java %}
protected <T> T doGetBean(
        final String name, final Class<T> requiredType, final Object[] args, boolean typeCheckOnly)
        throws BeansException {

    final String beanName = transformedBeanName(name);
    Object bean;

    // Eagerly check singleton cache for manually registered singletons.
    Object sharedInstance = getSingleton(beanName);
    if (sharedInstance != null && args == null) {
        if (logger.isDebugEnabled()) {
            if (isSingletonCurrentlyInCreation(beanName)) {
                logger.debug("Returning eagerly cached instance of singleton bean '" + beanName +
                        "' that is not fully initialized yet - a consequence of a circular reference");
            }
            else {
                logger.debug("Returning cached instance of singleton bean '" + beanName + "'");
            }
        }
        bean = getObjectForBeanInstance(sharedInstance, name, beanName, null);
    }

    else {
        // Fail if we're already creating this bean instance:
        // We're assumably within a circular reference.
        if (isPrototypeCurrentlyInCreation(beanName)) {
            throw new BeanCurrentlyInCreationException(beanName);
        }

        // Check if bean definition exists in this factory.
        BeanFactory parentBeanFactory = getParentBeanFactory();
        if (parentBeanFactory != null && !containsBeanDefinition(beanName)) {
            // Not found -> check parent.
            String nameToLookup = originalBeanName(name);
            if (args != null) {
                // Delegation to parent with explicit args.
                return (T) parentBeanFactory.getBean(nameToLookup, args);
            }
            else {
                // No args -> delegate to standard getBean method.
                return parentBeanFactory.getBean(nameToLookup, requiredType);
            }
        }

        if (!typeCheckOnly) {
            markBeanAsCreated(beanName);
        }

        try {
            final RootBeanDefinition mbd = getMergedLocalBeanDefinition(beanName);
            checkMergedBeanDefinition(mbd, beanName, args);

            // Guarantee initialization of beans that the current bean depends on.
            String[] dependsOn = mbd.getDependsOn();
            if (dependsOn != null) {
                for (String dep : dependsOn) {
                    if (isDependent(beanName, dep)) {
                        throw new BeanCreationException(mbd.getResourceDescription(), beanName,
                                "Circular depends-on relationship between '" + beanName + "' and '" + dep + "'");
                    }
                    registerDependentBean(dep, beanName);
                    getBean(dep);
                }
            }

            // Create bean instance.
            if (mbd.isSingleton()) {
                sharedInstance = getSingleton(beanName, new ObjectFactory<Object>() {
                    @Override
                    public Object getObject() throws BeansException {
                        try {
                            return createBean(beanName, mbd, args);
                        }
                        catch (BeansException ex) {
                            // Explicitly remove instance from singleton cache: It might have been put there
                            // eagerly by the creation process, to allow for circular reference resolution.
                            // Also remove any beans that received a temporary reference to the bean.
                            destroySingleton(beanName);
                            throw ex;
                        }
                    }
                });
                bean = getObjectForBeanInstance(sharedInstance, name, beanName, mbd);
            }

            else if (mbd.isPrototype()) {
                // It's a prototype -> create a new instance.
                Object prototypeInstance = null;
                try {
                    beforePrototypeCreation(beanName);
                    prototypeInstance = createBean(beanName, mbd, args);
                }
                finally {
                    afterPrototypeCreation(beanName);
                }
                bean = getObjectForBeanInstance(prototypeInstance, name, beanName, mbd);
            }

            else {
                String scopeName = mbd.getScope();
                final Scope scope = this.scopes.get(scopeName);
                if (scope == null) {
                    throw new IllegalStateException("No Scope registered for scope name '" + scopeName + "'");
                }
                try {
                    Object scopedInstance = scope.get(beanName, new ObjectFactory<Object>() {
                        @Override
                        public Object getObject() throws BeansException {
                            beforePrototypeCreation(beanName);
                            try {
                                return createBean(beanName, mbd, args);
                            }
                            finally {
                                afterPrototypeCreation(beanName);
                            }
                        }
                    });
                    bean = getObjectForBeanInstance(scopedInstance, name, beanName, mbd);
                }
                catch (IllegalStateException ex) {
                    throw new BeanCreationException(beanName,
                            "Scope '" + scopeName + "' is not active for the current thread; consider " +
                            "defining a scoped proxy for this bean if you intend to refer to it from a singleton",
                            ex);
                }
            }
        }
        catch (BeansException ex) {
            cleanupAfterBeanCreationFailure(beanName);
            throw ex;
        }
    }

    // Check if required type matches the type of the actual bean instance.
    if (requiredType != null && bean != null && !requiredType.isAssignableFrom(bean.getClass())) {
        try {
            return getTypeConverter().convertIfNecessary(bean, requiredType);
        }
        catch (TypeMismatchException ex) {
            if (logger.isDebugEnabled()) {
                logger.debug("Failed to convert bean '" + name + "' to required type '" +
                        ClassUtils.getQualifiedName(requiredType) + "'", ex);
            }
            throw new BeanNotOfRequiredTypeException(name, requiredType, bean.getClass());
        }
    }
    return (T) bean;
}
{% endhighlight %}




---

### 01. transformedBeanName()

{% highlight java %}
final String beanName = transformedBeanName(name);
{% endhighlight %}

**AbstractBeanFactory** 里面的 **transformedBeanName()** 是这样定义的：

{% highlight java %}
protected String transformedBeanName(String name) {
    return canonicalName(BeanFactoryUtils.transformedBeanName(name));
}
{% endhighlight %}

**canonicalName()** 目的是处理别名，如果传入的bean name是别名，需要转换成实际的名称。

因为可能存在别名的别名这种情况，所有这里使用了一个do while {}循环。

{% highlight java %}
public String canonicalName(String name) {
    String canonicalName = name;
    String resolvedName;
    do {
        resolvedName = this.aliasMap.get(canonicalName);
        if (resolvedName != null) {
            canonicalName = resolvedName;
        }
    }
    while (resolvedName != null);
    return canonicalName;
}
{% endhighlight %}

**transformedBeanName()** 实际调用 **BeanFactoryUtils.transformedBeanName(name)** 来处理。

{% highlight java %}
publiic class BeanFactoryUtils {
    public static String transformedBeanName(String name) {
        String beanName = name;
        while (beanName.startsWith(BeanFactory.FACTORY_BEAN_PREFIX)) {
            beanName = beanName.substring(BeanFactory.FACTORY_BEAN_PREFIX.length());
        }
        return beanName;
    }
}
{% endhighlight %}

Spring有两种Bean，一种是普通Bean(plain bean)，一种是工厂Bean(factory bean)。

工厂Bean要实现FactoryBean<T>接口。调用getBean()时，默认是调用接口的getObject()方法，返回结果。

{% highlight java %}
public interface FactoryBean<T> {
    T getObject() throws Exception;
    Class<?> getObjectType();
    boolean isSingleton();
}
{% endhighlight %}

Spring有定义一个工厂Bean前缀(BeanFactory.FACTORY_BEAN_PREFIX="&")，调用getBean()时，可以返回factory bean实例，而不是调用getObject()方法。

{% highlight java %}
AnimalFactory factory = ctx.getBean("&animalFactory", AnimalFactory.class);
{% endhighlight %}

getBean()的调用参数是name，name可能包含FACTORY_BEAN_PREFIX。

**BeanFactoryUtils.transformedBeanName(name)** 去掉bena name里面所有的 **FACTORY_BEAN_PREFIX**。




---

### 02. getSingleton()

{% highlight java %}
Object sharedInstance = getSingleton(beanName);
{% endhighlight %}

**getSingleton()** 是在 **DefaultSingletonBeanRegistry** 定义的，**AbstractBeanFactory** 继承了这个类。

{% highlight java %}
@Override
public Object getSingleton(String beanName) {
    return getSingleton(beanName, true);
}

protected Object getSingleton(String beanName, boolean allowEarlyReference) {
    Object singletonObject = this.singletonObjects.get(beanName);
    if (singletonObject == null && isSingletonCurrentlyInCreation(beanName)) {
        synchronized (this.singletonObjects) {
            singletonObject = this.earlySingletonObjects.get(beanName);
            if (singletonObject == null && allowEarlyReference) {
                ObjectFactory<?> singletonFactory = this.singletonFactories.get(beanName);
                if (singletonFactory != null) {
                    singletonObject = singletonFactory.getObject();
                    this.earlySingletonObjects.put(beanName, singletonObject);
                    this.singletonFactories.remove(beanName);
                }
            }
        }
    }
    return (singletonObject != NULL_OBJECT ? singletonObject : null);
}
{% endhighlight %}

这里重载了两个方法，提供了一个 **allowEarlyReference** 参数。

这里使用了三个重要的实例变量： **singletonObjects** 、 **singleFactories** 和 **earlySingletonObjects**。

singleton有两种注册方式。第一种方式，调用 **registerSingleton()**，将 **singletonObject** 保存在 **singletonObjects** 实例变量。

{% highlight java %}
/** Cache of singleton objects: bean name --> bean instance */
private final Map<String, Object> singletonObjects = new ConcurrentHashMap<String, Object>(256);

@Override
public void registerSingleton(String beanName, Object singletonObject) throws IllegalStateException {
    synchronized (this.singletonObjects) {
        Object oldObject = this.singletonObjects.get(beanName);
        addSingleton(beanName, singletonObject);
    }
}

protected void addSingleton(String beanName, Object singletonObject) {
    synchronized (this.singletonObjects) {
        this.singletonObjects.put(beanName, (singletonObject != null ? singletonObject : NULL_OBJECT));
        this.singletonFactories.remove(beanName);
        this.earlySingletonObjects.remove(beanName);
        this.registeredSingletons.add(beanName);
    }
}
{% endhighlight %}


第二种方式，调用 **addSingletonFactory()**，将 **singleFactory** 保存在 **singletonFactories** 实例变量。这是一个protected方法，所以只能在内部调用。**singletonFactory** 类型是 **ObjectFactory<?>**。

{% highlight java %}
/** Cache of singleton factories: bean name --> ObjectFactory */
private final Map<String, ObjectFactory<?>> singletonFactories = new HashMap<String, ObjectFactory<?>>(16);

/** Cache of early singleton objects: bean name --> bean instance */
private final Map<String, Object> earlySingletonObjects = new HashMap<String, Object>(16);

protected void addSingletonFactory(String beanName, ObjectFactory<?> singletonFactory) {
    Assert.notNull(singletonFactory, "Singleton factory must not be null");
    synchronized (this.singletonObjects) {
        if (!this.singletonObjects.containsKey(beanName)) {
            this.singletonFactories.put(beanName, singletonFactory);
            this.earlySingletonObjects.remove(beanName);
            this.registeredSingletons.add(beanName);
        }
    }
}
{% endhighlight %}

**getSingleton()** 执行时，先检查是否存在 **singletonObjects**，如果存在，就直接返回。然后检查是否存在 **singletonFactories**，如果存在，就调用它的 **getObject()** 创建一个 **singletonObject**，添加到 **earlySingletonObjects**，再返回 **singletonObject**。




---

### 03. getObjectForBeanInstance()

{% highlight java %}
Object sharedInstance = getSingleton(beanName);
if (sharedInstance != null && args == null) {
    bean = getObjectForBeanInstance(sharedInstance, name, beanName, null);
}
{% endhighlight %}

**sharedInstance** 是 **getSingleton()** 返回的结果。如果 **sharedInstance** 不为空，则对它调用 **getObjectForBeanInstance()**。

{% highlight java %}
protected Object getObjectForBeanInstance(
            Object beanInstance, String name, String beanName, RootBeanDefinition mbd) {

    if (BeanFactoryUtils.isFactoryDereference(name) && !(beanInstance instanceof FactoryBean)) {
        throw new BeanIsNotAFactoryException(transformedBeanName(name), beanInstance.getClass());
    }

    if (!(beanInstance instanceof FactoryBean) || BeanFactoryUtils.isFactoryDereference(name)) {
        return beanInstance;
    }

    Object object = null;
    if (mbd == null) {
        object = getCachedObjectForFactoryBean(beanName);
    }

    if (object == null) {
        FactoryBean<?> factory = (FactoryBean<?>) beanInstance;
        // Caches object obtained from FactoryBean if it is a singleton.
        if (mbd == null && containsBeanDefinition(beanName)) {
            mbd = getMergedLocalBeanDefinition(beanName);
        }
        boolean synthetic = (mbd != null && mbd.isSynthetic());
        object = getObjectFromFactoryBean(factory, beanName, !synthetic);
    }
    return object;
}
{% endhighlight %}

**BeanFactoryUtils.isFactoryDereference()** 检查 **name** 是否以 **FACTORY_BEAN_PREFIX** 开头，这是 **FactoryBean** 标识。

{% highlight java %}
public static boolean isFactoryDereference(String name) {
    return (name != null && name.startsWith(BeanFactory.FACTORY_BEAN_PREFIX));
}
{% endhighlight %}

通过 **FactoryBean** 创建的 **bean** 都会缓存在实例变量 **factoryBeanObjectCache** 里面，通过 **getCachedObjectForFactoryBean()** 可以重复使用。

{% highlight java %}
protected Object getCachedObjectForFactoryBean(String beanName) {
    Object object = this.factoryBeanObjectCache.get(beanName);
    return (object != NULL_OBJECT ? object : null);
}
{% endhighlight %}

**FactoryBean** 没有创建过 **bean** 时，通过 **getObjectFromFactoryBean()** 调用 **FactoryBean** 接口方法。




---

### 04. getObjectFromFactoryBean()

TODO XXXXXXXXXXXXXXXXXXXXX

{% highlight java %}
{% endhighlight %}




---

### 05. getParentBeanFactory()

{% highlight java %}
// Check if bean definition exists in this factory.
BeanFactory parentBeanFactory = getParentBeanFactory();
if (parentBeanFactory != null && !containsBeanDefinition(beanName)) {
    // Not found -> check parent.
    String nameToLookup = originalBeanName(name);
    if (args != null) {
        // Delegation to parent with explicit args.
        return (T) parentBeanFactory.getBean(nameToLookup, args);
    }
    else {
        // No args -> delegate to standard getBean method.
        return parentBeanFactory.getBean(nameToLookup, requiredType);
    }
}
{% endhighlight %}

**BeanFactory** 是可以嵌套的。如果bean name在当前 **BeanFactory** 找不到，可以继续在上一级 **BeanFactory** 找，直到找到最上一级。。




---

### 06. markBeanAsCreated()

{% highlight java %}
if (!typeCheckOnly) {
    markBeanAsCreated(beanName);
}
{% endhighlight %}

**markBeanAsCreated()** 将已经调用过 **getBean()** 的 **beanName** 保存到实例变量 **alreadyCreated**。

{% highlight java %}
protected void markBeanAsCreated(String beanName) {
    if (!this.alreadyCreated.contains(beanName)) {
        synchronized (this.mergedBeanDefinitions) {
            if (!this.alreadyCreated.contains(beanName)) {
                // Let the bean definition get re-merged now that we're actually creating
                // the bean... just in case some of its metadata changed in the meantime.
                clearMergedBeanDefinition(beanName);
                this.alreadyCreated.add(beanName);
            }
        }
    }
}
{% endhighlight %}




---

### 07. getMergedLocalBeanDefinition()

{% highlight java %}
final RootBeanDefinition mbd = getMergedLocalBeanDefinition(beanName);
checkMergedBeanDefinition(mbd, beanName, args); // 检查mbd是否是Abstract
{% endhighlight %}

Spring定义 **bean** 时，是允许使用继承的。例如：

{% highlight xml %}
<bean id="testBeanParent"  abstract="true"  class="com.wanzheng90.bean.TestBean">
    <property name="param1" value="父参数1" />
<property name="param2" value="父参数2" />
</bean>

<bean id="testBeanChild1" parent="testBeanParent" />

<bean id="testBeanChild2" parent="testBeanParent">
    <property name="param1" value="子参数1" />
</bean>
{% endhighlight %}

**getMergedLocalBeanDefinition()** 的目的就是合并 **BeanDefinition**。

{% highlight java %}
protected RootBeanDefinition getMergedLocalBeanDefinition(String beanName) throws BeansException {
    // 实例变量 mergedBeanDefinitions 做了缓存
    RootBeanDefinition mbd = this.mergedBeanDefinitions.get(beanName);
    if (mbd != null) {
        return mbd;
    }
    return getMergedBeanDefinition(beanName, getBeanDefinition(beanName));
}

protected RootBeanDefinition getMergedBeanDefinition(String beanName, BeanDefinition bd)
        throws BeanDefinitionStoreException {
    return getMergedBeanDefinition(beanName, bd, null);
}

protected RootBeanDefinition getMergedBeanDefinition(
        String beanName, BeanDefinition bd, BeanDefinition containingBd)
        throws BeanDefinitionStoreException {

    synchronized (this.mergedBeanDefinitions) {
        RootBeanDefinition mbd = null;

        // Check with full lock now in order to enforce the same merged instance.
        if (containingBd == null) {
            mbd = this.mergedBeanDefinitions.get(beanName);
        }

        if (mbd == null) {
            if (bd.getParentName() == null) {
                // Use copy of given root bean definition.
                if (bd instanceof RootBeanDefinition) {
                    mbd = ((RootBeanDefinition) bd).cloneBeanDefinition();
                }
                else {
                    mbd = new RootBeanDefinition(bd);
                }
            }
            else {
                // Child bean definition: needs to be merged with parent.
                BeanDefinition pbd;
                try {
                    String parentBeanName = transformedBeanName(bd.getParentName());
                    if (!beanName.equals(parentBeanName)) {
                        pbd = getMergedBeanDefinition(parentBeanName);
                    }
                    else {
                        BeanFactory parent = getParentBeanFactory();
                        if (parent instanceof ConfigurableBeanFactory) {
                            pbd = ((ConfigurableBeanFactory) parent).getMergedBeanDefinition(parentBeanName);
                        }
                        else {
                            throw new NoSuchBeanDefinitionException(parentBeanName,
                                    "Parent name '" + parentBeanName + "' is equal to bean name '" + beanName +
                                    "': cannot be resolved without an AbstractBeanFactory parent");
                        }
                    }
                }
                catch (NoSuchBeanDefinitionException ex) {
                    throw new BeanDefinitionStoreException(bd.getResourceDescription(), beanName,
                            "Could not resolve parent bean definition '" + bd.getParentName() + "'", ex);
                }
                // Deep copy with overridden values.
                mbd = new RootBeanDefinition(pbd);
                mbd.overrideFrom(bd);
            }

            // Set default singleton scope, if not configured before.
            if (!StringUtils.hasLength(mbd.getScope())) {
                mbd.setScope(RootBeanDefinition.SCOPE_SINGLETON);
            }

            // A bean contained in a non-singleton bean cannot be a singleton itself.
            // Let's correct this on the fly here, since this might be the result of
            // parent-child merging for the outer bean, in which case the original inner bean
            // definition will not have inherited the merged outer bean's singleton status.
            if (containingBd != null && !containingBd.isSingleton() && mbd.isSingleton()) {
                mbd.setScope(containingBd.getScope());
            }

            // Only cache the merged bean definition if we're already about to create an
            // instance of the bean, or at least have already created an instance before.
            if (containingBd == null && isCacheBeanMetadata()) {
                this.mergedBeanDefinitions.put(beanName, mbd);
            }
        }

        return mbd;
    }
}
{% endhighlight %}

**getMergedLocalBeanDefinition()** 的第一个参数 **beanName**，是子 **BeanDefinition** 名称。

第二个参数 **bd**，是子 **BeanDefinition**，通过 **getBeanDefinition()** 获取。

{% highlight java %}
@Override
public BeanDefinition getBeanDefinition(String beanName) throws NoSuchBeanDefinitionException {
    BeanDefinition bd = this.beanDefinitionMap.get(beanName);
    if (bd == null) {
        throw new NoSuchBeanDefinitionException(beanName);
    }
    return bd;
}
{% endhighlight %}

第三参数 **containingBd**，暂时没有使用。

首先检查实变量 **mergedBeanDefinitions** 是否已经存在，避免重复处理。

{% highlight java %}
mbd = this.mergedBeanDefinitions.get(beanName);
{% endhighlight %}

如果 **bd.getParentName()** 为空，说明没有使用继承，则直接返回 **bd** 或将 **bd** 作为构造参数创建一个 **RootBeanDefinition**。

{% highlight java %}
if (bd.getParentName() == null) {
    // Use copy of given root bean definition.
    if (bd instanceof RootBeanDefinition) {
        mbd = ((RootBeanDefinition) bd).cloneBeanDefinition();
    }
    else {
        mbd = new RootBeanDefinition(bd);
    }
}
{% endhighlight %}

如果 **bd.getParentName()** 不为空，说明使用了继承。

{% highlight java %}
BeanDefinition pbd;
try {
    // 转换parentBeanName
    String parentBeanName = transformedBeanName(bd.getParentName());

    // 如果beanName <> parentBeanName, 则对parentBeanName调用getMergedBeanDefinition()。
    // 因为parentBeanName也可能使用了继承
    if (!beanName.equals(parentBeanName)) {
        pbd = getMergedBeanDefinition(parentBeanName);
    }
    else {

        // 如果beanName == parentBeanName, 就是说两个同名
        // 这时候, parentBeanName应该存在于parentBeanFactory

        BeanFactory parent = getParentBeanFactory();
        if (parent instanceof ConfigurableBeanFactory) {
            pbd = ((ConfigurableBeanFactory) parent).getMergedBeanDefinition(parentBeanName);
        }
        else {
            throw new NoSuchBeanDefinitionException(parentBeanName,
                    "Parent name '" + parentBeanName + "' is equal to bean name '" + beanName +
                    "': cannot be resolved without an AbstractBeanFactory parent");
        }
    }
}
catch (NoSuchBeanDefinitionException ex) {
    throw new BeanDefinitionStoreException(bd.getResourceDescription(), beanName,
            "Could not resolve parent bean definition '" + bd.getParentName() + "'", ex);
}

// 用pbd创建一个RootBeanDefinition,
// 然后用bd属性覆盖mbd
mbd = new RootBeanDefinition(pbd);
mbd.overrideFrom(bd);
{% endhighlight %}

最后，缓存mbd到实例变量 **mergedBeanDefinitions**。

{% highlight java %}
if (containingBd == null && isCacheBeanMetadata()) {
    this.mergedBeanDefinitions.put(beanName, mbd);
}
{% endhighlight %}




---

### 08. Create Singleton Bean

如果 **scope = singleton**，则调用 **getSingleton()** 创建实例。

{% highlight java %}
if (mbd.isSingleton()) {
    sharedInstance = getSingleton(beanName, new ObjectFactory<Object>() {
        @Override
        public Object getObject() throws BeansException {
            return createBean(beanName, mbd, args);
        }
    });
    bean = getObjectForBeanInstance(sharedInstance, name, beanName, mbd);
}
{% endhighlight %}

这里 **getSingleton()** 的第二个参数是 **ObjectFactory** 类型。

{% highlight java %}
public Object getSingleton(String beanName, ObjectFactory<?> singletonFactory) {
    synchronized (this.singletonObjects) {
        Object singletonObject = this.singletonObjects.get(beanName);
        if (singletonObject == null) {
            beforeSingletonCreation(beanName);
            singletonObject = singletonFactory.getObject(); // 调用ObjectFactory接口
            afterSingletonCreation(beanName);
            addSingleton(beanName, singletonObject);
        }
        return (singletonObject != NULL_OBJECT ? singletonObject : null);
    }
}
{% endhighlight %}

这时的 **singletonFactory** 是一个匿名类，实际调用的是 **createBean()** 方法。

{% highlight java %}
@Override
protected Object createBean(String beanName, RootBeanDefinition mbd, Object[] args) throws BeanCreationException {
    RootBeanDefinition mbdToUse = mbd;

    // 解析class
    // 如果mbd只设置了beanClassName，没有设置beanClass，则需要clone一个RootBeanDefinition

    // Make sure bean class is actually resolved at this point, and
    // clone the bean definition in case of a dynamically resolved Class
    // which cannot be stored in the shared merged bean definition.
    Class<?> resolvedClass = resolveBeanClass(mbd, beanName);
    if (resolvedClass != null && !mbd.hasBeanClass() && mbd.getBeanClassName() != null) {
        mbdToUse = new RootBeanDefinition(mbd);
        mbdToUse.setBeanClass(resolvedClass);
    }

    // Prepare method overrides.
    mbdToUse.prepareMethodOverrides();

    // 检查是否有InstantiationAwareBeanPostProcessor存在?
    // Give BeanPostProcessors a chance to return a proxy instead of the target bean instance.
    Object bean = resolveBeforeInstantiation(beanName, mbdToUse);
    if (bean != null) {
        return bean;
    }

    Object beanInstance = doCreateBean(beanName, mbdToUse, args);
    return beanInstance;
}
{% endhighlight %}

看这里的 **resolveBeforeInstantiation()**，**BeanPostProcessor** 有一类叫 **InstantiationAwareBeanPostProcessor**。

Spring允许使用 **InstantiationAwareBeanPostProcessor** 创建bean实例。

{% highlight java %}
protected Object resolveBeforeInstantiation(String beanName, RootBeanDefinition mbd) {
    Object bean = null;
    if (!Boolean.FALSE.equals(mbd.beforeInstantiationResolved)) {
        // Make sure bean class is actually resolved at this point.
        if (!mbd.isSynthetic() && hasInstantiationAwareBeanPostProcessors()) {
            Class<?> targetType = determineTargetType(beanName, mbd);
            if (targetType != null) {
                bean = applyBeanPostProcessorsBeforeInstantiation(targetType, beanName);
                if (bean != null) { // InstantiationAwareBeanPostProcessor是否有创建bean实例？
                    bean = applyBeanPostProcessorsAfterInitialization(bean, beanName);
                }
            }
        }
        mbd.beforeInstantiationResolved = (bean != null);
    }
    return bean;
}

protected Object applyBeanPostProcessorsBeforeInstantiation(Class<?> beanClass, String beanName) {
    for (BeanPostProcessor bp : getBeanPostProcessors()) {
        if (bp instanceof InstantiationAwareBeanPostProcessor) {
            InstantiationAwareBeanPostProcessor ibp = (InstantiationAwareBeanPostProcessor) bp;
            Object result = ibp.postProcessBeforeInstantiation(beanClass, beanName);
            if (result != null) { // InstantiationAwareBeanPostProcessor是否有创建bean实例？
                return result;
            }
        }
    }
    return null;
}
{% endhighlight %}

















{% highlight java %}
{% endhighlight %}

{% highlight java %}
{% endhighlight %}

{% highlight java %}
{% endhighlight %}

{% highlight java %}
{% endhighlight %}

{% highlight java %}
{% endhighlight %}

{% highlight java %}
{% endhighlight %}