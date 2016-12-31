---
layout: post
title: useradd - 新建用户
---

{% highlight shell %}
[root@localhost ~]# useradd --help
Usage: useradd [options] LOGIN
       useradd -D
       useradd -D [options]

Options:
  -b, --base-dir BASE_DIR       base directory for the home directory of the
                                new account
  -c, --comment COMMENT         GECOS field of the new account
  -d, --home-dir HOME_DIR       home directory of the new account
  -D, --defaults                print or change default useradd configuration
  -e, --expiredate EXPIRE_DATE  expiration date of the new account
  -f, --inactive INACTIVE       password inactivity period of the new account
  -g, --gid GROUP               name or ID of the primary group of the new
                                account
  -G, --groups GROUPS           list of supplementary groups of the new
                                account
  -h, --help                    display this help message and exit
  -k, --skel SKEL_DIR           use this alternative skeleton directory
  -K, --key KEY=VALUE           override /etc/login.defs defaults
  -l, --no-log-init             do not add the user to the lastlog and
                                faillog databases
  -m, --create-home             create the user's home directory
  -M, --no-create-home          do not create the user's home directory
  -N, --no-user-group           do not create a group with the same name as
                                the user
  -o, --non-unique              allow to create users with duplicate
                                (non-unique) UID
  -p, --password PASSWORD       encrypted password of the new account
  -r, --system                  create a system account
  -R, --root CHROOT_DIR         directory to chroot into
  -s, --shell SHELL             login shell of the new account
  -u, --uid UID                 user ID of the new account
  -U, --user-group              create a group with the same name as the user
  -Z, --selinux-user SEUSER     use a specific SEUSER for the SELinux user mapping
{% endhighlight %}

---

新建用户 **wangxm**。Linux会创建同名用户组 **wangxm**，同时创建用户主目录 **/home/wangxm**。

{% highlight shell %}
[root@localhost ~]# useradd wangxm
{% endhighlight %}

---

新建用户 **wangxm**，加入主要组 **manager**，加入次要组 **company,employees**。如果主目录 **/home/wangxm** 已经存在，自动关联。

{% highlight shell %}
[root@localhost ~]# useradd -g manager -G company,employees wangxm
{% endhighlight %}

---

新建用户 **wangxm**，不用创建同名用户组，不用创建主目录。

{% highlight shell %}
[root@localhost ~]# useradd -N -M wangxm
{% endhighlight %}

---

新建用户 **wangxm**，指定主目录 **/home/company**。如果主目录 **/home/wangxm** 不存在，自动创建。

{% highlight shell %}
[root@localhost ~]# useradd -d /home/company wangxm
{% endhighlight %}

---

新建用户 **wangxm**，指定SHELL **/bin/bash**。

{% highlight shell %}
[root@localhost ~]# useradd -s /bin/bash wangxm
{% endhighlight %}

---

新建用户 **wangxm**，指定 **uid** 为 **501**。

{% highlight shell %}
[root@localhost ~]# useradd -u 501 wangxm
{% endhighlight %}