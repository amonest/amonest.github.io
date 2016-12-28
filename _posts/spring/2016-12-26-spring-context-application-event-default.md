---
layout: post
title: 应用事件
---

SpringApplication会发送一些应用事件，这些事件是在ApplicationContext被创建前触发的。

在SpringApplication运行时，应用事件会以下面的次序发送：

+ **ApplicationStartedEvent**

+ **ApplicationEnvironmentPreparedEvent**

+ **ApplicationPreparedEvent**

+ **ApplicationReadyEvent**

+ **ApplicationFailedEvent**

通常不需要使用应用程序事件，但知道它们的存在会很方便（在某些场合可能会使用到）。在Spring内部，Spring Boot使用事件处理各种各样的任务

---

[1] [《创建Maven项目》](/2016/12/28/spring-boot-create-maven-project)

---

[2] src/main/java/net/mingyang/spring_boot_config/Application.java：

{% highlight java %}
package net.mingyang.spring_boot_config;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.ApplicationContext;
import org.springframework.context.ApplicationEvent;
import org.springframework.context.ApplicationListener;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.PropertySource;
import org.springframework.stereotype.Component;

@SpringBootApplication
package net.mingyang.spring_boot_config;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.event.ApplicationStartedEvent;
import org.springframework.context.ApplicationListener;

@SpringBootApplication
public class Application {
    
    public static void main(String[] args) {
        SpringApplication application = new SpringApplication(Application.class);
        application.addListeners(new ApplicationStartedEventListener());
        application.run(args);
    }
    
    static class ApplicationStartedEventListener implements ApplicationListener<ApplicationStartedEvent> {
        public void onApplicationEvent(ApplicationStartedEvent event) {
            System.out.println("ApplicationStartedEvent");
        }
    }
}
{% endhighlight %}