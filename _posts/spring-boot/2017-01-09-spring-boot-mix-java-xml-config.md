---
layout: post
title: Spring Boot - 混合Java和XML配置
---

使用 **@ImportResource** 注解，可以混合 Java 和 XML 配置。

---

[1] src/main/java/net/mingyang/spring_boot_test/TestService.java：

{% highlight java %}
package net.mingyang.spring_boot_test;

public class TestService {
    private String text;

    public String getText() {
        return text;
    }

    public void setText(String text) {
        this.text = text;
    }

    @Override
    public String toString() {
        StringBuilder builder = new StringBuilder();
        builder.append("TestService [text=");
        builder.append(text);
        builder.append("]");
        return builder.toString();
    }
}
{% endhighlight %}

---

[2] src/main/java/net/mingyang/spring_boot_test/Application.java：

{% highlight java %}
package net.mingyang.spring_boot_test;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.ApplicationContext;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.ImportResource;

@SpringBootApplication
@ImportResource(value = { "classpath:testService.xml" })
public class Application {
    
    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }
    
    @Bean
    public CommandLineRunner runner() {
        return new CommandLineRunner() {
            @Autowired
            ApplicationContext ctx;
            
            public void run(String... args) throws Exception {
                TestService testService = ctx.getBean(TestService.class);
                System.out.println(testService);
            }
        };
    }
}
{% endhighlight %}

---

[3] src/main/resources/testService.xml：

{% highlight xml %}
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
    xmlns:context="http://www.springframework.org/schema/context"
    xsi:schemaLocation="
        http://www.springframework.org/schema/beans 
        http://www.springframework.org/schema/beans/spring-beans.xsd 
        http://www.springframework.org/schema/context 
        http://www.springframework.org/schema/context/spring-context.xsd">
    
    <bean class="net.mingyang.spring_boot_test.TestService">
        <property name="text" value="Hello World" />
    </bean>
    
</beans>
{% endhighlight %}