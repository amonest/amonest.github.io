---
layout: post
title: Spring Boot - 自定义ApplicationEvent
---

使用 **ApplicationEvent** 类和 **ApplicationListener** 接口，可以提供 **ApplicationContext** 的事件处理。

---

[1] src/main/java/net/mingyang/spring_boot_test/MessageApplicationEvent.java:

{% highlight java %}
package net.mingyang.spring_boot_test;

import org.springframework.context.ApplicationEvent;

@SuppressWarnings("serial")
public class MessageApplicationEvent extends ApplicationEvent {
    
    private String message;

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public MessageApplicationEvent(Object source, String message) {
        super(source);
        this.message = message;
    }

    @Override
    public String toString() {
        StringBuilder builder = new StringBuilder();
        builder.append("MessageApplicationEvent [message=");
        builder.append(message);
        builder.append("]");
        return builder.toString();
    }
}
{% endhighlight %}

---

[2] src/main/java/net/mingyang/spring_boot_test/MessageApplicationListener.java:

{% highlight java %}
package net.mingyang.spring_boot_test;

import org.springframework.context.ApplicationListener;
import org.springframework.stereotype.Component;

@Component
public class MessageApplicationListener implements ApplicationListener<MessageApplicationEvent> {

    public void onApplicationEvent(MessageApplicationEvent event) {
        System.out.println(event);
    }
}
{% endhighlight %}

也可以用下面方式，不使用泛型参数：

{% highlight java %}
package net.mingyang.spring_boot_test;

import org.springframework.context.ApplicationEvent;
import org.springframework.context.ApplicationListener;
import org.springframework.stereotype.Component;

@Component
@SuppressWarnings("rawtypes")
public class MessageApplicationListener implements ApplicationListener {

    public void onApplicationEvent(ApplicationEvent event) {
        if (event instanceof MessageApplicationEvent) {
            System.out.println(event);
        }
    }
}
{% endhighlight %}

---

[3] src/main/java/net/mingyang/spring_boot_test/Application.java:

{% highlight java %}
package net.mingyang.spring_boot_test;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.ApplicationContext;
import org.springframework.context.annotation.Bean;

@SpringBootApplication
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
                ctx.publishEvent(new MessageApplicationEvent(Application.this, "hello"));
            }
        };
    }
}
{% endhighlight %}

---

[4] Run:

{% highlight shell %}
X:\dev\spring-boot-test> mvn spring-boot:run
MessageApplicationEvent [message=hello]
{% endhighlight %}