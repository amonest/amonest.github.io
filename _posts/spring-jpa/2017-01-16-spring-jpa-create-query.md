---
layout: post
title: Spring JPA - 创建查询
---

### 通过 method name 创建查询

{% highlight xml %}
public interface UserRepository extends Repository<User, Long> {
    List<User> findByEmailAddressAndLastname(String emailAddress, String lastname);
}
{% endhighlight %}

上面的 findByEmailAddressAndLastname 方法会被解析成下面的JPA查询语句：

{% highlight sql %}
select u from User u where u.emailAddress = ?1 and u.lastname = ?2
{% endhighlight %}

Spring JPA 在 method name 中支持如下关键字：

|**Keyword**    | **Sample**                        | **JPQL snippet**  |
| And           | findByLastnameAndFirstname        | … where x.lastname = ?1 and x.firstname = ?2 |
| Or            | findByLastnameOrFirstname         | … where x.lastname = ?1 or x.firstname = ?2 |
| Is,Equals     | findByFirstname,findByFirstnameIs,findByFirstnameEquals | … where x.firstname = ?1 |
| Between       | findByStartDateBetween            | … where x.startDate between ?1 and ?2 |
| LessThan      | findByAgeLessThan                 | … where x.age < ?1 |
| LessThanEqual | findByAgeLessThanEqual            | … where x.age <= ?1 |
| GreaterThan   | findByAgeGreaterThan              | … where x.age > ?1 |
| GreaterThanEqual | findByAgeGreaterThanEqual      | … where x.age >= ?1 |
| After         | findByStartDateAfter              | … where x.startDate > ?1 |
| Before        | findByStartDateBefore             | … where x.startDate < ?1 |
| IsNull        | findByAgeIsNull                   | … where x.age is null | 
| IsNotNull,NotNull | findByAge(Is)NotNull          | … where x.age not null |
| Like          | findByFirstnameLike               | … where x.firstname like ?1 |
| NotLike       | findByFirstnameNotLike            | … where x.firstname not like ?1 |
| StartingWith  | findByFirstnameStartingWith       | … where x.firstname like ?1 (parameter bound with appended %) |
| EndingWith    | findByFirstnameEndingWith         | … where x.firstname like ?1 (parameter bound with prepended %) |
| Containing    | findByFirstnameContaining         | … where x.firstname like ?1 (parameter bound wrapped in %) |
| OrderBy       | findByAgeOrderByLastnameDesc      | … where x.age = ?1 order by x.lastname desc |
| Not           | findByLastnameNot                 | … where x.lastname <> ?1 |
| In            | findByAgeIn(Collection<Age> ages) | … where x.age in ?1 | 
| NotIn         | findByAgeNotIn(Collection<Age> age) | … where x.age not in ?1 | 
| True          | findByActiveTrue()                | … where x.active = true |
| False         | findByActiveFalse()               | … where x.active = false |
| IgnoreCase    | findByFirstnameIgnoreCase         | … where UPPER(x.firstame) = UPPER(?1) | 

---

### 创建 Named Queries 查询

在实体类上使用 **@NamedQuery** 注解：

{% highlight java %}
@Entity
@NamedQuery(name = "User.findByEmailAddress", 
    query = "select u from User u where u.emailAddress = ?1")
public class User {

}
{% endhighlight %}

定义接口：

{% highlight java %}
public interface UserRepository extends JpaRepository<User, Long> {
    User findByEmailAddress(String emailAddress);
}
{% endhighlight %}

也可以使用XML方式创建 Named Queries，这个XML路径为 **META-INF/orm.xml**。

{% highlight java %}
<named-query name="User.findByLastname">
    <query>select u from User u where u.lastname = ?1</query>
</named-query>
{% endhighlight %}

**@NamedQuery** 或 **&lt;named-query /&gt;** 使用的是 JPA query language，也可以使用 **@NamedNativeQuery** 和 **&lt;named-native-query /&gt;** ，包含 native SQL。

---

### 使用 @Query 注解

{% highlight java %}
public interface UserRepository extends JpaRepository<User, Long> {

    @Query("select u from User u where u.emailAddress = ?1")
    User findByEmailAddress(String emailAddress);
}
{% endhighlight %}

