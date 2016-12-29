---
layout: post
title: 主机名称
---

在CentOS或RHEL中，有三种定义的主机名:**静态的（static）**，**瞬态的（transient）**，以及**灵活的（pretty）**。

“**静态**”主机名也称为内核主机名，是系统在启动时从 **/etc/hostname** 自动初始化的主机名。

“**瞬态**”主机名是在系统运行时临时分配的主机名，例如，通过DHCP或mDNS服务器分配。

静态主机名和瞬态主机名都遵从作为互联网域名同样的字符限制规则。

而另一方面，“**灵活**”主机名则允许使用自由形式（包括特殊/空白字符）的主机名，以展示给终端用户（如Dan's Computer）。

---

查询主机名：

{% highlight shell %}
[root@localhost ~]# hostnamectl status
   Static hostname: localhost.localdomain
         Icon name: computer-vm
           Chassis: vm
        Machine ID: 28708a3a314b4954a948fd1d9e8b1f3a
           Boot ID: d7c939b1ff1840b7aa0cc3af141fc360
    Virtualization: vmware
  Operating System: CentOS Linux 7 (Core)
       CPE OS Name: cpe:/o:centos:centos:7
            Kernel: Linux 3.10.0-327.el7.x86_64
      Architecture: x86-64
{% endhighlight %}

---

同时修改所有三个主机名：静态、瞬态和灵活主机名：

{% highlight shell %}
[root@localhost ~]# hostnamectl set-hostname "Dan’s Computer"
{% endhighlight %}

修改的主机名，带有任何的特殊字符或空白字符都将会被移除，并且提供的参数中任何大写字母都会自动转化成小写。

如果你只想修改特定的主机名（静态，瞬态或灵活），你可以使用“--static”，“--transient”或“--pretty”选项。

一旦修改了静态主机名，**/etc/hostname** 将被自动更新。然而，**/etc/hosts** 不会更新以保存所做的修改，所以你需要手动更新**/etc/hosts**。

注意，你不必重启机器以激活永久主机名修改。上面的命令会立即修改内核主机名。注销并重新登入后在命令行提示来观察新的静态主机名。

---

查看静态、瞬态或灵活主机名，分别使用“**--static**”，“**--transient**”或“**--pretty**”选项：

{% highlight shell %}
[root@localhost etc]# hostnamectl status --static
danscomputer
[root@localhost etc]# hostnamectl status --transient
danscomputer
[root@localhost etc]# hostnamectl status --pretty
Dan’s Computer
{% endhighlight %}