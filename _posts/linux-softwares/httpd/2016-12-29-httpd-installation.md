---
layout: post
title: 安装Httpd
---

[1] 安装Httpd：

{% highlight shell %}
[root@localhost ~]# yum install httpd
{% endhighlight %}

配置目录是 **/etc/httpd**，文档目录是 **/var/www/html**。

---

[2] 创建欢迎文件：

{% highlight shell %}
[root@localhost ~]# vi /var/www/html/index.html
<html>
<body>
Test Page
</body>
</html>
{% endhighlight %}

---

[3] 配置防火墙。

{% highlight shell %}
[root@localhost ~]# firewall-cmd --add-service=http --permanent

[root@localhost ~]# firewall-cmd --reload
{% endhighlight %}

---

[4] 关闭SELinux。

{% highlight shell %}
[root@localhost ~]# setenforce 0
{% endhighlight %}

---


[5] 启动服务。

{% highlight shell %}
[root@localhost ~]# systemctl enable httpd.service

[root@localhost ~]# systemctl start httpd.service
{% endhighlight %}


[6] 客户端测试。

{% highlight shell %}
[root@localhost ~]# curl http://localhost/index.html
<html>
<body>
Test Page
</body>
</html>
{% endhighlight %}