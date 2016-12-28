---
layout: post
title: 应用参数
---

通过 **org.springframework.boot.ApplicationArguments** 可以访问 **SpringApplication.run(...)** 参数。

---

[1] [《创建Maven项目》](/2016/12/28/spring-boot-create-maven-project)

---

[2] src/main/java/net/mingyang/spring_boot_config/Application.java：

{% highlight java %}
package net.mingyang.spring_boot_config;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.stereotype.Component;

@SpringBootApplication
public class Application {
    
    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }
    
    @Component
    static class MyBean {
        @Autowired
        public MyBean(ApplicationArguments args) {
            for (String arg : args.getSourceArgs()) {
                System.out.println("Source: " + arg);
            }
            for (String arg : args.getOptionNames()) {
                System.out.println("Option: " + arg + "=" + args.getOptionValues(arg));
            }
            for (String arg : args.getNonOptionArgs()) {
                System.out.println("NonOption: " + arg);
            }
        }
    }
}
{% endhighlight %}

---

[3] Package:

{% highlight shell %}
X:\dev\spring-boot-config> mvn package
{% endhighlight %}

---

[4] Run:

{% highlight shell %}
X:\dev\spring-boot-config> java -jar target\spring-boot-config-0.0.1-SNAPSHOT.jar foo bar --name=suifeng --age=30 --sex=men
Source: foo
Source: bar
Source: --name=suifeng
Source: --age=30
Source: --sex=men
Option: sex=[men]
Option: name=[suifeng]
Option: age=[30]
NonOption: foo
NonOption: bar
{% endhighlight %}