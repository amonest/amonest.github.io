---
layout: post
title: Spring Mvc - 配置Servlet、Filter、Listener
---

{% highlight java %}
package net.mingyang.spring_boot_test;

import java.io.IOException;

import javax.servlet.Filter;
import javax.servlet.FilterChain;
import javax.servlet.FilterConfig;
import javax.servlet.ServletException;
import javax.servlet.ServletRequest;
import javax.servlet.ServletRequestEvent;
import javax.servlet.ServletRequestListener;
import javax.servlet.ServletResponse;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.springframework.boot.web.servlet.FilterRegistrationBean;
import org.springframework.boot.web.servlet.ServletListenerRegistrationBean;
import org.springframework.boot.web.servlet.ServletRegistrationBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class WebConfig {

    @Bean
    public ServletRegistrationBean helloServlet() {
        return new ServletRegistrationBean(new HelloServlet(), "/hello");
    }
    
    @Bean
    public ServletListenerRegistrationBean<HelloListenr> helloListenr() {
        return new ServletListenerRegistrationBean<HelloListenr>(new HelloListenr());
    }
    
    @Bean
    public FilterRegistrationBean helloFilter() {
        return new FilterRegistrationBean(new HelloFilter());
    }
    
    @SuppressWarnings("serial")
    static class HelloServlet extends HttpServlet {
        
        @Override
        protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
            System.out.println("HelloServlet.doGet()");
        }
        
        @Override
        protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
            System.out.println("HelloServlet.doPost()");
        }
    }
    
    static class HelloListenr implements ServletRequestListener {

        @Override
        public void requestDestroyed(ServletRequestEvent sre) {
            System.out.println("HelloListenr.requestDestroyed()");
        }

        @Override
        public void requestInitialized(ServletRequestEvent sre) {
            System.out.println("HelloListenr.requestInitialized()");
        }
    }
    
    static class HelloFilter implements Filter {

        @Override
        public void init(FilterConfig filterConfig) throws ServletException {
            System.out.println("HelloFilter.init()");
        }

        @Override
        public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
                throws IOException, ServletException {
            System.out.println("HelloFilter.doFilter()");
        }

        @Override
        public void destroy() {
            System.out.println("HelloFilter.destroy()");
        }
    }
}
{% endhighlight %}