使用本地查询：

{% highlight java %}
public interface UserRepository extends JpaRepository<User, Long> {

    @Query(value = "SELECT * FROM USERS WHERE EMAIL_ADDRESS = ?1", nativeQuery = true)
    User findByEmailAddress(String emailAddress);
}
{% endhighlight %}

当前本地查询不支持动态的排序和分页，必须指定相应的查询语句：

{% highlight java %}
public interface UserRepository extends JpaRepository<User, Long> {

    @Query(value = "SELECT * FROM USERS WHERE LASTNAME = ?1",
        countQuery = "SELECT count(*) FROM USERS WHERE LASTNAME = ?1",
        nativeQuery = true)
    Page<User> findByLastname(String lastname, Pageable pageable);
}
{% endhighlight %}

---

### 使用位置参数

第一个位置参数用 **?1** 表示，第二个位置参数用 **?2** 表示，以此类推。

{% highlight java %}
public interface UserRepository extends Repository<User, Long> {

    @Query("select u from User u where u.emailAddress = ?1 and u.lastname = ?2")
    User findByLastnameOrFirstname(String lastname, String firstname);
}
{% endhighlight %}

---

### 高级 LIKE 参数

LIKE 参数可以在位置参数前加 **%** 字符。

{% highlight java %}
public interface UserRepository extends JpaRepository<User, Long> {

    @Query("select u from User u where u.firstname like %?1")
    List<User> findByFirstnameEndsWith(String firstname);
}
{% endhighlight %}

---

### 使用命名参数

命名参数要配合 **@Param** 注解使用。

{% highlight java %}
public interface UserRepository extends JpaRepository<User, Long> {

  @Query("select u from User u where u.firstname = :firstname or u.lastname = :lastname")
  User findByLastnameOrFirstname(@Param("lastname") String lastname,
        @Param("firstname") String firstname);
}
{% endhighlight %}

Spring 4 fully supports Java 8’s parameter name discovery based on the **-parameters** compiler flag. Using this flag in your build as an alternative to debug information, you can omit the **@Param** annotation for named parameters.

---

### 使用排序

可以通过 PageRequest 参数或 Sort 参数指定排序。默认在Order表达式中不允许使用函数调用，但是可以用JpaSort.unsafe()加上函数。

{% highlight java %}
public interface UserRepository extends JpaRepository<User, Long> {

    @Query("select u from User u where u.lastname like ?1%")
    List<User> findByAndSort(String lastname, Sort sort);

    @Query("select u.id, LENGTH(u.firstname) as fn_len from User u where u.lastname like ?1%")
    List<Object[]> findByAsArrayAndSort(String lastname, Sort sort);
}

// Valid Sort expression pointing to property in domain model.
repo.findByAndSort("lannister", new Sort("firstname"));               

// Invalid Sort containing function call. Thows Exception.
repo.findByAndSort("stark", new Sort("LENGTH(firstname)"));       

// Valid Sort containing explicitly unsafe Order.    
repo.findByAndSort("targaryen", JpaSort.unsafe("LENGTH(firstname)")); 

// Valid Sort expression pointing to aliased function.
repo.findByAsArrayAndSort("bolton", new Sort("fn_len"));    
{% endhighlight %}

---

### 使用 SpEL 表达式

在 @Query 注解中可以使用 SpEL 表达式。目前支持如下变量：

| **Variable**  | **Usage** | **Description** |
| entityName    | select x from #{#entityName} x | Inserts the entityName of the domain type associated with the given Repository. The entityName is resolved as follows: If the domain type has set the name property on the @Entity annotation then it will be used. Otherwise the simple class-name of the domain type will be used. |

<p>在查询方法中使用 SpEL 表达式：</p>

{% highlight java %}
@Entity
public class User {
    @Id
    @GeneratedValue
    Long id;

    String lastname;
}

public interface UserRepository extends JpaRepository<User,Long> {

    @Query("select u from #{#entityName} u where u.lastname = ?1")
    List<User> findByLastname(String lastname);
}
{% endhighlight %}

使用 **#{#entityName}** 更通用的方式是定义通用Repository方法：

