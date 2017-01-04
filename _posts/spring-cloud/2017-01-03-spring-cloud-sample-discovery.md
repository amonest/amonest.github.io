---
layout: post
title: 实例(discovery)
---



[1] 创建项目cloth-discovery。

---

[2] pom.xml：

{% highlight xml %}
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/maven-v4_0_0.xsd">
    <modelVersion>4.0.0</modelVersion>
    
    <groupId>net.mingyang</groupId>
    <artifactId>cloud-discovery</artifactId>
    <packaging>jar</packaging>
    
    <version>1.0-SNAPSHOT</version>
    <name>cloud-discovery</name>
    <url>http://maven.apache.org</url>
    
    <properties>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    </properties>

    <parent>
        <groupId>org.springframework.cloud</groupId>
        <artifactId>spring-cloud-starter-parent</artifactId>
        <version>Brixton.SR7</version>
    </parent>

    <dependencies>
        <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-starter</artifactId>
        </dependency>
        
        <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-starter-eureka-server</artifactId>
        </dependency>
    </dependencies>
</project>
{% endhighlight %}

---

[3] src/main/java/net/mingyang/cloud_discovery/Application.java：

{% highlight java %}
package net.mingyang.cloud_discovery;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.netflix.eureka.server.EnableEurekaServer;

@SpringBootApplication
@EnableEurekaServer
public class Application 
{
    public static void main( String[] args ) {
        SpringApplication.run(Application.class, args);
    }
}
{% endhighlight %}

通过 **@EnableEurekaServer** 注解启动一个Enreka Server。

---

[4] src/main/resources/application.properties：

{% highlight properties %}
server.port=8761
eureka.instance.hostname=localhost
eureka.client.registerWithEureka=false  #当前服务不需要注册到Eureka Server
eureka.client.fetchRegistry=false       #当前服务不需要获取Config Server配置
{% endhighlight %}

---

[5] Run:

{% highlight shell %}
X:\dev\cloud-discovery> mvn spring-boot:run
{% endhighlight %}

---

[6] Test: http://localhost:8761/

![spring-cloud-sample-discovery](/assets/img/posts/spring-cloud-sample-discovery.png)