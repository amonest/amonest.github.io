---
layout: post
title: 重置私有字段
---

{% highlight java %}
package net.mingyang.spring_boot_test;

import java.lang.reflect.Field;
import java.util.ArrayList;
import java.util.List;

import org.springframework.util.ReflectionUtils;

public class Application {

    public static void main(String[] args) {
        AnimalManager animalManager = new AnimalManager();
        
        System.out.println("Original:");
        animalManager.printAnimals();
        
        List<String> list = new ArrayList<String>();
        list.add("rabbit");
        list.add("elephant");
        changeAnimals(animalManager, list);
        
        System.out.println("Changed:");
        animalManager.printAnimals();
    }
    
    static class AnimalManager {        
        private List<String> animals;
        
        public AnimalManager() {
            animals = new ArrayList<String>();
            animals.add("tiger");
            animals.add("lion");
        }
        
        public void printAnimals() {
            for (String animal : animals) {
                System.out.println("\t" + animal);
            }
        }
    }
    
    static void changeAnimals(AnimalManager manager, List<String> animals) {
        Field field = ReflectionUtils.findField(AnimalManager.class, "animals");
        ReflectionUtils.makeAccessible(field);
        @SuppressWarnings("unchecked")
        List<String> list = (List<String>) ReflectionUtils.getField(field, manager);
        list.clear();
        list.addAll(animals);
    }
}
{% endhighlight %}

---

Run:

{% highlight shell %}
X:\dev\spring-boot-test> mvn spring-boot:run
Original:
    tiger
    lion
Changed:
    rabbit
    elephant
{% endhighlight %}