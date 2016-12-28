---
layout: post
title: 测试服务
---

[1] [《创建Maven项目》](/2016/12/28/spring-boot-create-maven-project)

---

[2] pom.xml：

{% highlight xml %}
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter</artifactId>
</dependency>

<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-test</artifactId>
    <scope>test</scope>
</dependency>
{% endhighlight %}

---

[3] src/main/java/net/mingyang/spring_boot_test/NumberService.java：

{% highlight java %}
package net.mingyang.spring_boot_test;

import org.springframework.stereotype.Component;

@Component
public class NumberService {
    
    public int plus(int a, int b) {
        return a + b;
    }
    
    public int minus(int a, int b) {
        return a - b;
    }
}
{% endhighlight %}

---

[4] src/main/java/net/mingyang/spring_boot_test/Application.java：

{% highlight java %}
package net.mingyang.spring_boot_test;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class Application {
    
    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }
}
{% endhighlight %}

---

[5] src/test/java/net/mingyang/spring_boot_test/NumberServiceTest.java：

{% highlight java %}
package net.mingyang.spring_boot_test;

import static org.junit.Assert.assertEquals;

import org.junit.Test;
import org.junit.runner.RunWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.junit4.SpringRunner;

@RunWith(SpringRunner.class)
@SpringBootTest(classes = Application.class)
public class NumberServiceTest {
    
    @Autowired
    private NumberService numberService;

    private final static int NUM1 = 100;
    
    private final static int NUM2 = 30;
    
    @Test
    public void testPlus() throws Exception {
        int result = numberService.plus(NUM1, NUM2);
        assertEquals(result, NUM1 + NUM2);
    }
    
    @Test
    public void testMinus() throws Exception {
        int result = numberService.minus(NUM1, NUM2);
        assertEquals(result, NUM1 - NUM2);
    }
}
{% endhighlight %}