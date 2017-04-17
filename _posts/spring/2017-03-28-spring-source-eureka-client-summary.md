---
layout: post
title: Spring Cloud 源码分析 - Eureka客户端说明
---

Eureka对象模型：

![spring-source-eureka-client-apps](/assets/img/posts/spring-source-eureka-client-apps.png)



---

### DiscoveryClient配置

Eureka客户端核心类是 **DiscoveryClient**：

{% highlight java %}
package com.netflix.discovery;

public class DiscoveryClient implements EurekaClient {

    ... ...
}
{% endhighlight %}

先看它的构造函数：

{% highlight java %}
DiscoveryClient(ApplicationInfoManager applicationInfoManager, EurekaClientConfig config, DiscoveryClientOptionalArgs args,
    Provider<BackupRegistry> backupRegistryProvider) {

    ... ...
}
{% endhighlight %}

第一个参数applicationInfoManager，内部包含InstanceInfo和EurekaInstanceConfig两个实例变量：

{% highlight java %}
public class ApplicationInfoManager {

    private InstanceInfo instanceInfo;
    private EurekaInstanceConfig config;

    ... ...
}
{% endhighlight %}

Spring Cloud通过 **EurekaClientAutoConfiguration** 自动配置 **ApplicationInfoManager** 实例。

{% highlight java %}
public class EurekaClientAutoConfiguration {

    @Configuration
    protected static class EurekaClientConfiguration {

        @Bean
        @ConditionalOnMissingBean(value = ApplicationInfoManager.class, search = SearchStrategy.CURRENT)
        public ApplicationInfoManager eurekaApplicationInfoManager(
                EurekaInstanceConfig config) {
            InstanceInfo instanceInfo = new InstanceInfoFactory().create(config);
            return new ApplicationInfoManager(config, instanceInfo);
        }
    }

    ... ...
}
{% endhighlight %}

**EurekaInstanceConfig** 请参考《[Eureka实例配置](/2017/03/24/spring-source-eureka-instance-config)》。

**InstanceInfoFactory** 根据 **EurekaInstanceConfig** 创建一个 **InstanceInfo** 实例。

{% highlight java %}
public class InstanceInfoFactory {

    public InstanceInfo create(EurekaInstanceConfig config) {
        InstanceInfo.Builder builder = InstanceInfo.Builder.newBuilder();
        builder.setNamespace(namespace).setAppName(config.getAppname())
                .setInstanceId(config.getInstanceId())
                .setAppGroupName(config.getAppGroupName())
                .setDataCenterInfo(config.getDataCenterInfo())

        ... ...

        InstanceInfo instanceInfo = builder.build();
        return instanceInfo;
    }
}
{% endhighlight %}

**DiscoveryClient** 构造器第二个参数是 **EurekaClientConfig**，请参考《[Eureka客户端配置](/2017/03/24/spring-source-eureka-client-config)》。



---

### EurekaTransport传输类

**EurekaTransport** 是 **DiscoveryClient** 的一个嵌套类，作为 **EurekaHttpClient** 的容器。

**EurekaHttpClient** 请参考《[EurekaHttpClient](/2017/03/28/spring-source-eureka-http-client)》。

{% highlight java %}
private static final class EurekaTransport {

    private EurekaHttpClient registrationClient;
    private EurekaHttpClientFactory registrationClientFactory;

    private EurekaHttpClient queryClient;
    private EurekaHttpClientFactory queryClientFactory;

    ... ...
}
{% endhighlight %}

**registrationClient** 和 **queryClient** 分别是什么意思呢？

Eureka Client和Eureka Server通信，可以注册到Eureka Server，可以从Eureka Server查询，也可以只选择其中一种。

这都可以通过EurekaClientConfig来配置，注册和查询分别对应不同的EurekaHttpClient对象：registrationClient 和 queryClient.

{% highlight java %}
if (clientConfig.shouldRegisterWithEureka()) { // 是否注册到Eureka Server?
    EurekaHttpClientFactory newRegistrationClientFactory = EurekaHttpClients.registrationClientFactory(
                eurekaTransport.bootstrapResolver,
                eurekaTransport.transportClientFactory,
                transportConfig
        );
    EurekaHttpClient newRegistrationClient = newRegistrationClientFactory.newClient();
    eurekaTransport.registrationClientFactory = newRegistrationClientFactory;
    eurekaTransport.registrationClient = newRegistrationClient; //用来注册的EurekaHttpClient
}

if (clientConfig.shouldFetchRegistry()) { // 是否从Eureka Server查询信息？
    EurekaHttpClientFactory newQueryClientFactory = EurekaHttpClients.queryClientFactory(
                eurekaTransport.bootstrapResolver,
                eurekaTransport.transportClientFactory,
                clientConfig,
                transportConfig,
                applicationInfoManager.getInfo(),
                applicationsSource
        );
    EurekaHttpClient newQueryClient = newQueryClientFactory.newClient();
    eurekaTransport.queryClientFactory = newQueryClientFactory;
    eurekaTransport.queryClient = newQueryClient; //用来查询的EurekaHttpClient
}
{% endhighlight %}





