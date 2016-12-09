---
layout: post
title: Spring Boot Web快速创建Web项目
tag : [Spring, Spring Boot]
---

[1] 创建Maven项目。

---

[2] 修改pom.xml。

{% highlight xml %}
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>

  <groupId>net.mingyang</groupId>
  <artifactId>spring-cloth-sample</artifactId>
  <version>0.0.1-SNAPSHOT</version>
  <packaging>jar</packaging>

  <name>spring-cloth-sample</name>
  <url>http://maven.apache.org</url>

  <parent>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-parent</artifactId>
    <version>1.4.1.RELEASE</version>
    <relativePath />
  </parent>

  <properties>
    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    <project.reporting.outputEncoding>UTF-8</project.reporting.outputEncoding>
    <java.version>1.7</java.version>
  </properties>

  <dependencies>
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-web</artifactId>
    </dependency>

    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-test</artifactId>
      <scope>test</scope>
    </dependency>
  </dependencies>

  <build>
    <plugins>
      <plugin>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-maven-plugin</artifactId>
      </plugin>
    </plugins>
  </build>

</project>
{% endhighlight %}

---

[3] 创建Application.java：

{% highlight java %}
package net.mingyang.spring_cloth_sample;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class Application 
{
  public static void main(String[] args) {
    SpringApplication.run(Application.class, args);
  }
}
{% endhighlight %}

---

[4] 创建SimpleController.java：

{% highlight java %}
package net.mingyang.spring_cloth_sample;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.ResponseBody;

@Controller
public class SimpleController {

    @RequestMapping(value ="/hello", method = RequestMethod.GET)
    @ResponseBody
    public String hello() {
        return "hello world";
    }
}
{% endhighlight %}

---

[5] 启动应用程序：

{% highlight shell %}
  .   ____          _            __ _ _
 /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
 \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
  '  |____| .__|_| |_|_| |_\__, | / / / /
 =========|_|==============|___/=/_/_/_/
 :: Spring Boot ::        (v1.4.1.RELEASE)

