---
layout: post
title: Apache Maven - Maven仓库国内镜像
---

使用Maven国内镜像，可以解决构建项目时太慢的问题。

找到maven配置文件，一般是MAVEN_INSTALL/conf/settings.xml，按如下方式修改：

{% highlight xml %}
<settings>
    <mirrors>
        <mirror>
            <id>alimaven</id>
            <name>aliyun maven</name>
            <url>http://maven.aliyun.com/nexus/content/groups/public/</url>
            <mirrorOf>central</mirrorOf>
        </mirror>
    </mirrors>
</settings>
{% endhighlight %}