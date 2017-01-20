---
layout: post
title: Spring Mvc - RequestContextHolder
---

org.springframework.web.context.request.RequestContextHolder:

{% highlight java %}
package org.springframework.web.context.request;

/**
 * Holder class to expose the web request in the form of a thread-bound
 * {@link RequestAttributes} object. The request will be inherited
 * by any child threads spawned by the current thread if the
 * {@code inheritable} flag is set to {@code true}.
 *
 * <p>Use {@link RequestContextListener} or
 * {@link org.springframework.web.filter.RequestContextFilter} to expose
 * the current web request. Note that
 * {@link org.springframework.web.servlet.DispatcherServlet} and
 * {@link org.springframework.web.portlet.DispatcherPortlet} already
 * expose the current request by default.
 *
 * @author Juergen Hoeller
 * @author Rod Johnson
 * @since 2.0
 * @see RequestContextListener
 * @see org.springframework.web.filter.RequestContextFilter
 * @see org.springframework.web.servlet.DispatcherServlet
 * @see org.springframework.web.portlet.DispatcherPortlet
 */
public abstract class RequestContextHolder  {

    /**
     * Reset the RequestAttributes for the current thread.
     */
    public static void resetRequestAttributes() {
        requestAttributesHolder.remove();
        inheritableRequestAttributesHolder.remove();
    }

    /**
     * Bind the given RequestAttributes to the current thread,
     * <i>not</i> exposing it as inheritable for child threads.
     * @param attributes the RequestAttributes to expose
     * @see #setRequestAttributes(RequestAttributes, boolean)
     */
    public static void setRequestAttributes(RequestAttributes attributes) {
        setRequestAttributes(attributes, false);
    }

    /**
     * Bind the given RequestAttributes to the current thread.
     * @param attributes the RequestAttributes to expose,
     * or {@code null} to reset the thread-bound context
     * @param inheritable whether to expose the RequestAttributes as inheritable
     * for child threads (using an {@link InheritableThreadLocal})
     */
    public static void setRequestAttributes(RequestAttributes attributes, boolean inheritable) {
        if (attributes == null) {
            resetRequestAttributes();
        }
        else {
            if (inheritable) {
                inheritableRequestAttributesHolder.set(attributes);
                requestAttributesHolder.remove();
            }
            else {
                requestAttributesHolder.set(attributes);
                inheritableRequestAttributesHolder.remove();
            }
        }
    }

    /**
     * Return the RequestAttributes currently bound to the thread.
     * @return the RequestAttributes currently bound to the thread,
     * or {@code null} if none bound
     */
    public static RequestAttributes getRequestAttributes() {
        RequestAttributes attributes = requestAttributesHolder.get();
        if (attributes == null) {
            attributes = inheritableRequestAttributesHolder.get();
        }
        return attributes;
    }

    /**
     * Return the RequestAttributes currently bound to the thread.
     * <p>Exposes the previously bound RequestAttributes instance, if any.
     * Falls back to the current JSF FacesContext, if any.
     * @return the RequestAttributes currently bound to the thread
     * @throws IllegalStateException if no RequestAttributes object
     * is bound to the current thread
     * @see #setRequestAttributes
     * @see ServletRequestAttributes
     * @see FacesRequestAttributes
     * @see javax.faces.context.FacesContext#getCurrentInstance()
     */
    public static RequestAttributes currentRequestAttributes() throws IllegalStateException {
        RequestAttributes attributes = getRequestAttributes();
        if (attributes == null) {
            if (jsfPresent) {
                attributes = FacesRequestAttributesFactory.getFacesRequestAttributes();
            }
            if (attributes == null) {
                throw new IllegalStateException("No thread-bound request found: " +
                        "Are you referring to request attributes outside of an actual web request, " +
                        "or processing a request outside of the originally receiving thread? " +
                        "If you are actually operating within a web request and still receive this message, " +
                        "your code is probably running outside of DispatcherServlet/DispatcherPortlet: " +
                        "In this case, use RequestContextListener or RequestContextFilter to expose the current request.");
            }
        }
        return attributes;
    }


    /**
     * Inner class to avoid hard-coded JSF dependency.
     */
    private static class FacesRequestAttributesFactory {

