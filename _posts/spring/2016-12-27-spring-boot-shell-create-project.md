---
layout: post
title: 创建Shell
---

[1] 创建Maven项目。

---

[2] pom.xml：

{% highlight xml %}
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>

  <groupId>net.mingyang</groupId>
  <artifactId>spring-boot-remote-shell</artifactId>
  <version>0.0.1-SNAPSHOT</version>
  <packaging>jar</packaging>

  <name>spring-boot-remote-shell</name>
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
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-remote-shell</artifactId>
    </dependency>
  </dependencies>
</project>
{% endhighlight %}

---

[3] src/main/java/net/mingyang/spring_boot_remote_shell/Application.java：

{% highlight java %}
package net.mingyang.spring_boot_remote_shell;

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

[4] Run:

{% highlight shell %}
D:\dev\spring-boot-remote-shell> mvn spring-boot:run
  .   ____          _            __ _ _
 /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
 \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
  '  |____| .__|_| |_|_| |_\__, | / / / /
 =========|_|==============|___/=/_/_/_/
 :: Spring Boot ::        (v1.4.1.RELEASE)

2016-12-27 15:58:15.153  INFO 221096 --- [           main] n.m.s.Application                        : Starting Application on C60602111 with PID 221096 (X:\dev\spring-test-suite\spring-boot-remote-shell\target\classes started by lbin in X:\dev\spring-test-suite\spring-boot-remote-shell)
2016-12-27 15:58:15.157  INFO 221096 --- [           main] n.m.s.Application                        : No active profile set, falling back to default profiles: default
2016-12-27 15:58:15.362  INFO 221096 --- [           main] s.c.a.AnnotationConfigApplicationContext : Refreshing org.springframework.context.annotation.AnnotationConfigApplicationContext@6ba947ac: startup date [Tue Dec 27 15:58:15 CST 2016]; root of context hierarchy
2016-12-27 15:58:16.332  INFO 221096 --- [           main] roperties$SimpleAuthenticationProperties : 

Using default password for shell access: 3c363289-f1f2-446d-9250-bde3392d375a

2016-12-27 15:58:17.430  INFO 221096 --- [           main] o.s.j.e.a.AnnotationMBeanExporter        : Registering beans for JMX exposure on startup
2016-12-27 15:58:17.435  INFO 221096 --- [           main] o.s.c.support.DefaultLifecycleProcessor  : Starting beans in phase 0
2016-12-27 15:58:17.508  INFO 221096 --- [           main] n.m.s.Application  
{% endhighlight %}

Spring Remote Shell登录信息：
+ Port: 2000
+ Account: user
+ Password: 上面执行过程中的default password

---

[5] SecureCRT登录:

![spring-boot-shell-securecrt-login](/assets/img/posts/spring-boot-shell-securecrt-login.png)

![spring-boot-shell-securecrt-main](/assets/img/posts/spring-boot-shell-securecrt-main.png)