2016-12-09 08:30:25.900  INFO 97316 --- [           main] n.m.spring_cloth_sample.Application      : Starting Application on C60602111 with PID 97316 (X:\dev\spring-test-suite\spring-cloth-sample\target\classes started by lbin in X:\dev\spring-test-suite\spring-cloth-sample)
2016-12-09 08:30:25.903  INFO 97316 --- [           main] n.m.spring_cloth_sample.Application      : No active profile set, falling back to default profiles: default
2016-12-09 08:30:25.952  INFO 97316 --- [           main] ationConfigEmbeddedWebApplicationContext : Refreshing org.springframework.boot.context.embedded.AnnotationConfigEmbeddedWebApplicationContext@1a43bd4: startup date [Fri Dec 09 08:30:25 CST 2016]; root of context hierarchy
2016-12-09 08:30:27.096  INFO 97316 --- [           main] s.b.c.e.t.TomcatEmbeddedServletContainer : Tomcat initialized with port(s): 8080 (http)
2016-12-09 08:30:27.103  INFO 97316 --- [           main] o.apache.catalina.core.StandardService   : Starting service Tomcat
2016-12-09 08:30:27.104  INFO 97316 --- [           main] org.apache.catalina.core.StandardEngine  : Starting Servlet Engine: Apache Tomcat/8.5.5
2016-12-09 08:30:27.165  INFO 97316 --- [ost-startStop-1] o.a.c.c.C.[Tomcat].[localhost].[/]       : Initializing Spring embedded WebApplicationContext
2016-12-09 08:30:27.165  INFO 97316 --- [ost-startStop-1] o.s.web.context.ContextLoader            : Root WebApplicationContext: initialization completed in 1215 ms
2016-12-09 08:30:27.295  INFO 97316 --- [ost-startStop-1] o.s.b.w.servlet.ServletRegistrationBean  : Mapping servlet: 'dispatcherServlet' to [/]
2016-12-09 08:30:27.298  INFO 97316 --- [ost-startStop-1] o.s.b.w.servlet.FilterRegistrationBean   : Mapping filter: 'characterEncodingFilter' to: [/*]
2016-12-09 08:30:27.298  INFO 97316 --- [ost-startStop-1] o.s.b.w.servlet.FilterRegistrationBean   : Mapping filter: 'hiddenHttpMethodFilter' to: [/*]
2016-12-09 08:30:27.298  INFO 97316 --- [ost-startStop-1] o.s.b.w.servlet.FilterRegistrationBean   : Mapping filter: 'httpPutFormContentFilter' to: [/*]
2016-12-09 08:30:27.299  INFO 97316 --- [ost-startStop-1] o.s.b.w.servlet.FilterRegistrationBean   : Mapping filter: 'requestContextFilter' to: [/*]
2016-12-09 08:30:27.538  INFO 97316 --- [           main] s.w.s.m.m.a.RequestMappingHandlerAdapter : Looking for @ControllerAdvice: org.springframework.boot.context.embedded.AnnotationConfigEmbeddedWebApplicationContext@1a43bd4: startup date [Fri Dec 09 08:30:25 CST 2016]; root of context hierarchy
2016-12-09 08:30:27.594  INFO 97316 --- [           main] s.w.s.m.m.a.RequestMappingHandlerMapping : Mapped "{[/hello],methods=[GET]}" onto public java.lang.String net.mingyang.spring_cloth_sample.SimpleController.hello()
2016-12-09 08:30:27.597  INFO 97316 --- [           main] s.w.s.m.m.a.RequestMappingHandlerMapping : Mapped "{[/error]}" onto public org.springframework.http.ResponseEntity<java.util.Map<java.lang.String, java.lang.Object>> org.springframework.boot.autoconfigure.web.BasicErrorController.error(javax.servlet.http.HttpServletRequest)
2016-12-09 08:30:27.597  INFO 97316 --- [           main] s.w.s.m.m.a.RequestMappingHandlerMapping : Mapped "{[/error],produces=[text/html]}" onto public org.springframework.web.servlet.ModelAndView org.springframework.boot.autoconfigure.web.BasicErrorController.errorHtml(javax.servlet.http.HttpServletRequest,javax.servlet.http.HttpServletResponse)
2016-12-09 08:30:27.627  INFO 97316 --- [           main] o.s.w.s.handler.SimpleUrlHandlerMapping  : Mapped URL path [/webjars/**] onto handler of type [class org.springframework.web.servlet.resource.ResourceHttpRequestHandler]
2016-12-09 08:30:27.627  INFO 97316 --- [           main] o.s.w.s.handler.SimpleUrlHandlerMapping  : Mapped URL path [/**] onto handler of type [class org.springframework.web.servlet.resource.ResourceHttpRequestHandler]
2016-12-09 08:30:27.660  INFO 97316 --- [           main] o.s.w.s.handler.SimpleUrlHandlerMapping  : Mapped URL path [/**/favicon.ico] onto handler of type [class org.springframework.web.servlet.resource.ResourceHttpRequestHandler]
2016-12-09 08:30:27.835  INFO 97316 --- [           main] o.s.j.e.a.AnnotationMBeanExporter        : Registering beans for JMX exposure on startup
2016-12-09 08:30:27.873  INFO 97316 --- [           main] s.b.c.e.t.TomcatEmbeddedServletContainer : Tomcat started on port(s): 8080 (http)
2016-12-09 08:30:27.877  INFO 97316 --- [           main] n.m.spring_cloth_sample.Application      : Started Application in 2.359 seconds (JVM running for 2.59)
{% endhighlight %}

---

[6] 访问http://localhost:8080/hello，测试是否成功。

![spring-boot-web-integrate-thymeleaf](/assets/img/posts/spring-boot-web-integrate-thymeleaf.png)