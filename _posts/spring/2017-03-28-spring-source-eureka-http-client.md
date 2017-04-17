---
layout: post
title: Spring Cloud 源码分析 - EurekaHttpClient
---

**EurekaHttpClient** 是Eureka的客户端请求接口。

{% highlight java %}
package com.netflix.discovery.shared.transport;

public interface EurekaHttpClient {
    EurekaHttpResponse<Void> register(InstanceInfo info);
    EurekaHttpResponse<Void> cancel(String appName, String id);
    EurekaHttpResponse<InstanceInfo> sendHeartBeat(String appName, String id, InstanceInfo info, InstanceStatus overriddenStatus);
    EurekaHttpResponse<Void> statusUpdate(String appName, String id, InstanceStatus newStatus, InstanceInfo info);
    EurekaHttpResponse<Void> deleteStatusOverride(String appName, String id, InstanceInfo info);
    EurekaHttpResponse<Applications> getApplications(String... regions);
    EurekaHttpResponse<Applications> getDelta(String... regions);
    EurekaHttpResponse<Applications> getVip(String vipAddress, String... regions);
    EurekaHttpResponse<Applications> getSecureVip(String secureVipAddress, String... regions);
    EurekaHttpResponse<Application> getApplication(String appName);
    EurekaHttpResponse<InstanceInfo> getInstance(String appName, String id);
    EurekaHttpResponse<InstanceInfo> getInstance(String id);
    void shutdown();
}
{% endhighlight %}

主要实现类是 **AbstractJerseyEurekaHttpClient**，它的内部封装了一个jerseyClient对象。

{% highlight java %}
package com.netflix.discovery.shared.transport.jersey;

public abstract class AbstractJerseyEurekaHttpClient implements EurekaHttpClient {

    protected final Client jerseyClient;
    protected final String serviceUrl;

    protected AbstractJerseyEurekaHttpClient(Client jerseyClient, String serviceUrl) {
        this.jerseyClient = jerseyClient;
        this.serviceUrl = serviceUrl;
        logger.debug("Created client for url: {}", serviceUrl);
    }

    ... ...
}
{% endhighlight %}


以 **sendHeartBeat()** 为例，这是向Eureka Server发送一个心跳信息，实现如下：

{% highlight java %}
public EurekaHttpResponse<InstanceInfo> sendHeartBeat(String appName, String id, InstanceInfo info, InstanceStatus overriddenStatus) {
    String urlPath = "apps/" + appName + '/' + id;
    ClientResponse response = null;
    try {
        WebResource webResource = jerseyClient.resource(serviceUrl)
                .path(urlPath)
                .queryParam("status", info.getStatus().toString())
                .queryParam("lastDirtyTimestamp", info.getLastDirtyTimestamp().toString());
        if (overriddenStatus != null) {
            webResource = webResource.queryParam("overriddenstatus", overriddenStatus.name());
        }
        Builder requestBuilder = webResource.getRequestBuilder();
        addExtraHeaders(requestBuilder);
        response = requestBuilder.put(ClientResponse.class);
        EurekaHttpResponseBuilder<InstanceInfo> eurekaResponseBuilder = anEurekaHttpResponse(response.getStatus(), InstanceInfo.class).headers(headersOf(response));
        if (response.hasEntity()) {
            eurekaResponseBuilder.entity(response.getEntity(InstanceInfo.class));
        }
        return eurekaResponseBuilder.build();
    } finally {
        if (response != null) {
            response.close();
        }
    }
}
{% endhighlight %}
