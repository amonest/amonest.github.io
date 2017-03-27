---
layout: post
title: Spring Cloud 源码分析 - Eureka客户端配置
---

Eureka客户端配置是通过接口 **EurekaClientConfig** 来读取的。

{% highlight java %}
package com.netflix.discovery;

public interface EurekaClientConfig {

    int getRegistryFetchIntervalSeconds();
    int getInstanceInfoReplicationIntervalSeconds();
    int getInitialInstanceInfoReplicationIntervalSeconds();

    ... ...
}
{% endhighlight %}


---

Spring Cloud实现这个接口的类是 **EurekaClientConfigBean**。

{% highlight java %}
package org.springframework.cloud.netflix.eureka;

@ConfigurationProperties(EurekaClientConfigBean.PREFIX)
public class EurekaClientConfigBean implements EurekaClientConfig, EurekaConstants {

    public static final String PREFIX = "eureka.client";

    ... ...
}
{% endhighlight %}


---

**EurekaClientAutoConfiguration** 自动配置类实例这个 **EurekaClientConfigBean**。

{% highlight java %}
package org.springframework.cloud.netflix.eureka;

@Configuration
@EnableConfigurationProperties
public class EurekaClientAutoConfiguration {

    @Bean
    @ConditionalOnMissingBean(value = EurekaClientConfig.class, search = SearchStrategy.CURRENT)
    public EurekaClientConfigBean eurekaClientConfigBean() {
        EurekaClientConfigBean client = new EurekaClientConfigBean();
        if ("bootstrap".equals(this.env.getProperty("spring.config.name"))) {
            // We don't register during bootstrap by default, but there will be another
            // chance later.
            client.setRegisterWithEureka(false);
        }
        return client;
    }

    ... ...
}
{% endhighlight %}


---

综上所述，Eureka客户端会从 **application.properties** 获取以 **eureka.client** 开头的配置信息填充到 **EurekaClientConfigBean** 实例。

同理，Eureka客户端配置信息默认值都可以从 **EurekaClientConfigBean** 查得到。