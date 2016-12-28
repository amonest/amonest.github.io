---
layout: post
title: 创建Maven项目
---


[1] 参考[《Inheriting the starter parent》](http://docs.spring.io/spring-boot/docs/current/reference/htmlsingle/#using-boot-maven-parent-pom)。

---

[2] 参考[《创建新项目》](/2016/12/28/maven-create-project)。

---

[3] 创建项目：

{% highlight shell %}
X:\dev> mvn archetype:generate -DgroupId=net.mingyang ^
            -DartifactId=spring-boot-config ^
            -DarchetypeArtifactId=maven-archetype-quickstart ^
            -DinteractiveMode=false ^
            -DarchetypeCatalog=local
{% endhighlight %}

---

[4] pom.xml:


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

[5] src/main/java/net/mingyang/spring_boot_config/Application.java：

{% highlight java %}
package net.mingyang.spring_boot_config;

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
    
    @Bean
    public ApplicationRunner runner() {
        return new ApplicationRunner() {
            public void run(ApplicationArguments args) throws Exception {
                System.out.println("Hello, Spring!");
            }
        };
    } 
}
{% endhighlight %}

---

[6] Run:

{% highlight shell %}
X:\dev\spring-boot-config> mvn spring-boot:run
Hello, Spring!
{% endhighlight %}