---
layout: post
title: Spring JPA - 实体审计
---

Spring JPA 用下面四个注解实现审计功能：

* @CreatedDate

* @CreatedBy

* @LastModifiedDate

* @LastModifiedBy

AuditableUser.java:

{% highlight java %}
@Entity
@EntityListeners(AuditingEntityListener.class)
public class AuditableUser {

    private @Id @GeneratedValue Long id;
    private String username;

    private @CreatedDate LocalDateTime createdDate;
    private @LastModifiedDate LocalDateTime lastModifiedDate;

    private @ManyToOne @CreatedBy AuditableUser createdBy;
    private @ManyToOne @LastModifiedBy AuditableUser lastModifiedBy;
}
{% endhighlight %}

AuditorAwareImpl.java:

{% highlight java %}
public class AuditorAwareImpl implements AuditorAware<AuditableUser> {

    public AuditableUser getCurrentAuditor() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        
        if (authentication == null || !authentication.isAuthenticated()) {
            return null;
        }

        return ((AuditableUser) authentication.getPrincipal()).getUser();
    }
}
{% endhighlight %}

AuditableUserRepository.java：

{% highlight java %}
public interface AuditableUserRepository extends CrudRepository<AuditableUser, Long> {}
{% endhighlight %}

AuditingConfiguration.java：

{% highlight java %}
@Configuration
@EnableJpaAuditing
class AuditingConfiguration {

    @Bean
    AuditorAwareImpl auditorAware() {
        return new AuditorAwareImpl();
    }
}
{% endhighlight %}