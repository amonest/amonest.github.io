---
layout: post
title: passwd - 修改密码
---

{% highlight shell %}
[root@localhost ~]# passwd --help
Usage: passwd [OPTION...] <accountName>
  -k, --keep-tokens       keep non-expired authentication tokens
  -d, --delete            delete the password for the named account (root only)
  -l, --lock              lock the password for the named account (root only)
  -u, --unlock            unlock the password for the named account (root only)
  -e, --expire            expire the password for the named account (root only)
  -f, --force             force operation
  -x, --maximum=DAYS      maximum password lifetime (root only)
  -n, --minimum=DAYS      minimum password lifetime (root only)
  -w, --warning=DAYS      number of days warning users receives before password expiration (root only)
  -i, --inactive=DAYS     number of days after password expiration when an account becomes disabled (root
                          only)
  -S, --status            report password status on the named account (root only)
  --stdin                 read new tokens from stdin (root only)

Help options:
  -?, --help              Show this help message
  --usage                 Display brief usage message
{% endhighlight %}

---

修改用户 **wangxm** 的密码为 **123456**：

{% highlight shell %}
[root@localhost ~]# echo "123456" | passwd --stdin wangxm
{% endhighlight %}