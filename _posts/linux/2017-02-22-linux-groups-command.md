---
layout: post
title: 查询用户所属的群组
---

groups：查询用户所属的群组。

{% highlight shell %}
[root@localhost ~]# groups 
Usage: groups [OPTION]... [USERNAME]...
Print group memberships for each USERNAME or, if no USERNAME is specified, for
the current process (which may differ if the groups database has changed).
      --help     display this help and exit
      --version  output version information and exit
{% endhighlight %}

---

查询指定用户所属的群组：

{% highlight shell %}
[root@localhost ~]# groups root
root: root
{% endhighlight %}

---

查询当前用户所属的群组：

{% highlight shell %}
[root@localhost ~]# groups
root: root
{% endhighlight %}