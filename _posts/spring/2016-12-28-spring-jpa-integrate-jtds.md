---
layout: post
title: 集成jTDS
---

[1] 参考[《JdbcTemplate》](/2016/12/28/spring-jpa-jdbc-template)。

---

[2] pom.xml：

{% highlight xml %}
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-jdbc</artifactId>
</dependency>
         
<dependency>
    <groupId>net.sourceforge.jtds</groupId>
    <artifactId>jtds</artifactId>
    <scope>runtime</scope>
</dependency>
{% endhighlight %}

---

[3] src/main/resources/application.properties:

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

[4] Run:

{% highlight shell %}
X:\dev\spring-boot-test> mvn spring-boot:run
Student [id=1, name=张三, score=95.0]
Student [id=2, name=李四, score=90.0]
Student [id=3, name=王五, score=100.0]
{% endhighlight %}