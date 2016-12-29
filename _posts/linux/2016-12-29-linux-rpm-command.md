---
layout: post
title: RPM命令
---

查询某个软件包是否已安装：

{% highlight shell %}
[root@localhost ~]# rpm -q httpd
httpd-2.4.6-45.el7.centos.x86_64
{% endhighlight %}

---

查询所有已安装软件包：

{% highlight shell %}
# -a, --all                        query/verify all packages

[root@localhost ~]# rpm -qa | grep httpd
httpd-tools-2.4.6-45.el7.centos.x86_64
httpd-2.4.6-45.el7.centos.x86_64
{% endhighlight %}

---

查询某个已安装软件包信息：

{% highlight shell %}
[root@localhost ~]# rpm -qi httpd
Name        : httpd
Version     : 2.4.6
Release     : 45.el7.centos
Architecture: x86_64
Install Date: Thu 29 Dec 2016 02:30:33 PM HKT
Group       : System Environment/Daemons
Size        : 9807149
License     : ASL 2.0
Signature   : RSA/SHA256, Mon 21 Nov 2016 02:14:03 AM HKT, Key ID 24c6a8a7f4a80eb5
Source RPM  : httpd-2.4.6-45.el7.centos.src.rpm
Build Date  : Tue 15 Nov 2016 02:06:40 AM HKT
Build Host  : c1bm.rdu2.centos.org
Relocations : (not relocatable)
Packager    : CentOS BuildSystem <http://bugs.centos.org>
Vendor      : CentOS
URL         : http://httpd.apache.org/
Summary     : Apache HTTP Server
Description :
The Apache HTTP Server is a powerful, efficient, and extensible web server.
{% endhighlight %}

---

查询某个已安装软件包里面的所有文件：

{% highlight shell %}
# -l, --list                       list files in package

[root@localhost ~]# rpm -ql httpd
{% endhighlight %}

---

查询某个已安装软件包里面的所有配置：

{% highlight shell %}
# -c, --configfiles                list all configuration files

[root@localhost ~]# rpm -qc httpd
{% endhighlight %}

---

查询某个已安装软件包里面的所有文档：

{% highlight shell %}
# -d, --docfiles                   list all documentation files

[root@localhost ~]# rpm -qd httpd
{% endhighlight %}
---

查询某个文件属于哪个软件包：

{% highlight shell %}
# -f, --file                       query/verify package(s) owning file

[root@localhost ~]# rpm -qf /etc/httpd/conf/httpd.conf 
httpd-2.4.6-45.el7.centos.x86_64
{% endhighlight %}

---

删除某个已安装软件包：

{% highlight shell %}
# -e, --erase=<package>+           erase (uninstall) package

[root@localhost ~]# rpm -evh httpd
{% endhighlight %}

---

安装某个RPM软件包：

{% highlight shell %}
# -i, --install                    install package(s)
# -v, --verbose                    provide more detailed output
# -h, --hash                       print hash marks as package installs (good with -v)

[root@localhost ~]# rpm -ivh rsh-0.17-29.rpm
{% endhighlight %}

---

测试某个RPM软件包：

{% highlight shell %}
# --test                           don't install, but tell if it would work or not

[root@localhost ~]# rpm -ivh --test rsh-0.17-29.rpm
{% endhighlight %}

---

查询某个RPM软件包：

{% highlight shell %}
#  -p, --package                    query/verify a package file

[root@localhost ~]# rpm -qpi httpd-2.4.6-45.el7.centos.x86_64.rpm

[root@localhost ~]# rpm -qpl httpd-2.4.6-45.el7.centos.x86_64.rpm

[root@localhost ~]# rpm -qpd httpd-2.4.6-45.el7.centos.x86_64.rpm

[root@localhost ~]# rpm -qpc httpd-2.4.6-45.el7.centos.x86_64.rpm
{% endhighlight %}
