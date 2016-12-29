---
layout: post
title: YUM命令
---

查询软件包是否已安装：

{% highlight shell %}
[root@localhost ~]# yum list installed | grep httpd
httpd.x86_64                          2.4.6-45.el7.centos              @base    
httpd-tools.x86_64                    2.4.6-45.el7.centos              @base    
{% endhighlight %}

---

搜索软件包：

{% highlight shell %}
[root@localhost ~]# yum search httpd
================================================ N/S matched: httpd =================================================
lighttpd-fastcgi.x86_64 : FastCGI module and spawning helper for lighttpd and PHP configuration
lighttpd-mod_authn_gssapi.x86_64 : Authentication module for lighttpd that uses GSSAPI
lighttpd-mod_authn_mysql.x86_64 : Authentication module for lighttpd that uses a MySQL database
lighttpd-mod_geoip.x86_64 : GeoIP module for lighttpd to use for location lookups
lighttpd-mod_mysql_vhost.x86_64 : Virtual host module for lighttpd that uses a MySQL database
httpd.x86_64 : Apache HTTP Server
httpd-devel.x86_64 : Development interfaces for the Apache HTTP server
httpd-itk.x86_64 : MPM Itk for Apache HTTP Server
httpd-manual.noarch : Documentation for the Apache HTTP server
httpd-tools.x86_64 : Tools for use with the Apache HTTP Server
{% endhighlight %}

---

查询软件包：

{% highlight shell %}
[root@localhost ~]# yum info httpd
Loaded plugins: fastestmirror
Loading mirror speeds from cached hostfile
 * base: mirrors.aliyun.com
 * epel: mirrors.aliyun.com
 * extras: mirrors.aliyun.com
 * updates: mirrors.aliyun.com
Available Packages
Name        : httpd
Arch        : x86_64
Version     : 2.4.6
Release     : 45.el7.centos
Size        : 2.7 M
Repo        : base/7/x86_64
Summary     : Apache HTTP Server
URL         : http://httpd.apache.org/
License     : ASL 2.0
Description : The Apache HTTP Server is a powerful, efficient, and extensible
            : web server.
{% endhighlight %}

---

安装或卸载软件包：

{% highlight shell %}
# info           Display details about a package or group of packages
# install        Install a package or packages on your system
# erase          Remove a package or packages from your system
# reinstall      reinstall a package
# upgrade        Update packages taking obsoletes into account
# downgrade      downgrade a package
# update         Update a package or packages on your system

# -y, --assumeyes       answer yes for all questions

[root@localhost ~]# yum [install|erase] -y httpd
{% endhighlight %}

---

下载软件包，但是不安装：

{% highlight shell %}
# --downloadonly        don't update, just download

# 默认下载目录/var/cache/yum
[root@localhost ~]# yum install --downloadonly httpd

[root@localhost ~]# yum install --downloadonly --downloaddir=. httpd
{% endhighlight %}