---
layout: post
title: Spring Mvc - 配置HandlerInterceptor
---

LogInterceptor.java：

{% highlight java %}
package net.mingyang.spring_boot_test;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;
import org.springframework.web.servlet.ModelAndView;

@Component
public class LogInterceptor implements HandlerInterceptor {

    final static Logger log = LoggerFactory.getLogger(LogInterceptor.class);
  
    @Override
    public boolean preHandle(HttpServletRequest request, 
            HttpServletResponse response, 
            Object handler) 
            throws Exception {
        log.info("preHandle");
        return true;
    }
    
    @Override
    public void postHandle(HttpServletRequest request, 
            HttpServletResponse response, 
            Object handler, 
            ModelAndView modelAndView)
            throws Exception {
        log.info("postHandle");
    }
    
    @Override
    public void afterCompletion(
            HttpServletRequest request, 
            HttpServletResponse response, 
            Object handler, 
            Exception ex)
            throws Exception {
        log.info("afterCompletion");
    }
}
{% endhighlight %}

---

WebMvcConfig.java：

{% highlight java %}
package net.mingyang.spring_boot_test;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurerAdapter;

@Configuration
public class WebMvcConfig extends WebMvcConfigurerAdapter {

    @Autowired
    LogInterceptor logInterceptor;
    
    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        registry.addInterceptor(logInterceptor);
    }
}
{% endhighlight %}