---
layout: post
title: devtools
---

***spring-boot-devtools*** 是boot的一个热部署工具，当我们修改了classpath下的文件（包括类文件、属性文件、页面等）时，会重新启动应用。由于其采用的双类加载器机制，这个启动会非常快。

***双类加载器机制***：boot使用了两个类加载器来实现重启（restart）机制：***base类加载器（简称bc）*** + ***restart类加载器（简称rc）***。

+ ***bc***：用于加载不会改变的jar（eg.第三方依赖的jar）

+ ***rc***：用于加载我们正在开发的jar（eg.整个项目里我们自己编写的类）。当应用重启后，原先的rc被丢掉、重新new一个rc来加载这些修改过的东西，而bc却不需要动一下。这就是devtools重启速度快的原因。

---

修改pom.xml：

{% highlight xml %}
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-devtools</artifactId>
</dependency>
{% endhighlight %}