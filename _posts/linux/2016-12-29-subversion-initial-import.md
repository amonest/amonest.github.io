---
layout: post
title: 初始化SVN仓库
---

使用 **mkdir** 创建目录：

{% highlight shell %}
[root@localhost ~]# svn mkdir file:///var/svn/spring-hello-world/trunk -m "create"

[root@localhost ~]# svn mkdir file:///var/svn/spring-hello-world/branches -m "create"

[root@localhost ~]# svn mkdir file:///var/svn/spring-hello-world/tags -m "create"
{% endhighlight %}

---

也可以使用 **import** 导入现有项目：

{% highlight shell %}
[root@localhost ~]# svn import /home/project file:///var/svn/spring-hello-world/trunk -m "initial import" 
{% endhighlight %}

---

查询仓库结构：

{% highlight shell %}
[root@localhost ~]# svn list file:///var/svn/spring-hello-world/
branches/
tags/
trunk/
{% endhighlight %}