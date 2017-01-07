---
layout: post
title: Spring Boot - 发布可执行的jar文件
---

使用 **spring-boot-maven-plugin** 插件，可以创建可执行的jar文件。

{% highlight xml %}
<build>
    <plugins>
        <plugin>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-maven-plugin</artifactId>
            <configuration>
                <executable>true</executable>
            </configuration>
        </plugin>
    </plugins>
</build>
{% endhighlight %}