---
layout: post
title: 自定义事件
---

[1] [《创建Maven项目》](/2016/12/28/spring-boot-create-maven-project)

---

[2] src/main/java/net/mingyang/spring_boot_config/Application.java：

{% highlight java %}
package net.mingyang.spring_boot_config;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.ApplicationContext;
import org.springframework.context.ApplicationEvent;
import org.springframework.context.ApplicationListener;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.PropertySource;
import org.springframework.stereotype.Component;

@SpringBootApplication
public class Application {
    
    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }
    
    @SuppressWarnings("serial")
    static class DemoEvent extends ApplicationEvent {
        private String msg;
        
        public String getMsg() {
            return msg;
        }
        
        public void setMsg(String msg) {
            this.msg = msg;
        }
        
        public DemoEvent(Object source, String msg) {
            super(source);
            this.msg = msg;
        }

        @Override
        public String toString() {
            StringBuilder builder = new StringBuilder();
            builder.append("DemoEvent [msg=");
            builder.append(msg);
            builder.append(", source=");
            builder.append(source);
            builder.append("]");
            return builder.toString();
        }
    }

    @Component
    static class DemoListener implements ApplicationListener<DemoEvent> {
        public void onApplicationEvent(DemoEvent event) {
            System.out.println(event);
        }
    }
    
    @Component
    static class DemoPublisher {
        @Autowired
        private ApplicationContext ctx;
        
        public void publish(String msg) {
            ctx.publishEvent(new DemoEvent(this, msg));
        }
    }
    
    @Bean
    public ApplicationRunner runner() {
        return new ApplicationRunner() {
            @Autowired
            private ApplicationContext ctx;
            
            public void run(ApplicationArguments args) throws Exception {
                DemoPublisher demoPublisher = ctx.getBean(DemoPublisher.class);
                demoPublisher.publish("hello");
            }
        };
    }  
}
{% endhighlight %}

---

[3] Run:

{% highlight shell %}
X:\dev\spring-boot-config> mvn spring-boot:run
DemoEvent [msg=hello, source=net.mingyang.spring_boot_config.Application$DemoPublisher@6caa5e85]
{% endhighlight %}