---
layout: post
title: Spring Boot Web：发布war
---

[1] 参考[《Converting a Spring Boot JAR Application to a WAR》](http://spring.io/guides/gs/convert-jar-to-war/)。

---

[2] 修改pom.xml：

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

[3] 发布war。

{% highlight shell %}
$ mvn package
{% endhighlight %}