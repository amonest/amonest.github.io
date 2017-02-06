---
layout: post
title: Spring Analysis - AnnotationUtils
---

**Spring** 实现了注解的继承，关键是 **AnnotationUtils.findAnnotation()** 方法。

{% highlight java %}
private static <A extends Annotation> A findAnnotation(Class<?> clazz, 
            Class<A> annotationType, Set<Annotation> visited) {
    try {
        Annotation[] anns = clazz.getDeclaredAnnotations();

        // 查找当前类上直接标注的注解？
        for (Annotation ann : anns) {
            if (ann.annotationType() == annotationType) {
                return (A) ann;
            }
        }

        for (Annotation ann : anns) {
            if (!isInJavaLangAnnotationPackage(ann) && visited.add(ann)) {
                // 查找注解的注解，这里用了递归的方式，会查找到最顶层注解
                A annotation = findAnnotation(ann.annotationType(), annotationType, visited);
                if (annotation != null) {
                    return annotation;
                }
            }
        }
    }
    catch (Throwable ex) {
        handleIntrospectionFailure(clazz, ex);
        return null;
    }

    // 查找当前类实现的接口
    for (Class<?> ifc : clazz.getInterfaces()) {
        A annotation = findAnnotation(ifc, annotationType, visited);
        if (annotation != null) {
            return annotation;
        }
    }

    // 查找当前类的父类
    Class<?> superclass = clazz.getSuperclass();
    if (superclass == null || Object.class == superclass) {
        return null;
    }
    return findAnnotation(superclass, annotationType, visited);
}
{% endhighlight %}

例如，以 **@SpringBootApplication** 为例，它的继承关系如下：

{% highlight java %}
@SpringBootConfiguration
public @interface SpringBootApplication {}

@Configuration
public @interface SpringBootConfiguration {}

@Component
public @interface Configuration {}

public @interface Component {}
{% endhighlight %}

如果一个类用 **@SpringBootApplication** 注解做了标注：

{% highlight java %}
@SpringBootApplication
public class SpringTestApplication {}
{% endhighlight %}

就可以使用 **AnnotationUtils.findAnnotation()** 方法在该类上查找到 **@Component** 注解：

{% highlight java %}
AnnotationUtils.findAnnotation(SpringTestApplication.class, Component.class);
{% endhighlight %}