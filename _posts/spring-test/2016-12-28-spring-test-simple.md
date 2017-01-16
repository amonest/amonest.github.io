---
layout: post
title: Spring Test - 简单测试
---

{% highlight java %}
package net.mingyang.spring_boot_test;

import static org.junit.Assert.assertEquals;

import org.junit.Test;
import org.junit.runner.RunWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.junit4.SpringRunner;

@RunWith(SpringRunner.class)
@SpringBootTest
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