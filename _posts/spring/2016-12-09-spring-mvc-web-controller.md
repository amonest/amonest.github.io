---
layout: post
title: 创建Web项目
---

[1] [《创建Maven项目》](/2016/12/28/spring-boot-create-maven-project)

---

[2] pom.xml：

{% highlight xml %}
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-web</artifactId>
</dependency>
{% endhighlight %}

---

[3] src/main/java/net/mingyang/spring_boot_test/HelloController.java：

{% highlight java %}
package net.mingyang.spring_boot_test;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.ResponseBody;

@Controller
public class HelloController {

    @RequestMapping(value ="/hello", method = RequestMethod.GET)
    @ResponseBody
    public String hello() {
        return "hello world";
    }
}
{% endhighlight %}

---

[4] src/main/java/net/mingyang/spring_boot_test/Application.java：

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

[5] Run:

{% highlight shell %}
X:\dev\spring-boot-test> mvn spring-boot:run
{% endhighlight %}

---

[6] Test:

![spring-boot-web-create-project](/assets/img/posts/spring-boot-web-create-project.png)