---
layout: post
title: 安装mod_dav_svn
---

[1] [《安装Httpd》](/2016/12/29/httpd-installation)

---

[2] [《安装Subversion》](/2016/12/29/subversion-installation)

---

[3] 安装mod_dav_svn。

{% highlight shell %}
[root@localhost ~]# yum install mod_dav_svn
{% endhighlight %}

完成后检查一下 **/etc/httpd/modules** 是否包含 **mod_dav_svn.so** 和 **mod_authz_svn.so**。如果有，**mod_dav_svn** 安装成功。

---

[4] LoadModule。

{% highlight shell %}
[root@localhost ~]# cat /etc/httpd/conf.modules.d/10-subversion.conf
LoadModule dav_svn_module     modules/mod_dav_svn.so
LoadModule authz_svn_module   modules/mod_authz_svn.so
LoadModule dontdothat_module  modules/mod_dontdothat.so
{% endhighlight %}

mod_dav_svn安装完成后，会自动创建 **/etc/httpd/conf.modules.d/10-subversion.conf**，加载必需的模块。

---

[5] 配置httpd。

{% highlight shell %}
[root@localhost ~]# vi /etc/httpd/conf.d/subversion.conf 
<Location /svn>                                 #表示svn的访问URL为http://ip/svn
    DAV svn                                     #表示使用mod_dav_svn模块
    SVNParentPath  /var/svn                     #表示http://ip/svn请求时，使用/var/svn路径下相应的内容

    # Authentication: Basic
    AuthName "Subversion repository"            #表示输入用户名和密码时的提示信息
    AuthType Basic                              #认证类型，这里我们使用基本的认证类型
    AuthUserFile /etc/httpd/svn-auth.htpasswd   #表示认证文件的位置

    # Authorization: Authenticated users only
    <LimitExcept GET PROPFIND OPTIONS REPORT>
        Require valid-user
    </LimitExcept>
</Location>
{% endhighlight %}

---

[6] 创建授权文件。

{% highlight shell %}
# -c  Create a new file.
# -m  Force MD5 encryption of the password (default).

[root@localhost ~]# htpasswd -cm /etc/httpd/svn-auth.htpasswd user1
{% endhighlight %}

---

[7] 目录授权。

{% highlight shell %}
[root@localhost ~]# chown -R apache:apache /var/svn/spring-hello-world
{% endhighlight %}

---

[8] 客户端测试。

{% highlight shell %}
[root@localhost ~]# svn checkout http://localhost/svn/spring-hello-world
A    spring-hello-world/tags
A    spring-hello-world/trunk
A    spring-hello-world/trunk/LICENSE.txt
A    spring-hello-world/trunk/index.html
A    spring-hello-world/trunk/README.txt
A    spring-hello-world/branches
Checked out revision 4.

[root@localhost ~]# cd spring-hello-world/trunk

[root@localhost trunk]# vi index.php

[root@localhost trunk]# svn status
M       index.html

[root@localhost trunk]# svn add index.php
A         index.php

[root@localhost trunk]# svn commit --username user1 -m "change index.html"
Sending        index.html
Transmitting file data .
Committed revision 5.
{% endhighlight %}