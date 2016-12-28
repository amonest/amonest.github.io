---
layout: post
title: 发布war
---

[1] 参考[《Converting a Spring Boot JAR Application to a WAR》](http://spring.io/guides/gs/convert-jar-to-war/)。

---

[2] pom.xml：

{% highlight xml %}
<packaging>war</packaging>

<dependencies>
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-web</artifactId>
    </dependency>

    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-tomcat</artifactId>
        <scope>provided</scope>
    </dependency>
</dependencies>
{% endhighlight %}

---

[3] src/main/java/net/mingyang/spring_boot_test/Application.java：

{% highlight java %}
@SpringBootApplication
public class Application extends SpringBootServletInitializer
{
    public static void main(String[] args) {
      SpringApplication.run(Application.class, args);
    }
  
    @Override
    protected SpringApplicationBuilder configure(SpringApplicationBuilder application) {
      return application.sources(Application.class);
    }
}
{% endhighlight %}

---

[4] Deploy:

{% highlight shell %}
X:\dev\spring-boot-test> mvn package
{% endhighlight %}