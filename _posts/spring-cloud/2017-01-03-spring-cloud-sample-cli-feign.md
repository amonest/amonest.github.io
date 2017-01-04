---
layout: post
title: 实例(cli-feign)
---

[1] 创建项目cloth-cli-feign

---

[2] pom.xml：

{% highlight xml %}
<project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>net.mingyang</groupId>
    <artifactId>cloud-cli-feign</artifactId>
    <version>0.0.1-SNAPSHOT</version>
    <packaging>jar</packaging>

    <name>cloud-cli-feign</name>
    <url>http://maven.apache.org</url>

    <parent>
        <groupId>org.springframework.cloud</groupId>
        <artifactId>spring-cloud-starter-parent</artifactId>
        <version>Brixton.SR7</version>
    </parent>

    <dependencies>
        <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-starter</artifactId>
        </dependency>

        <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-starter-eureka</artifactId>
        </dependency>

        <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-starter-feign</artifactId>
        </dependency>

        <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-starter-hystrix</artifactId>
        </dependency>

        <dependency>
            <groupId>org.springframework.cloud</groupId>
            <artifactId>spring-cloud-starter-zuul</artifactId>
        </dependency>
    </dependencies>
</project>
{% endhighlight %}

---

[3] src/main/java/net/mingyang/cloud_cli_feign/Application.java：

{% highlight java %}
package net.mingyang.cloud_cli_feign;

import java.util.List;
import java.util.concurrent.TimeUnit;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.circuitbreaker.EnableCircuitBreaker;
import org.springframework.cloud.netflix.eureka.EnableEurekaClient;
import org.springframework.cloud.netflix.feign.EnableFeignClients;
import org.springframework.cloud.netflix.zuul.EnableZuulProxy;
import org.springframework.context.annotation.Bean;

@SpringBootApplication
@EnableEurekaClient
@EnableFeignClients
@EnableCircuitBreaker
@EnableZuulProxy
public class Application 
{
    public static void main( String[] args ) {
        SpringApplication.run(Application.class, args);
    }
    
    @Bean
    public ApplicationRunner runner() {
        return new ApplicationRunner() {
            @Autowired
            StudentCallback studentCallback;
            
            public void run(ApplicationArguments args) throws Exception { 
                List<Student> studentList = studentCallback.getList();
                for (Student student : studentList) {
                    System.out.println(student);
                }
            }
        };
    }
}
{% endhighlight %}

使用 **@EnableEurekaClient** 提供 Eureka Client 支持。

使用 **@EnableFeignClients** 提供 feign 客户端支持。

使用 **@EnableCircuitBreaker** 提供 CircuitBreaker 支持。

使用 **@EnableZuulProxy** 提供 网关代理 支持。

---

[4] src/main/java/net/mingyang/cloud_cli_feign/Student.java：

{% highlight java %}
package net.mingyang.cloud_cli_feign;

import java.io.Serializable;

@SuppressWarnings("serial")
public class Student implements Serializable {

    private int id;
    private String name;
    private float score;
    
    public int getId() {
        return id;
    }
    
    public void setId(int id) {
        this.id = id;
    }
    
    public String getName() {
        return name;
    }
    
    public void setName(String name) {
        this.name = name;
    }

    public float getScore() {
        return score;
    }

    public void setScore(float score) {
        this.score = score;
    }

    @Override
    public String toString() {
        StringBuilder builder = new StringBuilder();
        builder.append("Student [id=");
        builder.append(id);
        builder.append(", name=");
        builder.append(name);
        builder.append(", score=");
        builder.append(score);
        builder.append("]");
        return builder.toString();
    }
}
{% endhighlight %}

---

[5] src/main/java/net/mingyang/cloud_cli_feign/StudentService.java：

{% highlight java %}
package net.mingyang.cloud_cli_feign;

import java.util.List;

import org.springframework.cloud.netflix.feign.FeignClient;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.ResponseBody;

@FeignClient("cloud-student")
public interface StudentService {

    @RequestMapping(value = "/list", method = RequestMethod.POST,
            produces = MediaType.APPLICATION_JSON_VALUE,
            consumes = MediaType.APPLICATION_JSON_VALUE)
    @ResponseBody
    List<Student> getList();
}
{% endhighlight %}

---

[6] src/main/java/net/mingyang/cloud_cli_feign/StudentCallback.java：

{% highlight java %}
package net.mingyang.cloud_cli_feign;

import java.util.ArrayList;
import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.netflix.hystrix.contrib.javanica.annotation.HystrixCommand;

@Service
public class StudentCallback {

    @Autowired
    StudentService studentService;
    
    @HystrixCommand(fallbackMethod = "fallback")
    public List<Student> getList() {
        List<Student> studentList = studentService.getList();
        return studentList;
    }
    
    public List<Student> fallback() {
        List<Student> studentList = new ArrayList<Student>();
        Student student = new Student();
        student.setName("fallback");
        studentList.add(student);
        return studentList;
    }
}
{% endhighlight %}

---

[5] src/main/resources/bootstrap.properties：

{% highlight properties %}
eureka.client.serviceUrl.defaultZone=http://localhost:8761/eureka/
eureka.client.registerWithEureka=false
spring.application.name=cloud-cli-feign
{% endhighlight %}

---

[7] Run:

{% highlight shell %}
X:\dev\cloud-cli-feign> mvn spring-boot:run
Student [id=1, name=张三, score=95.0]
Student [id=2, name=李四, score=90.0]
Student [id=3, name=王五, score=100.0]
{% endhighlight %}