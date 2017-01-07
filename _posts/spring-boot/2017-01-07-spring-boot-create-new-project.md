---
layout: post
title: Spring Boot - 创建Spring Boot新项目
---

使用 **@SpringBootApplication** 注解，可以快速的创建 Spring Boot 新项目。

---

[1] pom.xml：

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

[2] src/main/java/net/mingyang/spring_boot_test/Application.java：

{% highlight java %}
package net.mingyang.spring_boot_test;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class Application {
    
    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }
}
{% endhighlight %}

---

[3] Run：

{% highlight shell %}
X:\dev\spring-boot-test> mvn spring-boot:run
  .   ____          _            __ _ _
 /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
 \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
  '  |____| .__|_| |_|_| |_\__, | / / / /
 =========|_|==============|___/=/_/_/_/
 :: Spring Boot ::        (v1.4.1.RELEASE)

2017-01-07 08:59:51.845  INFO 94196 --- [           main] n.mingyang.spring_boot_test.Application  : Starting Application on C60602111 with PID 94196 (X:\dev\spring-boot-test\target\classes started by lbin in X:\dev\spring-boot-test)
2017-01-07 08:59:51.848  INFO 94196 --- [           main] n.mingyang.spring_boot_test.Application  : No active profile set, falling back to default profiles: default
2017-01-07 08:59:51.895  INFO 94196 --- [           main] s.c.a.AnnotationConfigApplicationContext : Refreshing org.springframework.context.annotation.AnnotationConfigApplicationContext@3ce9d642: startup date [Sat Jan 07 08:59:51 CST 2017]; root of context hierarchy
2017-01-07 08:59:52.651  INFO 94196 --- [           main] o.s.j.e.a.AnnotationMBeanExporter        : Registering beans for JMX exposure on startup
2017-01-07 08:59:52.663  INFO 94196 --- [           main] n.mingyang.spring_boot_test.Application  : Started Application in 1.096 seconds (JVM running for 1.395)
2017-01-07 08:59:52.664  INFO 94196 --- [       Thread-1] s.c.a.AnnotationConfigApplicationContext : Closing org.springframework.context.annotation.AnnotationConfigApplicationContext@3ce9d642: startup date [Sat Jan 07 08:59:51 CST 2017]; root of context hierarchy
2017-01-07 08:59:52.665  INFO 94196 --- [       Thread-1] o.s.j.e.a.AnnotationMBeanExporter        : Unregistering JMX-exposed beans on shutdown
{% endhighlight %}