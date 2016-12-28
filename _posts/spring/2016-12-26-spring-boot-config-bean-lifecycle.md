---
layout: post
title: "@PostConstruct、@PreDestroy"
---

@Bean的initMethod在构造之前执行，destroyMethod在销毁之前执行。JSP-250的@PostConstruct和@PreDestroy实现同样功能。

---

[1] 创建Maven项目。

---

[2] pom.xml：

{% highlight xml %}
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>net.mingyang</groupId>
    <artifactId>spring-boot-test</artifactId>
    <version>0.0.1-SNAPSHOT</version>
    <packaging>jar</packaging>

    <name>spring-boot-test</name>
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
        
        <dependency>
            <groupId>javax.annotation</groupId>
            <artifactId>jsr250-api</artifactId>
            <version>1.0</version>
        </dependency>
    </dependencies>
</project>
{% endhighlight %}

---

[3] src/main/java/net/mingyang/spring_boot_test/Application.java：

{% highlight java %}
package net.mingyang.spring_boot_test;

import javax.annotation.PostConstruct;
import javax.annotation.PreDestroy;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.PropertySource;

@SpringBootApplication
public class Application {
    
    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }
    
    @Bean(initMethod="init", destroyMethod="destroy")
    public FooService foo() {
        return new FooService();
    }
    
    @Bean
    public BarService bar() {
        return new BarService();
    }
    
    static class FooService {
        public FooService() {
            System.out.println("FooService.constructor()");
        }

        private void init() {
            System.out.println("FooService.init()");
        }

        private void destroy() {
            System.out.println("FooService.destroy()");
        }
    }
    
    static class BarService {
        public BarService() {
            System.out.println("BarService.constructor()");
        }
        
        @PostConstruct
        private void init() {
            System.out.println("BarService.init()");
        }
        
        @PreDestroy
        private void destroy() {
            System.out.println("BarService.destroy()");
        }
    }
}
{% endhighlight %}