        public static RequestAttributes getFacesRequestAttributes() {
            FacesContext facesContext = FacesContext.getCurrentInstance();
            return (facesContext != null ? new FacesRequestAttributes(facesContext) : null);
        }
    }

}
{% endhighlight %}

---

org.springframework.web.context.request.ServletRequestAttributes:

{% highlight java %}
package org.springframework.web.context.request;

/**
 * Servlet-based implementation of the {@link RequestAttributes} interface.
 *
 * <p>Accesses objects from servlet request and HTTP session scope,
 * with no distinction between "session" and "global session".
 *
 * @author Juergen Hoeller
 * @since 2.0
 * @see javax.servlet.ServletRequest#getAttribute
 * @see javax.servlet.http.HttpSession#getAttribute
 */
public class ServletRequestAttributes extends AbstractRequestAttributes {

    /**
     * Constant identifying the {@link String} prefixed to the name of a
     * destruction callback when it is stored in a {@link HttpSession}.
     */
    public static final String DESTRUCTION_CALLBACK_NAME_PREFIX =
            ServletRequestAttributes.class.getName() + ".DESTRUCTION_CALLBACK.";

    protected static final Set<Class<?>> immutableValueTypes = new HashSet<Class<?>>(16);

    static {
        immutableValueTypes.addAll(NumberUtils.STANDARD_NUMBER_TYPES);
        immutableValueTypes.add(Boolean.class);
        immutableValueTypes.add(Character.class);
        immutableValueTypes.add(String.class);
    }


    private final HttpServletRequest request;

    private HttpServletResponse response;

    private volatile HttpSession session;

    private final Map<String, Object> sessionAttributesToUpdate = new ConcurrentHashMap<String, Object>(1);


    /**
     * Create a new ServletRequestAttributes instance for the given request.
     * @param request current HTTP request
     */
    public ServletRequestAttributes(HttpServletRequest request) {
        Assert.notNull(request, "Request must not be null");
        this.request = request;
    }

    /**
     * Create a new ServletRequestAttributes instance for the given request.
     * @param request current HTTP request
     * @param response current HTTP response (for optional exposure)
     */
    public ServletRequestAttributes(HttpServletRequest request, HttpServletResponse response) {
        this(request);
        this.response = response;
    }


    /**
     * Exposes the native {@link HttpServletRequest} that we're wrapping.
     */
    public final HttpServletRequest getRequest() {
        return this.request;
    }

    /**
     * Exposes the native {@link HttpServletResponse} that we're wrapping (if any).
     */
    public final HttpServletResponse getResponse() {
        return this.response;
    }

    /**
     * Exposes the {@link HttpSession} that we're wrapping.
     * @param allowCreate whether to allow creation of a new session if none exists yet
     */
    protected final HttpSession getSession(boolean allowCreate) {
        if (isRequestActive()) {
            HttpSession session = this.request.getSession(allowCreate);
            this.session = session;
            return session;
        }
        else {
            // Access through stored session reference, if any...
            HttpSession session = this.session;
            if (session == null) {
                if (allowCreate) {
                    throw new IllegalStateException(
                            "No session found and request already completed - cannot create new session!");
                }
                else {
                    session = this.request.getSession(false);
                    this.session = session;
                }
            }
            return session;
        }
    }


    @Override
    public Object getAttribute(String name, int scope) {
        if (scope == SCOPE_REQUEST) {
            if (!isRequestActive()) {
                throw new IllegalStateException(
                        "Cannot ask for request attribute - request is not active anymore!");
            }
            return this.request.getAttribute(name);
        }
        else {
            HttpSession session = getSession(false);
            if (session != null) {
                try {
                    Object value = session.getAttribute(name);
                    if (value != null) {
                        this.sessionAttributesToUpdate.put(name, value);
                    }
                    return value;
                }
                catch (IllegalStateException ex) {
                    // Session invalidated - shouldn't usually happen.
                }
            }
            return null;
        }
    }

    @Override
    public void setAttribute(String name, Object value, int scope) {
        if (scope == SCOPE_REQUEST) {
            if (!isRequestActive()) {
                throw new IllegalStateException(
                        "Cannot set request attribute - request is not active anymore!");
            }
            this.request.setAttribute(name, value);
        }
        else {
            HttpSession session = getSession(true);
            this.sessionAttributesToUpdate.remove(name);
            session.setAttribute(name, value);
        }
    }

