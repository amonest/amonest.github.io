---
layout: post
title: "@SpringBootApplication"
---

Spring Boot通常有一个名为Application的入口类，入口类里有一个main方法。入口类用@SpringBootApplication注解。

@SpringBootApplication实质是一个组合注解：

{% highlight java %}
package org.springframework.boot.autoconfigure;

@Target(ElementType.TYPE)
@Retention(RetentionPolicy.RUNTIME)
@Documented
@Inherited
@SpringBootConfiguration
@EnableAutoConfiguration
@ComponentScan(excludeFilters = @Filter(type = FilterType.CUSTOM, classes = TypeExcludeFilter.class))
public @interface SpringBootApplication {

}
{% endhighlight %}