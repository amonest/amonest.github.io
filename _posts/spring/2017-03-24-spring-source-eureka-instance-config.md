---
layout: post
title: Spring Cloud 源码分析 - Eureka实例配置
---

Eureka实例配置是通过接口 **EurekaInstanceConfig** 来读取的。

{% highlight java %}
package com.netflix.appinfo;

public interface EurekaInstanceConfig {

    String getInstanceId();
    String getAppname();
    String getAppGroupName();

    ... ...
}
{% endhighlight %}


---

Spring Cloud实现这个接口的类是 **EurekaInstanceConfigConfigBean**。

{% highlight java %}
package org.springframework.cloud.netflix.eureka;

public interface CloudEurekaInstanceConfig extends EurekaInstanceConfig {
    void setNonSecurePort(int port);
    InstanceInfo.InstanceStatus getInitialStatus();
}

@ConfigurationProperties("eureka.instance")
public class EurekaInstanceConfigBean implements CloudEurekaInstanceConfig {

    ... ...
}
{% endhighlight %}


---

**EurekaClientAutoConfiguration** 自动配置类实例这个 **EurekaInstanceConfigBean**。

{% highlight java %}
package org.springframework.cloud.netflix.eureka;

@Configuration
@EnableConfigurationProperties
public class EurekaClientAutoConfiguration {

    @Bean
    @ConditionalOnMissingBean(value = EurekaInstanceConfig.class, search = SearchStrategy.CURRENT)
    public EurekaInstanceConfigBean eurekaInstanceConfigBean(InetUtils inetUtils) {
        EurekaInstanceConfigBean instance = new EurekaInstanceConfigBean(inetUtils);
        instance.setNonSecurePort(this.nonSecurePort);
        instance.setInstanceId(getDefaultInstanceId(this.env));
        if (this.managementPort != this.nonSecurePort && this.managementPort != 0) {
            if (StringUtils.hasText(this.hostname)) {
                instance.setHostname(this.hostname);
            }
            String scheme = instance.getSecurePortEnabled() ? "https" : "http";
            instance.setStatusPageUrl(scheme + "://" + instance.getHostname() + ":"
                    + this.managementPort + instance.getStatusPageUrlPath());
            instance.setHealthCheckUrl(scheme + "://" + instance.getHostname() + ":"
                    + this.managementPort + instance.getHealthCheckUrlPath());
        }
        return instance;
    }

    ... ...
}
{% endhighlight %}


---

综上所述，Eureka实例会从 **application.properties** 获取以 **eureka.instance** 开头的配置信息填充到 **EurekaInstanceConfigBean** 实例。

同理，Eureka实例配置信息默认值都可以从 **EurekaInstanceConfigBean** 查得到。