---
layout: post
title: 注入Map或List
---

{% highlight java %}
package net.mingyang.spring_boot_test;

import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.stereotype.Component;

@SpringBootApplication
public class Application {
    
    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }
    
    static interface Animal { }
    
    @Component
    static class Tiger implements Animal { }
    
    @Component
    static class Lion implements Animal { }
    
    @Component
    static class Elephant implements Animal { }
    
    @Component
    static class AnimalRunner implements CommandLineRunner {
        @Autowired
        private Map<String, Animal> animalMap;
        
        @Autowired
        private List<Animal> animalList;
        
        @Override
        public void run(String... args) throws Exception {
            System.out.println("animalMap:");
            for (String key : animalMap.keySet()) {
                System.out.println("\t" + key + "=" + animalMap.get(key));
            }
            
            System.out.println("animalList:");
            for (Animal animal : animalList) {
                System.out.println("\t" + animal);
            }
        }       
    }
}
{% endhighlight %}

---

Run:

{% highlight shell %}
X:\dev\spring-boot-test> mvn spring-boot:run
animalMap:
    application.Elephant=net.mingyang.spring_boot_test.Application$Elephant@4760f169
    application.Lion=net.mingyang.spring_boot_test.Application$Lion@261ea657
    application.Tiger=net.mingyang.spring_boot_test.Application$Tiger@35c12c7a
animalList:
    net.mingyang.spring_boot_test.Application$Elephant@4760f169
    net.mingyang.spring_boot_test.Application$Lion@261ea657
    net.mingyang.spring_boot_test.Application$Tiger@35c12c7a
{% endhighlight %}