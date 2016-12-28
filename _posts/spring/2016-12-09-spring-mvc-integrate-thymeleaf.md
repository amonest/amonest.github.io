---
layout: post
title: 集成Thymeleaf
---

[1] 参考[《Serving Web Content with Spring MVC》](https://spring.io/guides/gs/serving-web-content/)。

---

[2] [《创建Web项目》](/2016/12/09/spring-mvc-web-controller)。

---

[3] 修改pom.xml。

{% highlight xml %}
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-web</artifactId>
</dependency>

<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-thymeleaf</artifactId>
</dependency>
{% endhighlight %}

---

[4] src/main/java/net/mingyang/spring_boot_test/HelloController.java：

{% highlight java %}
package net.mingyang.spring_boot_test;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;

@Controller
public class HelloController {
    
    @RequestMapping(value ="/hello", method = RequestMethod.GET)
    public String hello(Model model) {
        model.addAttribute("name", "mingyang");
        return "hello";
    }
}
{% endhighlight %}

---

[5] src/resources/templates/hello.html。

{% highlight html %}
<!DOCTYPE HTML>
<html xmlns:th="http://www.thymeleaf.org">
<head>
    <title>Getting Started: Serving Web Content</title>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
</head>
<body>
    <p th:text="'Hello, ' + ${name} + '!'" />
</body>
</html>
{% endhighlight %}

---

[6] src/main/java/net/mingyang/spring_boot_test/Application.java：

{% highlight java %}
package net.mingyang.spring_boot_test;

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

[7] Run:

{% highlight shell %}
X:\dev\spring-boot-test> mvn spring-boot:run
{% endhighlight %}

---

[8] Test:

![spring-boot-web-integrate-thymeleaf](/assets/img/posts/spring-boot-web-integrate-thymeleaf.png)