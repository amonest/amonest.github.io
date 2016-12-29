---
layout: post
title: 测试控制器
---

[1] pom.xml：

{% highlight xml %}
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-web</artifactId>
</dependency>

<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-thymeleaf</artifactId>
</dependency>

<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-test</artifactId>
    <scope>test</scope>
</dependency>
{% endhighlight %}

---

[2] src/main/java/net/mingyang/spring_boot_test/NumberController.java：

{% highlight java %}
package net.mingyang.spring_boot_test;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;

@Controller
public class NumberController {
    
    public final static String PARAM_NUM1 = "num1"; 
    public final static String PARAM_NUM2 = "num2";
    
    public final static String MODEL_RESULT = "result";
    
    public final static String VIEW_SUCCESS = "success";

    @RequestMapping(value ="/plus")
    public String plus(@RequestParam(PARAM_NUM1) Integer a, 
            @RequestParam(PARAM_NUM2) Integer b, Model model) {
        model.addAttribute(MODEL_RESULT, a + b);
        return VIEW_SUCCESS;
    }
    
    @RequestMapping(value ="/minus")
    public String minus(@RequestParam(PARAM_NUM1) Integer a, 
            @RequestParam(PARAM_NUM2) Integer b, Model model) {
        model.addAttribute(MODEL_RESULT, a - b);
        return VIEW_SUCCESS;
    }
}
{% endhighlight %}

---

[3] src/main/java/net/mingyang/spring_boot_test/Application.java：

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

[4] src/main/resources/templates/success.html:

{% highlight html %}
<!DOCTYPE HTML>
<html lang="zh-CN" xmlns:th="http://www.thymeleaf.org">
<head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
</head>
<body>
    <span th:text="${result}">result</span>
</body>
</html>
{% endhighlight %}

---

[5] src/test/java/net/mingyang/spring_boot_test/NumberControllerTest.java：

{% highlight java %}
package net.mingyang.spring_boot_test;

import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.junit4.SpringRunner;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders;
import org.springframework.test.web.servlet.result.MockMvcResultMatchers;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

@RunWith(SpringRunner.class)
@SpringBootTest(classes = Application.class)
public class NumberControllerTest {
    
    private final static int NUM1 = 100;
    
    private final static int NUM2 = 30;
    
    private MockMvc mvc;

    @Before
    public void setUp() {  
        mvc = MockMvcBuilders.standaloneSetup(new NumberController()).build();  
    }
    
    @Test
    public void testPlus() throws Exception {
        int expected = NUM1 + NUM2;
        mvc.perform(MockMvcRequestBuilders.get("/plus")
                .param(NumberController.PARAM_NUM1, String.valueOf(NUM1))
                .param(NumberController.PARAM_NUM2, String.valueOf(NUM2)))
            .andExpect(MockMvcResultMatchers.view().name(NumberController.VIEW_SUCCESS))
            .andExpect(MockMvcResultMatchers.model().attribute(NumberController.MODEL_RESULT, expected));
    }
    
    @Test
    public void testMinus() throws Exception {
        int expected = NUM1 - NUM2;
        mvc.perform(MockMvcRequestBuilders.get("/minus")
                .param(NumberController.PARAM_NUM1, String.valueOf(NUM1))
                .param(NumberController.PARAM_NUM2, String.valueOf(NUM2)))
            .andExpect(MockMvcResultMatchers.view().name(NumberController.VIEW_SUCCESS))
            .andExpect(MockMvcResultMatchers.model().attribute(NumberController.MODEL_RESULT, expected));
    }
}
{% endhighlight %}

也可以用 **@WebMvcTest** 按照下面这种方式简写：

{% highlight java %}
package net.mingyang.spring_boot_test;

import org.junit.Test;
import org.junit.runner.RunWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.test.context.junit4.SpringRunner;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders;
import org.springframework.test.web.servlet.result.MockMvcResultMatchers;

@RunWith(SpringRunner.class)
@WebMvcTest(NumberController.class)
public class NumberControllerTest2 {
    
    private final static int NUM1 = 100;
    
    private final static int NUM2 = 30;
    
    @Autowired
    private MockMvc mvc;
    
    @Test
    public void testPlus() throws Exception {
        int expected = NUM1 + NUM2;
        mvc.perform(MockMvcRequestBuilders.get("/plus")
                .param(NumberController.PARAM_NUM1, String.valueOf(NUM1))
                .param(NumberController.PARAM_NUM2, String.valueOf(NUM2)))
            .andExpect(MockMvcResultMatchers.view().name(NumberController.VIEW_SUCCESS))
            .andExpect(MockMvcResultMatchers.model().attribute(NumberController.MODEL_RESULT, expected));
    }
    
    @Test
    public void testMinus() throws Exception {
        int expected = NUM1 - NUM2;
        mvc.perform(MockMvcRequestBuilders.get("/minus")
                .param(NumberController.PARAM_NUM1, String.valueOf(NUM1))
                .param(NumberController.PARAM_NUM2, String.valueOf(NUM2)))
            .andExpect(MockMvcResultMatchers.view().name(NumberController.VIEW_SUCCESS))
            .andExpect(MockMvcResultMatchers.model().attribute(NumberController.MODEL_RESULT, expected));
    }
}
{% endhighlight %}