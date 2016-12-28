---
layout: post
title: "application-{profile}.properties"
---

Spring Boot支持application-{profile}.properties配置方式。

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
    </dependencies>
</project>
{% endhighlight %}

---

[3] src/main/resources/application-prod.properties:

{% highlight properties %}
server.port=80
{% endhighlight %}

---

[4] src/main/resources/application-dev.properties:

{% highlight properties %}
server.port=8080
{% endhighlight %}

---

[5] src/main/resources/application.properties:

{% highlight properties %}
spring.profiles.active=dev
{% endhighlight %}

---

[6] src/main/java/net/mingyang/spring_boot_test/Application.java：

{% highlight java %}
package net.mingyang.spring_boot_test;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;

@SpringBootApplication
public class Application {
    
    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }
    
    @Value("${server.port}")
    private int serverPort;
    
    @Bean
    public ApplicationRunner runner() {
        return new ApplicationRunner() {
            public void run(ApplicationArguments args) throws Exception {
                System.out.println("Server Port: " + serverPort);
            }
        };
    }
}
{% endhighlight %}

---

[7] Run: 

{% highlight shell %}
D:\dev\spring-boot-test> mvn spring-boot:run
Server Port: 8080
{% endhighlight %}

---

[8] 使用-D可以覆盖application.properties里的设置：

{% highlight shell %}
D:\dev\spring-boot-test> mvn spring-boot:run -Dspring.profiles.active=prod
Server Port: 80
{% endhighlight %}