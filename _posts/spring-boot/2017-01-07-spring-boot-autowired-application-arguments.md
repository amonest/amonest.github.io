---
layout: post
title: Spring Boot - 获取Spring Boot启动参数
---

通过 **ApplicationArguments** 类可以获取 **SpringApplication.run(...)** 参数。

---

[1] src/main/java/net/mingyang/spring_boot_test/Application.java：

{% highlight java %}
package net.mingyang.spring_boot_test;

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
    static class TestApplicationArguments {
        @Autowired
        public TestApplicationArguments(ApplicationArguments args) {
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

[2] Package:

{% highlight shell %}
X:\dev\spring-boot-test> mvn package
{% endhighlight %}

---

[3] Run:

{% highlight shell %}
X:\dev\spring-boot-test> java -jar target\spring-boot-test-0.0.1-SNAPSHOT.jar foo bar --name=suifeng --age=30 --sex=men
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