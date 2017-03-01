---
layout: post
title: 安装Docker Compose
---

Gibhub: <https://github.com/docker/compose>

Docker Compose: <https://docs.docker.com/compose/>

Install Docker Compose: <https://docs.docker.com/compose/install/>

DaoClout: <http://get.daocloud.io/> #国内Docker镜像

{% highlight shell %}
$ curl -L "https://github.com/docker/compose/releases/download/1.11.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

$ chmod +x /usr/local/bin/docker-compose

$ docker-compose --version
{% endhighlight %}