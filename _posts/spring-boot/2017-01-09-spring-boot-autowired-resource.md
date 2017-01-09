---
layout: post
title: Spring Boot - 区别@Autowired与@Resource
---

**@Autowired** 为Spring提供的注解，需要导入包 **org.springframework.beans.factory.annotation.Autowired**。

{% highlight java %}
public class TestServiceImpl {

    // 下面两种@Autowired只要使用一种即可

    @Autowired
    private UserDao userDao; // 用于字段上
    
    @Autowired
    public void setUserDao(UserDao userDao) { // 用于属性的方法上
        this.userDao = userDao;
    }
}
{% endhighlight %}

**@Autowired** 注解是按照类型（**byType**）装配依赖对象，默认情况下它要求依赖对象必须存在，如果允许null值，可以设置它的 **required** 属性为false。

{% highlight java %}
public class TestServiceImpl {
    @Autowired(required = false)
    private UserDao userDao; 
}
{% endhighlight %}

如果我们想使用按照名称（**byName**）来装配，可以结合 **@Qualifier** 注解一起使用。

{% highlight java %}
public class TestServiceImpl {
    @Autowired
    @Qualifier("userDao")
    private UserDao userDao; 
}
{% endhighlight %}


**@Resource** 默认按照 **ByName** 自动注入，由J2EE提供，需要导入包 **javax.annotation.Resource**。**@Resource** 有两个重要的属性：**name** 和 **type**，而Spring将 **@Resource** 注解的 **name** 属性解析为bean的名字，而 **type** 属性则解析为bean的类型。所以，如果使用 **name** 属性，则使用 **byName** 的自动注入策略，而使用 **type** 属性时则使用 **byType** 自动注入策略。如果既不制定 **name** 也不制定 **type** 属性，这时将通过反射机制使用 **byName** 自动注入策略。

{% highlight java %}
public class TestServiceImpl {

    // 下面两种@Resource只要使用一种即可

    @Resource(name="userDao")
    private UserDao userDao; // 用于字段上
    
    @Resource(name="userDao")
    public void setUserDao(UserDao userDao) { // 用于属性的setter方法上
        this.userDao = userDao;
    }
}
{% endhighlight %}

@Resource装配顺序：

+ 如果同时指定了 **name** 和 **type**，则从Spring上下文中找到唯一匹配的bean进行装配，找不到则抛出异常。

+ 如果指定了 **name** ，则从上下文中查找名称（id）匹配的bean进行装配，找不到则抛出异常。

+ 如果指定了 **type**，则从上下文中找到类似匹配的唯一bean进行装配，找不到或是找到多个，都会抛出异常。

+ 如果既没有指定 **name**，又没有指定**type**，则自动按照 **byName** 方式进行装配；如果没有匹配，则回退为一个原始类型进行匹配，如果匹配则自动装配。
