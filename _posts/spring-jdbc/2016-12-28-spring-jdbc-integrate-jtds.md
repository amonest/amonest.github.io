---
layout: post
title: Spring JDBC - 集成jTDS连接SQLServer
---

pom.xml：

{% highlight xml %}
<dependency>
    <groupId>net.sourceforge.jtds</groupId>
    <artifactId>jtds</artifactId>
    <scope>runtime</scope>
</dependency>
{% endhighlight %}

---

application.properties:

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