---
layout: post
title: "@Scheduled"
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

import java.text.SimpleDateFormat;
import java.util.Date;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.scheduling.annotation.Scheduled;

@SpringBootApplication
@EnableScheduling
public class Application {
    
    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }
    
    @Scheduled(fixedRate = 5000)
    public void reportCurrentTime() {
        SimpleDateFormat sdf = new SimpleDateFormat("HH:mm:ss");
        System.out.println("Current Time: " + sdf.format(new Date()));
    }
}
{% endhighlight %}

---

[4] Run:

{% highlight shell %}
D:\dev\spring-boot-config> mvn spring-boot:run
Current Time: 14:02:53
Current Time: 14:02:58
Current Time: 14:03:03
Current Time: 14:03:08
Current Time: 14:03:13
Current Time: 14:03:18
Current Time: 14:03:23
{% endhighlight %}