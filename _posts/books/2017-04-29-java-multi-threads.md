---
layout: post
title: 《Java并发编程实践》
---

### 过期数据

MutableInteger不是线程安全的。setter和getter都访问了value，却没有进行同步。

如果一个线程A调用了setter，而另一个线程B同时调用了getter，线程B可能就看不到更新的数据了。

{% highlight java %}
public class MutableInteger {

    private int value;

    public void setValue(int value) {
        this.value = value;
    }

    public int getValue() {
        return value;
    }
}
{% endhighlight %}

我们可以通过同步化setting和getter，使MutableInteger编程线程安全的。

{% highlight java %}
public class SynchronizedInteger {

    private int value;

    public synchronized void setValue(int value) {
        this.value = value;
    }

    public synchronized int getValue() {
        return value;
    }
}
{% endhighlight %}

模拟情景：如果有两个线程A和B共享变量数据，A负责读取，B负责写入。

线程A先读取数据到局部变量，然后线程B被启动，数据被更新。这时候，线程A局部变量保存的数据也是过期的。

{% highlight java %}
public class Application {
    
    static class Person { }
    
    static Person person = new Person();

    public static void main(String[] args) throws InterruptedException {
        Person originalPerson = person;
        
        Thread childThread = new ChildThread();
        childThread.start();
        childThread.join(); 
        
        Person currentPerson = person;
        
        System.out.println("originalPerson == currentPerson? " + (originalPerson == currentPerson));
        
        // 运行结果：
        // originalPerson == currentPerson? false

    }
    
    static class ChildThread extends Thread {
        public void run() {
            person = new Person();
        }
    }
}
{% endhighlight %}


---

### 发布和逸出

发布(publishing)一个对象的意思是使它能够被当前范围之外的代码所使用。

**最常见的对象发布方式是将对象引用存储到公共静态域中**，任何类和线程都可以看见这个域。

{% highlight java %}
public static Set<Secret> knownSecrets;

public void initialize() {
    knownSecrets = new HashSet<Secret>();
}
{% endhighlight %}

**发布一个对象还会间接的发布其他对象。**如果你将一个Secret对象加入集合knownSecrets中，你就已经发布了这个对象，因为任何代码都可以遍历并获得新Secret对象的引用。

**类似的，从非私有方法中返回引用，也能发布返回的对象。**

{% highlight java %}
private String[] states = new String[] {"AK", "AL" ...};

public String[] getStates() {
    return states;
}
{% endhighlight %}

以这种方式发布states会出问题。任何一个调用者都能修改它的内容，而这个数组本应是私有的。

在这个例子中，数组states已经逸出(escape)了它所属的范围。这个本应是私有的数据，事实上已经变成公有了。

**不要让this引用在构造期间逸出**。对象只有通过构造函数返回后，才处于可预言的、稳定的状态。所以从构造函数内部发布的对象，只是一个未完成构造的对象。

**甚至即使是在构造函数的最后一行发布的引用也是如此**。

如果this引用在构造过程中逸出，这样的对象被认为是“没有正确构建的”。

{% highlight java %}
public clas XmlReader {

    public XmlReader() {
        this.parser = new XmlParser(this);
    }
}
{% endhighlight %}

你可以使用一个私有的构造函数和一个公共的工厂方法，这样就避免了不正确的创建。

{% highlight java %}
public clas XmlReader {

    private XmlReader() { }

    public static XmlReader createReader() {
        XmlReader reader = new XmlReader();
        reader.setParser(new XmlParser());
        return reader;
    }
}
{% endhighlight %}


---

### ThreadLocal

ThreadLocal提供了get与set访问器，为每个使用它的线程维护一份单独的拷贝。所以，**get总是返回由当前执行线程通过set设置的最新值**。

{% highlight java %}
public static ThreadLocal<Connection> connectionHolder =
    = new ThreadLocal<Connection>() {
        public Connection initialValue() {
            return DriverManager.getConnection(DB_URL);
        }
    };

public static Connection getConnection() {
    return connectionHolder.get();
}
{% endhighlight %}