---
layout: post
title: 阿里云EPEL
---

阿里云EPEL：[http://mirrors.aliyun.com/](http://mirrors.aliyun.com/)

---

[1] 备份。

{% highlight shell %}
[root@localhost ~]# mv /etc/yum.repos.d/epel.repo /etc/yum.repos.d/epel.repo.backup
{% endhighlight %}

---

[2] 下载新repo 到/etc/yum.repos.d/。

CentOS 5：

{% highlight shell %}
[root@localhost ~]# wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-5.repo
{% endhighlight %}

CentOS 6：

{% highlight shell %}
[root@localhost ~]# wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-6.repo
{% endhighlight %}

CentOS 7：

{% highlight shell %}
[root@localhost ~]# wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
{% endhighlight %}

---

[3] 运行yum makecache生成缓存。

{% highlight shell %}
[root@localhost ~]# yum clean all
[root@localhost ~]# yum makecache
{% endhighlight %}