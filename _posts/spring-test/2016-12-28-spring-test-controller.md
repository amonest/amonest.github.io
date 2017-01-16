---
layout: post
title: Spring Test - 控制器测试
---

NumberController.java：

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

NumberControllerTest.java：

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
@SpringBootTest
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

也可以用 **@WebMvcTest** 简化 **MockMvc** 创建方式：

{% highlight java %}

@RunWith(SpringRunner.class)
@WebMvcTest(NumberController.class)
public class NumberControllerTest {
    
    @Autowired
    private MockMvc mvc;

    ... ...
}
{% endhighlight %}