{% highlight java %}
@MappedSuperclass
public abstract class AbstractMappedType {
    ... ... 
    String attribute
}

@Entity
public class ConcreteType extends AbstractMappedType { ... ... }

@NoRepositoryBean
public interface MappedTypeRepository<T extends AbstractMappedType>
    extends Repository<T, Long> {

    @Query("select t from #{#entityName} t where t.attribute = ?1")
    List<T> findAllByAttribute(String attribute);
}

public interface ConcreteRepository
    extends MappedTypeRepository<ConcreteType> { ... ... }
{% endhighlight %}

---

### 存储过程查询
---

使用 **@Procedure** 注解指定存储过程：

{% highlight java %}
@Procedure("plus1inout")
Integer explicitlyNamedPlus1inout(Integer arg);

@Procedure(procedureName = "plus1inout")
Integer plus1inout(Integer arg);
{% endhighlight %}

配合 **@NamedStoredProcedureQuery** 注解，使用命名存储过程查询：

{% highlight java %}
@Entity
@NamedStoredProcedureQuery(name = "User.plus1", procedureName = "plus1inout", parameters = {
    @StoredProcedureParameter(mode = ParameterMode.IN, name = "arg", type = Integer.class),
    @StoredProcedureParameter(mode = ParameterMode.OUT, name = "res", type = Integer.class) })
public class User { ... ... }

@Procedure(name = "User.plus1IO")
Integer entityAnnotatedCustomNamedProcedurePlus1IO(@Param("arg") Integer arg);

@Procedure
Integer plus1(@Param("arg") Integer arg);
{% endhighlight %}

---

### 查询返回类型

目前支持如下返回类型：

| **Return type** | **Description** | 
| void          | Denotes no return value. |
| Primitives    | Java primitives. | 
| Wrapper types | Java wrapper types. | 
| T             | An unique entity. Expects the query method to return one result at most. In case no result is found null is returned. More than one result will trigger an IncorrectResultSizeDataAccessException. | 
| Iterator&lt;T&gt;   | An Iterator. | 
| Collection&lt;T&gt; | A Collection. | 
| List&lt;T&gt;       | A List. | 
| Optional&lt;T&gt;   | A Java 8 or Guava Optional. Expects the query method to return one result at most. In case no result is found Optional.empty()/Optional.absent() is returned. More than one result will trigger an IncorrectResultSizeDataAccessException. | 
| Option&lt;T&gt;     | An either Scala or JavaSlang Option type. Semantically same behavior as Java 8’s Optional described above. | 
| Stream&lt;T&gt;     | A Java 8 Stream. | 
| Future&lt;T&gt;     | A Future. Expects method to be annotated with @Async and requires Spring’s asynchronous method execution capability enabled. | 
| CompletableFuture&lt;T&gt;    | A Java 8 CompletableFuture. Expects method to be annotated with @Async and requires Spring’s asynchronous method execution capability enabled. | 
| ListenableFuture              | A org.springframework.util.concurrent.ListenableFuture. Expects method to be annotated with @Async and requires Spring’s asynchronous method execution capability enabled. | 
| Slice         | A sized chunk of data with information whether there is more data available. Requires a Pageable method parameter. | 
| Page&lt;T&gt;       | A Slice with additional information, e.g. the total number of results. Requires a Pageable method parameter. | 
| GeoResult&lt;T&gt;  | A result entry with additional information, e.g. distance to a reference location. | 
| GeoResults&lt;T&gt; | A list of GeoResult&lt;T&gt; with additional information, e.g. average distance to a reference location. | 
| GeoPage&lt;T&gt;    | A Page with GeoResult&lt;T&gt;, e.g. average distance to a reference location. | 

---

### 更新查询

{% highlight java %}
@Modifying
@Query("update User u set u.firstname = ?1 where u.lastname = ?2")
int setFixedFirstnameFor(String firstname, String lastname);
{% endhighlight %}

更新查询执行后，**EntityManager** 可能会包含过期的数据，Spring JPA 不会自动清理(**EntityManager.clear()**)。如果你希望 **EntityManager** 执行完 **@Modifying** 查询后自动清理，可以设置 **@Modifying** 注解的 **clearAutomatically** 属性。