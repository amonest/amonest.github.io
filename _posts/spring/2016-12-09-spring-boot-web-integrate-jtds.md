---
layout: post
title: Spring Boot Web：集成jTDS
---

jTDS是一个开放源代码的100%纯Java实现的JDBC3.0驱动，它用于连接 Microsoft SQL Server（6.5，7，2000，2005，2008 和 2012）和Sybase（10 ，11 ，12 ，15）。

---

[1] 执行[《创建Web项目》](/2016/12/09/spring-boot-web-create-project)。

---

[2] 执行[《集成Thymeleaf》](/2016/12/09/spring-boot-web-integrate-thymeleaf)。

---

[3] 参考[《集成JDBC》](/2016/12/09/spring-boot-web-integrate-jdbc)。

---

[4] 修改pom.xml：

{% highlight xml %}
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-jdbc</artifactId>
</dependency>
         
<dependency>
    <groupId>net.sourceforge.jtds</groupId>
    <artifactId>jtds</artifactId>
</dependency>
{% endhighlight %}

---

[5] 修改application.properties。

{% highlight ini %}
spring.datasource.url=jdbc:jtds:sqlserver://10.3.1.44:1433/test
spring.datasource.username=test
spring.datasource.password=test
spring.datasource.driver-class-name=net.sourceforge.jtds.jdbc.Driver
{% endhighlight %}

如果SQLServer有实例需要指定，则需要使用下面格式指定URL：

{% highlight ini %}
spring.datasource.url=jdbc:jtds:sqlserver://10.3.1.44:1433/test;instance=spdb
{% endhighlight %}

---

[6] 参考[《集成JDBC》](/2016/12/09/spring-boot-web-integrate-jdbc)创建Student.java、StudentService.java、StudentController.java和student_list.html。

---

[7] 启动应用程序，访问http://localhost:8080/student，测试是否成功。

![spring-boot-web-integrate-jdbc](/assets/img/posts/spring-boot-web-integrate-jdbc.png)