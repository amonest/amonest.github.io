---
layout: post
title: 实例(config)
---

[1] 创建项目cloth-config

---

[2] pom.xml：

{% highlight xml %}
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>net.mingyang</groupId>
    <artifactId>cloud-config</artifactId>
    <version>0.0.1-SNAPSHOT</version>
    <packaging>jar</packaging>

    <name>cloud-config</name>
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
            <artifactId>spring-cloud-starter-eureka</artifactId>
        </dependency>

        <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-config-server</artifactId>
        </dependency>
    </dependencies>
</project>
{% endhighlight %}

---

[3] src/main/java/net/mingyang/cloud_config/Application.java：

{% highlight java %}
package net.mingyang.cloud_config;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.config.server.EnableConfigServer;
import org.springframework.cloud.netflix.eureka.EnableEurekaClient;

@SpringBootApplication
@EnableEurekaClient
@EnableConfigServer
public class Application 
{
    public static void main( String[] args ) {
        SpringApplication.run(Application.class, args);
    }
}
{% endhighlight %}

使用 **@EnableEurekaClient** 开启 Eureka Client 支持。

使用 **@EnableConfigServer** 开启 Config Server 支持。

---

[5] src/main/resources/bootstrap.properties：

{% highlight properties %}
spring.application.name=cloud-config    #在Eureka Server注册的名称
eureka.client.serviceUrl.defaultZone=http://localhost:8761/eureka/

spring.profiles.active=native           #Config Server使用本地配置，默认为git配置
spring.cloud.config.server.native.searchLocations=classpath:config  #本地配置路径
{% endhighlight %}

---

[4] src/main/resources/application.properties：

{% highlight properties %}
server.port=8762
{% endhighlight %}

---

[5] src/main/resources/config/cloud-student.properties：

{% highlight properties %}
spring.datasource.url=jdbc:mysql://10.3.1.90:3306/test
spring.datasource.username=root
spring.datasource.password=
spring.datasource.driverClassName=com.mysql.jdbc.Driver
welcome.message=hello, student.
{% endhighlight %}

---

[6] src/main/resources/config/cloud-student-dev.properties：

{% highlight properties %}
welcome.message=hello, student(dev).
{% endhighlight %}

---

[7] Run

{% highlight shell %}
X:\dev\cloud-config> mvn spring-boot:run
{% endhighlight %}

---

[8] Test


获取Config Server上的配置信息遵循如下规则：<br />
/{application}/{profile}[/{label}] <br />
/{application}-{profile}.yml <br />
/{label}/{application}-{profile}.yml <br />
/{application}-{profile}.properties <br />
/{label}/{application}-{profile}.properties <br />


application：表示应用名称,在Config Client中通过spring.config.name配置

profile: 表示获取指定环境下配置，例如开发环境、测试环境、生产环境。默认值default，实际开发中可以是 dev、test、demo、production等

label: git标签，默认值master

如果application名称为foo，则可以采用如下方式访问： <br />
http://localhost:8762/foo/default <br />
http://localhost:8762/foo/development <br />