    @Override
    public void removeAttribute(String name, int scope) {
        if (scope == SCOPE_REQUEST) {
            if (isRequestActive()) {
                this.request.removeAttribute(name);
                removeRequestDestructionCallback(name);
            }
        }
        else {
            HttpSession session = getSession(false);
            if (session != null) {
                this.sessionAttributesToUpdate.remove(name);
                try {
                    session.removeAttribute(name);
                    // Remove any registered destruction callback as well.
                    session.removeAttribute(DESTRUCTION_CALLBACK_NAME_PREFIX + name);
                }
                catch (IllegalStateException ex) {
                    // Session invalidated - shouldn't usually happen.
                }
            }
        }
    }

    @Override
    public String[] getAttributeNames(int scope) {
        if (scope == SCOPE_REQUEST) {
            if (!isRequestActive()) {
                throw new IllegalStateException(
                        "Cannot ask for request attributes - request is not active anymore!");
            }
            return StringUtils.toStringArray(this.request.getAttributeNames());
        }
        else {
            HttpSession session = getSession(false);
            if (session != null) {
                try {
                    return StringUtils.toStringArray(session.getAttributeNames());
                }
                catch (IllegalStateException ex) {
                    // Session invalidated - shouldn't usually happen.
                }
            }
            return new String[0];
        }
    }

    @Override
    public void registerDestructionCallback(String name, Runnable callback, int scope) {
        if (scope == SCOPE_REQUEST) {
            registerRequestDestructionCallback(name, callback);
        }
        else {
            registerSessionDestructionCallback(name, callback);
        }
    }

    @Override
    public Object resolveReference(String key) {
        if (REFERENCE_REQUEST.equals(key)) {
            return this.request;
        }
        else if (REFERENCE_SESSION.equals(key)) {
            return getSession(true);
        }
        else {
            return null;
        }
    }

    @Override
    public String getSessionId() {
        return getSession(true).getId();
    }

    @Override
    public Object getSessionMutex() {
        return WebUtils.getSessionMutex(getSession(true));
    }


    /**
     * Update all accessed session attributes through {@code session.setAttribute}
     * calls, explicitly indicating to the container that they might have been modified.
     */
    @Override
    protected void updateAccessedSessionAttributes() {
        if (!this.sessionAttributesToUpdate.isEmpty()) {
            // Update all affected session attributes.
            HttpSession session = getSession(false);
            if (session != null) {
                try {
                    for (Map.Entry<String, Object> entry : this.sessionAttributesToUpdate.entrySet()) {
                        String name = entry.getKey();
                        Object newValue = entry.getValue();
                        Object oldValue = session.getAttribute(name);
                        if (oldValue == newValue && !isImmutableSessionAttribute(name, newValue)) {
                            session.setAttribute(name, newValue);
                        }
                    }
                }
                catch (IllegalStateException ex) {
                    // Session invalidated - shouldn't usually happen.
                }
            }
            this.sessionAttributesToUpdate.clear();
        }
    }

    /**
     * Determine whether the given value is to be considered as an immutable session
     * attribute, that is, doesn't have to be re-set via {@code session.setAttribute}
     * since its value cannot meaningfully change internally.
     * <p>The default implementation returns {@code true} for {@code String},
     * {@code Character}, {@code Boolean} and standard {@code Number} values.
     * @param name the name of the attribute
     * @param value the corresponding value to check
     * @return {@code true} if the value is to be considered as immutable for the
     * purposes of session attribute management; {@code false} otherwise
     * @see #updateAccessedSessionAttributes()
     */
    protected boolean isImmutableSessionAttribute(String name, Object value) {
        return (value == null || immutableValueTypes.contains(value.getClass()));
    }

    /**
     * Register the given callback as to be executed after session termination.
     * <p>Note: The callback object should be serializable in order to survive
     * web app restarts.
     * @param name the name of the attribute to register the callback for
     * @param callback the callback to be executed for destruction
     */
    protected void registerSessionDestructionCallback(String name, Runnable callback) {
        HttpSession session = getSession(true);
        session.setAttribute(DESTRUCTION_CALLBACK_NAME_PREFIX + name,
                new DestructionCallbackBindingListener(callback));
    }


    @Override
    public String toString() {
        return this.request.toString();
    }

}
{% endhighlight %}