---
layout: post
title: Spring Boot - 初始化Spring Boot项目
---

我们在开发过程中可能会有这样的情景：需要在容器启动的时候执行一些内容，比如读取配置文件、数据库连接之类的。SpringBoot给我们提供了两个接口来帮助我们实现这种需求，这两个接口分别为 **CommandLineRunner** 和 **ApplicationRunner**。他们的执行时机为容器启动完成的时候。

这两个接口中有一个run方法，我们只需要实现这个方法即可。这两个接口的不同之处在于：**ApplicationRunner** 中 **run** 方法的参数为 **ApplicationArguments**，而 **CommandLineRunner** 接口中 **run** 方法的参数为 **String数组**。

***如果有多个实现类，而你需要他们按一定顺序执行的话，可以在实现类上加上 @Order 注解，SpringBoot 会按照 @Order 中的 value 值从小到大依次执行。***

---

ApplicationRunner:

{% highlight java %}
package net.mingyang.spring_boot_test;

import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.stereotype.Component;

@Component
public class TestApplicationRunner implements ApplicationRunner {

    public void run(ApplicationArguments args) throws Exception {
        System.out.println("Hello ApplicationRunner");;
    }
}
{% endhighlight %}

---

CommandLineRunner:

{% highlight java %}
package net.mingyang.spring_boot_test;

import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

@Component
public class TestCommandLineRunner implements CommandLineRunner {

    public void run(String... args) throws Exception {
        System.out.println("Hello CommandLineRunner");;
    }
}
{% endhighlight %}