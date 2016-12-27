---
layout: post
title: 定制登录用户
---

[1] 参考[《Connecting to the remote shell》](http://docs.spring.io/spring-boot/docs/current/reference/html/production-ready-remote-shell.html)。

---

[2] src/main/resources/application.properties:

{% highlight ini %}
management.shell.auth.simple.user.name=admin
management.shell.auth.simple.user.password=admin
{% endhighlight %}
