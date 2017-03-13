---
layout: post
title: Spring XML - 自定义XML Schema
---

[1] Application.java:

{% highlight java %}
package net.mingyang.spring_source_analysis_boot;

import org.springframework.context.ApplicationContext;
import org.springframework.context.support.ClassPathXmlApplicationContext;

public class SpringSourceAnalysisBootApplication {

    public static void main(String[] args) {
        ApplicationContext ctx = new ClassPathXmlApplicationContext("beanFactoryTest.xml");
        HelloBean helloBean = ctx.getBean(HelloBean.class);
        System.out.println(helloBean);
    }
}

{% endhighlight %}


---

[2] HelloBean.java:

{% highlight java %}
package net.mingyang.spring_source_analysis_boot;

public class HelloBean {

    private String message;

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    @Override
    public String toString() {
        StringBuilder builder = new StringBuilder();
        builder.append("HelloBean [message=");
        builder.append(message);
        builder.append("]");
        return builder.toString();
    }
    
    public void sayHello() {
        System.out.println(getClass().getSimpleName() + ": " + this.getMessage());
    }

}
{% endhighlight %}


---

[3] HelloBeanDefinitionParser.java:

{% highlight java %}
package net.mingyang.spring_source_analysis_boot;

import org.springframework.beans.factory.support.BeanDefinitionBuilder;
import org.springframework.beans.factory.xml.AbstractSingleBeanDefinitionParser;
import org.springframework.util.StringUtils;
import org.w3c.dom.Element;

public class HelloBeanDefinitionParser extends AbstractSingleBeanDefinitionParser {

    protected Class<?> getBeanClass(Element element) {
        return HelloBean.class;
    }

    protected void doParse(Element element, BeanDefinitionBuilder bean) {
        String message = element.getAttribute("message");

        if (StringUtils.hasText(message)) {
            bean.addPropertyValue("message", message);
        }
    }
}
{% endhighlight %}


---

[4] OrganizationNamespaceHandler.java:

{% highlight java %}
package net.mingyang.spring_source_analysis_boot;

import org.springframework.beans.factory.xml.NamespaceHandlerSupport;

public class OrganizationNamespaceHandler extends NamespaceHandlerSupport {

    public void init() {
        registerBeanDefinitionParser("helloBean", new HelloBeanDefinitionParser());
    }
}
{% endhighlight %}


---

[5] META-INF/mingyang-organization.xsd:

{% highlight xml %}
<?xml version="1.0" encoding="UTF-8"?>
<xsd:schema xmlns:xsd="http://www.w3.org/2001/XMLSchema"
    xmlns:beans="http://www.springframework.org/schema/beans"
    targetNamespace="http://www.mingyang.net/schema/organization"
    elementFormDefault="qualified" attributeFormDefault="unqualified">

    <xsd:import namespace="http://www.springframework.org/schema/beans"
        schemaLocation="http://www.springframework.org/schema/beans/spring-beans.xsd" />

    <xsd:element name="helloBean">
        <xsd:complexType>
            <xsd:complexContent>
                <xsd:extension base="beans:identifiedType">
                    <xsd:attribute name="message" type="xsd:string" />
                </xsd:extension>
            </xsd:complexContent>
        </xsd:complexType>
    </xsd:element>

</xsd:schema>
{% endhighlight %}


---

[6] META-INF/spring.handlers:

{% highlight properties %}
http\://www.mingyang.net/schema/organization=net.mingyang.spring_source_analysis_boot.OrganizationNamespaceHandler
{% endhighlight %}


---

[7] META-INF/spring.schemas:

{% highlight properties %}
http\://www.mingyang.net/schema/organization.xsd=META-INF/mingyang-organization.xsd
{% endhighlight %}


---

[8] beanFactoryTest.xml:

{% highlight xml %}
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:org="http://www.mingyang.net/schema/organization"
    xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd
       http://www.mingyang.net/schema/organization http://www.mingyang.net/schema/organization.xsd">

    <org:helloBean id="helloBean" message="Hello, World!" />
</beans>

{% endhighlight %}


---

[9] run:

{% highlight shell %}
HelloBean [message=Hello, World!]
{% endhighlight %}