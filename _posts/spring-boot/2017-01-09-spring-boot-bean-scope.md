---
layout: post
title: Spring Boot - Bean的作用域范围
---

Spring容器最初提供了两种Bean的scope类型：singleton和prototype。但发布2.0以后，又引入了另外三种scope类型：request、session和global session，这三种只能在Web应用中才可以使用。
 
- **singleton**: Spring容器只会创建该Bean定义的唯一实例，这个实例会被保存到缓存中，并且对该Bean的所有后续请求和引用都将返回该缓存中的对象实例，一般情况下，无状态的Bean使用该scope。
 
- **prototype**：每次对该bean的请求都会创建一个新的实例，一般情况下，有状态的bean使用该scope。
 
- **request**：每次http请求将会有各自的bean实例，类似于prototype。
 
- **session**：在一个http session中，一个bean定义对应一个bean实例。
 
- **global session**：在一个全局的http session中，一个bean定义对应一个bean实例。典型情况下，仅在使用portlet context的时候有效。

---

***Spring的默认scope是singleton。***

---

{% highlight java %}
package net.mingyang.spring_boot_test;

import java.util.Arrays;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.ApplicationContext;
import org.springframework.context.annotation.Scope;
import org.springframework.stereotype.Component;
import org.springframework.stereotype.Service;

@SpringBootApplication
public class Application {
    
    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }
    
    @Component
    static class Runner implements ApplicationRunner {  
        @Autowired
        private ApplicationContext ctx;

        public void run(ApplicationArguments args) throws Exception {
            FooService f1 = ctx.getBean(FooService.class);
            FooService f2 = ctx.getBean(FooService.class);
            System.out.println("f1 == f2 ? " + f1.equals(f2));
            
            BarService b1 = ctx.getBean(BarService.class);
            BarService b2 = ctx.getBean(BarService.class);
            System.out.println("b1 == b2 ? " + b1.equals(b2));
        }  
    }
    
    @Service
    @Scope("singleton")
    static class FooService {
        public void hello() {
            System.out.print("I am FooService");
        }
    }
    
    @Service
    @Scope("prototype")
    static class BarService {
        public void hello() {
            System.out.print("I am BarService");
        }
    }
}
{% endhighlight %}

---

执行结果：

{% highlight shell %}
f1 == f2 ? true
b1 == b2 ? false
{% endhighlight %}