---
layout: post
title: ApplicationEvent
---

[1] 创建Maven项目。

---

[2] pom.xml：

{% highlight xml %}
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>net.mingyang</groupId>
    <artifactId>spring-boot-config</artifactId>
    <version>0.0.1-SNAPSHOT</version>
    <packaging>jar</packaging>

    <name>spring-boot-config</name>
    <url>http://maven.apache.org</url>

    <properties>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    </properties>

    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>1.4.1.RELEASE</version>
        <relativePath />
    </parent>

    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter</artifactId>
        </dependency>
    </dependencies>
</project>
{% endhighlight %}

---

[3] src/main/java/net/mingyang/spring_boot_config/Application.java：

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
public class Application {
    
    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }
    
    @SuppressWarnings("serial")
    static class DemoEvent extends ApplicationEvent {
        private String msg;
        
        public String getMsg() {
            return msg;
        }
        
        public void setMsg(String msg) {
            this.msg = msg;
        }
        
        public DemoEvent(Object source, String msg) {
            super(source);
            this.msg = msg;
        }

        @Override
        public String toString() {
            StringBuilder builder = new StringBuilder();
            builder.append("DemoEvent [msg=");
            builder.append(msg);
            builder.append(", source=");
            builder.append(source);
            builder.append("]");
            return builder.toString();
        }
    }

    @Component
    static class DemoListener implements ApplicationListener<DemoEvent> {
        public void onApplicationEvent(DemoEvent event) {
            System.out.println(event);
        }
    }
    
    @Component
    static class DemoPublisher {
        @Autowired
        private ApplicationContext ctx;
        
        public void publish(String msg) {
            ctx.publishEvent(new DemoEvent(this, msg));
        }
    }
    
    @Bean
    public ApplicationRunner runner() {
        return new ApplicationRunner() {
            @Autowired
            private ApplicationContext ctx;
            
            public void run(ApplicationArguments args) throws Exception {
                DemoPublisher demoPublisher = ctx.getBean(DemoPublisher.class);
                demoPublisher.publish("hello");
            }
        };
    }  
}
{% endhighlight %}

---

[4] Run:

{% highlight shell %}
D:\dev\spring-boot-config> mvn spring-boot:run
DemoEvent [msg=hello, source=net.mingyang.spring_boot_config.Application$DemoPublisher@6caa5e85]
{% endhighlight %}