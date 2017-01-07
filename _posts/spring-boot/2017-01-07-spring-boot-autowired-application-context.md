---
layout: post
title: Spring Boot - 自动注入ApplicationContext
---

使用 **@Autowired** 注解，可以自动注入 **ApplicationContext** 变量。

---

{% highlight java %}
package net.mingyang.spring_boot_test;

import java.util.Arrays;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.ApplicationContext;
import org.springframework.stereotype.Component;

@Component
public class TestApplicationContext implements CommandLineRunner {

    @Autowired
    private ApplicationContext ctx;
    
    public void run(String... args) throws Exception {
        String[] beanNames = ctx.getBeanDefinitionNames();
        Arrays.sort(beanNames);
        for (String beanName : beanNames) {
            System.out.println(beanName);
        }
    }
}
{% endhighlight %}