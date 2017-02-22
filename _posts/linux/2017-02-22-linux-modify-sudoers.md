---
layout: post
title: 修改sudoers
---

[1] 切换至root用户，使用visudo命令修改/etc/sudoers。

{% highlight shell %}
[root@localhost ~]# visudo
{% endhighlight %}

---

[2] 添加需要的用户：

{% highlight shell %}
xxx ALL=(ALL) ALL
{% endhighlight %}

如果不想每次都输入密码，可以使用NOPASSWD。 

{% highlight shell %}
xxx ALL=(ALL) NOPASSWD: ALL
{% endhighlight %}

---

[3] /etc/sudoers有设置wheel群组的用户可以执行所有命令，所以将用户加到wheel群组也是可以的。

{% highlight shell %}
## Allows people in group wheel to run all commands
%wheel  ALL=(ALL)       ALL

## Same thing without a password
# %wheel        ALL=(ALL)       NOPASSWD: ALL
{% endhighlight %}

将用户加到wheel群组：

{% highlight shell %}
[root@localhost ~]# usermod -a -G wheel admin

[root@localhost ~]# groups admin
admin : admin wheel
{% endhighlight %}

