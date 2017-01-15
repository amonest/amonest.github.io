---
layout: post
title: Spring JPA - 创建查询方法
---

[1] 通过解析方法名创建查询

框架在进行方法名解析时，会先把方法名多余的前缀截取掉，比如 find、findBy、read、readBy、get、getBy，然后对剩下部分进行解析。并且如果方法的最后一个参数是 Sort 或者 Pageable 类型，也会提取相关的信息，以便按规则进行排序或者分页查询。

在创建查询时，我们通过在方法名中使用属性名称来表达，比如 findByUserAddressZip ()。框架在解析该方法时，首先剔除 findBy，然后对剩下的属性进行解析，详细规则如下（此处假设该方法针对的域对象为 AccountInfo 类型）：

先判断 userAddressZip （根据 POJO 规范，首字母变为小写，下同）是否为 AccountInfo 的一个属性，如果是，则表示根据该属性进行查询；如果没有该属性，继续第二步；
从右往左截取第一个大写字母开头的字符串（此处为 Zip），然后检查剩下的字符串是否为 AccountInfo 的一个属性，如果是，则表示根据该属性进行查询；如果没有该属性，则重复第二步，继续从右往左截取；最后假设 user 为 AccountInfo 的一个属性；
接着处理剩下部分（ AddressZip ），先判断 user 所对应的类型是否有 addressZip 属性，如果有，则表示该方法最终是根据 "AccountInfo.user.addressZip" 的取值进行查询；否则继续按照步骤 2 的规则从右往左截取，最终表示根据 "AccountInfo.user.address.zip" 的值进行查询。
在查询时，通常需要同时根据多个属性进行查询，且查询的条件也格式各样（大于某个值、在某个范围等等），Spring Data JPA 为此提供了一些表达条件查询的关键字，大致如下：

And --- 等价于 SQL 中的 and 关键字，比如 findByUsernameAndPassword(String user, Striang pwd)；
Or --- 等价于 SQL 中的 or 关键字，比如 findByUsernameOrAddress(String user, String addr)；
Between --- 等价于 SQL 中的 between 关键字，比如 findBySalaryBetween(int max, int min)；
LessThan --- 等价于 SQL 中的 "<"，比如 findBySalaryLessThan(int max)；
GreaterThan --- 等价于 SQL 中的">"，比如 findBySalaryGreaterThan(int min)；
IsNull --- 等价于 SQL 中的 "is null"，比如 findByUsernameIsNull()；
IsNotNull --- 等价于 SQL 中的 "is not null"，比如 findByUsernameIsNotNull()；
NotNull --- 与 IsNotNull 等价；
Like --- 等价于 SQL 中的 "like"，比如 findByUsernameLike(String user)；
NotLike --- 等价于 SQL 中的 "not like"，比如 findByUsernameNotLike(String user)；
OrderBy --- 等价于 SQL 中的 "order by"，比如 findByUsernameOrderBySalaryAsc(String user)；
Not --- 等价于 SQL 中的 "！ ="，比如 findByUsernameNot(String user)；
In --- 等价于 SQL 中的 "in"，比如 findByUsernameIn(Collection<String> userList) ，方法的参数可以是 Collection 类型，也可以是数组或者不定长参数；
NotIn --- 等价于 SQL 中的 "not in"，比如 findByUsernameNotIn(Collection<String> userList) ，方法的参数可以是 Collection 类型，也可以是数组或者不定长参数；


---

[2] 使用 @Query 创建查询

@Query 注解的使用非常简单，只需在声明的方法上面标注该注解，同时提供一个 JP QL 查询语句即可，如下所示：

复制代码
 public interface UserDao extends Repository<AccountInfo, Long> { 

 @Query("select a from AccountInfo a where a.accountId = ?1") 
 public AccountInfo findByAccountId(Long accountId); 

    @Query("select a from AccountInfo a where a.balance > ?1") 
 public Page<AccountInfo> findByBalanceGreaterThan( 
 Integer balance,Pageable pageable); 
 } 
复制代码
很多开发者在创建 JP QL 时喜欢使用命名参数来代替位置编号，@Query 也对此提供了支持。JP QL 语句中通过": 变量"的格式来指定参数，同时在方法的参数前面使用 @Param 将方法参数与 JP QL 中的命名参数对应，示例如下：

复制代码
public interface UserDao extends Repository<AccountInfo, Long> { 

 public AccountInfo save(AccountInfo accountInfo); 

 @Query("from AccountInfo a where a.accountId = :id") 
 public AccountInfo findByAccountId(@Param("id")Long accountId); 

   @Query("from AccountInfo a where a.balance > :balance") 
   public Page<AccountInfo> findByBalanceGreaterThan( 
 @Param("balance")Integer balance,Pageable pageable); 
 } 
复制代码
此外，开发者也可以通过使用 @Query 来执行一个更新操作，为此，我们需要在使用 @Query 的同时，用 @Modifying 来将该操作标识为修改查询，这样框架最终会生成一个更新的操作，而非查询。如下所示：

 @Modifying 
 @Query("update AccountInfo a set a.salary = ?1 where a.salary < ?2") 
 public int increaseSalary(int after, int before); 


---

[3] 通过调用 JPA 命名查询语句创建查询

命名查询是 JPA 提供的一种将查询语句从方法体中独立出来，以供多个方法共用的功能。Spring Data JPA 对命名查询也提供了很好的支持。用户只需要按照 JPA 规范在 orm.xml 文件或者在代码中使用 @NamedQuery（或 @NamedNativeQuery）定义好查询语句，唯一要做的就是为该语句命名时，需要满足”DomainClass.methodName()”的命名规则。假设定义了如下接口：

public interface UserDao extends Repository<AccountInfo, Long> { 
 ...... 
 public List<AccountInfo> findTop5(); 
 } 
如果希望为 findTop5() 创建命名查询，并与之关联，我们只需要在适当的位置定义命名查询语句，并将其命名为 "AccountInfo.findTop5"，框架在创建代理类的过程中，解析到该方法时，优先查找名为 "AccountInfo.findTop5" 的命名查询定义，如果没有找到，则尝试解析方法名，根据方法名字创建查询。







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