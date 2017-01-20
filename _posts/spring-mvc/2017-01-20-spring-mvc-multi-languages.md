---
layout: post
title: Spring Mvc - 配置多语言
---

src/main/java/net/mingyang/spring_boot_test/WebLocaleConfig.java:

{% highlight java %}
package net.mingyang.spring_boot_test;

import java.util.Locale;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.LocaleResolver;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurerAdapter;
import org.springframework.web.servlet.i18n.LocaleChangeInterceptor;
import org.springframework.web.servlet.i18n.SessionLocaleResolver;

@Configuration
public class WebLocaleConfig extends WebMvcConfigurerAdapter {
    
    @Bean
    public LocaleResolver localeResolver() {
        SessionLocaleResolver slr = new SessionLocaleResolver();
        slr.setDefaultLocale(Locale.SIMPLIFIED_CHINESE);
        return slr;
    }

    @Bean
    public LocaleChangeInterceptor localeChangeInterceptor() {
        LocaleChangeInterceptor lci = new LocaleChangeInterceptor();
        lci.setParamName("lang");
        return lci;
    }
    
    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        registry.addInterceptor(localeChangeInterceptor());
    }
}
{% endhighlight %}

---

src/main/resources/messages.properties:

{% highlight properties %}
welcome.message = 你好！
{% endhighlight %}

---

src/main/resources/messages_en_US.properties:

{% highlight properties %}
welcome.message = Hello!
{% endhighlight %}

---

Html:

{% highlight html %}
<a href="?lang=en_US">英语</a>  
<a href="?lang=zh_CN">中文</a>
{% endhighlight %}