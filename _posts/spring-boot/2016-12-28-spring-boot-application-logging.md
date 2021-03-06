---
layout: post
title: Spring Boot - 启用应用程序日志
---

默认情况下，Spring Boot只会将日志记录到控制台而不会写进日志文件。

如果除了输出到控制台还想写入到日志文件，那需要设置 **logging.file** 或 **logging.path** 属性。

---

参考 [《73. Logging》](http://docs.spring.io/spring-boot/docs/current/reference/html/howto-logging.html)

---

[1] src/main/java/net/mingyang/spring_boot_test/Application.java：

{% highlight java %}
package net.mingyang.spring_boot_test;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;

@SpringBootApplication
public class Application {
    
    final Logger logger = LoggerFactory.getLogger(Application.class);
    
    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }   
    
    @Bean
    public ApplicationRunner runner() {
        return new ApplicationRunner() {
            public void run(ApplicationArguments args) throws Exception {
                logger.debug("ApplicationRunner.run(");
            }
        };
    }
}
{% endhighlight %}

---

[2] src/main/resources/application.properties:

{% highlight ini %}
logging.file = logs/spring-boot-test.log

# TRACE, DEBUG, INFO, WARN, ERROR, FATAL, OFF
logging.level.org.springframework = DEBUG
logging.level.org.hibernate = INFO
logging.level = DEBUG
{% endhighlight %}