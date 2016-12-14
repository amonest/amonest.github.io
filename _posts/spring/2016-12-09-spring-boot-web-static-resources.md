---
layout: post
title: Spring Boot Web：静态资源
---

[1] 增加src/main/resources/static目录。

---

[2] 将静态资源复制到static目录。以bootstrap为例：

![spring-boot-web-static-resources](/assets/img/posts/spring-boot-web-static-resources.png)

---

[3] 修改模板，引用静态资源。

{% highlight html %}
<!DOCTYPE HTML>
<html xmlns:th="http://www.thymeleaf.org">
<head>
    <title>Getting Started: Serving Web Content</title>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <link rel="stylesheet" href="/bootstrap/css/bootstrap.min.css" />
</head>
<body>

    <br />
    <br />

    <div class="btn-group">
        <button type="button" class="btn btn-default">Left</button>
        <button type="button" class="btn btn-default">Middle</button>
        <button type="button" class="btn btn-default">Right</button>
    </div>

</body>
</html>
{% endhighlight %}

---

[4] 启动应用程序，访问http://localhost:8080/hello，测试是否成功。

![spring-boot-web-static-resources-html](/assets/img/posts/spring-boot-web-static-resources-html.png)