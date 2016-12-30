---
layout: post
title: 防火墙
---

查询当前Zone：

{% highlight shell %}
[root@localhost ~]# firewall-cmd --list-all
{% endhighlight %}

---

增加服务：

{% highlight shell %}
# --permanent 永久选项，不影响运行时的状态，仅在重载或者重启服务时可用。
# 为了使用运行时和永久设置，需要分别设置两者。

[root@localhost ~]# firewall-cmd --add-service=telnet --permanent
{% endhighlight %}

---

删除服务：

{% highlight shell %}
[root@localhost ~]# firewall-cmd --remove-service=telnet --permanent
{% endhighlight %}

---

增加端口：

{% highlight shell %}
[root@localhost ~]# firewall-cmd --add-port=3306 --permanent
{% endhighlight %}

---

删除端口：

{% highlight shell %}
[root@localhost ~]# firewall-cmd --remove-port=3306 --permanent
{% endhighlight %}

---

重新加载：

{% highlight shell %}
[root@localhost ~]# firewall-cmd --reload
{% endhighlight %}

---