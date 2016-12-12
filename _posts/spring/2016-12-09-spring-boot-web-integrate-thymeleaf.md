---
layout: post
title: Spring Boot Web：集成Thymeleaf
---

[1] 参考[《Serving Web Content with Spring MVC》](https://spring.io/guides/gs/serving-web-content/)。

---

[2] 执行[《创建Web项目》](/2016/12/09/spring-boot-web-create-project)。

---

[3] 修改pom.xml。

{% highlight xml %}
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-thymeleaf</artifactId>
</dependency>
{% endhighlight %}

---

[4] 修改SimpleController.java。

{% highlight java %}
@Controller
public class SimpleController {

    @RequestMapping(value ="/hello", method = RequestMethod.GET)
    public String hello(Model model) {
        model.addAttribute("name", "mingyang");
        return "hello";
    }
}
{% endhighlight %}

---

[5] 创建模板src/resources/templates/hello.html。

Spring Boot默认模板目录是classpath:/templates，所以模板文件可以放在src/main/resources/templates或src/main/java/templates。

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

[6] 启动应用程序，访问http://localhost:8080/hello，测试是否成功。

![spring-boot-web-integrate-thymeleaf](/assets/img/posts/spring-boot-web-integrate-thymeleaf.png)