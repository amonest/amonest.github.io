---
layout: post
title: Spring Boot Web集成JSP视图
tag : [Spring, Spring Boot]
---

[1] 执行[《Spring Boot Web快速创建Web项目》](/2016/12/09/spring-boot-web-create-project)。

参考：[《Serving Web Content with Spring MVC》](https://spring.io/guides/gs/serving-web-content/)。

---

[2] 修改pom.xml，增加Thymeleaf依赖。

{% highlight xml %}
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-thymeleaf</artifactId>
</dependency>
{% endhighlight %}

---

[3] 修改SimpleController.java。

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

[4] 创建模板src/resources/templates/hello.html。

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

[5] 启动应用程序。

---

[6] 访问http://localhost:8080/hello，测试是否成功。

![spring-boot-web-integrate-thymeleaf](/assets/img/posts/spring-boot-web-integrate-thymeleaf.png)