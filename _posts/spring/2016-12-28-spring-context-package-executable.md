---
layout: post
title: 可执行jar
---

[1] [《创建Maven项目》](/2016/12/28/spring-create-maven-project)

---

[2] pom.xml：

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

---

[3] src/main/java/net/mingyang/spring_boot_config/Application.java：

{% highlight java %}
package net.mingyang.spring_boot_config;

import java.util.concurrent.TimeUnit;

import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;

@SpringBootApplication
public class Application {
  
  public static void main(String[] args) {
    SpringApplication.run(Application.class, args);
  }
  
  @Bean
  public ApplicationRunner runner() {
    return new ApplicationRunner() {
      public void run(ApplicationArguments args) throws Exception {
        int count = 0;            
        while (true) {
          System.out.println("one-" + count++);
          TimeUnit.SECONDS.sleep(2);
        }
      }
    };
  }
}
{% endhighlight %}

---

[4] Package:

{% highlight shell %}
X:\dev\spring-boot-config> mvn package
{% endhighlight %}

---

[5] Run:

{% highlight shell %}
X:\dev\spring-boot-config> java -jar target\spring-boot-config-0.0.1-SNAPSHOT.jar
one-0
one-1
one-2
one-3
one-4
one-5
one-6
{% endhighlight %}