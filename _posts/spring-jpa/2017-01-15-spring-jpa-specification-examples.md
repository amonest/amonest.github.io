---
layout: post
title: Spring JPA - Specification查询示例
---

Specification接口：

{% highlight java %}
Predicate toPredicate(Root<T> root, CriteriaQuery<?> query, CriteriaBuilder cb);
{% endhighlight %}

---

简单的Predicate示例：

{% highlight java %}
Predicate p1=cb.like(root.get(“name”).as(String.class), “%”+uqm.getName()+“%”);

Predicate p2=cb.equal(root.get("uuid").as(Integer.class), uqm.getUuid());

Predicate p3=cb.gt(root.get("age").as(Integer.class), uqm.getAge());
{% endhighlight %}

---

组合的Predicate示例：

{% highlight java %}
Predicate p = cb.and(p3, cb.or(p1, p2)); 
{% endhighlight %}

---

动态拼接查询语句的方式：

{% highlight java %}
Specification<UserModel> spec = new Specification<UserModel>() {  
    public Predicate toPredicate(Root<UserModel> root,  
            CriteriaQuery<?> query, CriteriaBuilder cb) {  
        List<Predicate> list = new ArrayList<Predicate>();  
              
        if(um.getName()!=null && um.getName().trim().length()>0){  
            list.add(cb.like(root.get("name").as(String.class), "%"+um.getName()+"%"));  
        }

        if(um.getUuid()>0){  
            list.add(cb.equal(root.get("uuid").as(Integer.class), um.getUuid()));  
        }

        Predicate[] p = new Predicate[list.size()];  
        return cb.and(list.toArray(p));  
    }  
};
{% endhighlight %}

---

 也可以使用CriteriaQuery来得到最后的Predicate：

{% highlight java %}
Specification<UserModel> spec = new Specification<UserModel>() {  
    public Predicate toPredicate(Root<UserModel> root,  
            CriteriaQuery<?> query, CriteriaBuilder cb) {  
        Predicate p1 = cb.like(root.get("name").as(String.class), "%"+um.getName()+"%");  
        Predicate p2 = cb.equal(root.get("uuid").as(Integer.class), um.getUuid());  
        Predicate p3 = cb.gt(root.get("age").as(Integer.class), um.getAge()); 

        //把Predicate应用到CriteriaQuery中去,
        //因为还可以给CriteriaQuery添加其他的功能，比如排序、分组啥的  
        query.where(cb.and(p3, cb.or(p1, p2)));

        //添加排序的功能  
        query.orderBy(cb.desc(root.get("uuid").as(Integer.class)));  
          
        return query.getRestriction();  
    }  
};
{% endhighlight %}