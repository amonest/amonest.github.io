---
layout: post
title: 配置ServletContextListener
---

{% highlight java %}
package net.mingyang.spring_boot_test;

import javax.servlet.ServletContextEvent;
import javax.servlet.ServletContextListener;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.stereotype.Component;

@SpringBootApplication
public class Application {
    
    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }
    
    @Component
    static class TestInitializer implements ServletContextListener {

        @Override
        public void contextInitialized(ServletContextEvent sce) {
            System.out.println("TestInitializer.contextInitialized()");
        }

        @Override
        public void contextDestroyed(ServletContextEvent sce) {
            System.out.println("TestInitializer.contextDestroyed()");
        }
    }
}
{% endhighlight %}