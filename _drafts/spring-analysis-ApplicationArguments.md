---
layout: post
title: Spring Analysis - ApplicationArguments
---

**SpringApplication** 启动时，执行 **run()** 方法，创建 **ApplicationArguments** 对象。

{% highlight java %}
public class SpringApplication {
    public ConfigurableApplicationContext run(String... args) {
        ApplicationArguments applicationArguments = new DefaultApplicationArguments(args);

        ... ...
    }
}
{% endhighlight %}

然后通过 **prepareContext()** 将 **ApplicationArguments** 对象注入到 **ApplicationContext**。

{% highlight java %}
private void prepareContext(ConfigurableApplicationContext context,
        ConfigurableEnvironment environment, SpringApplicationRunListeners listeners,
        ApplicationArguments applicationArguments, Banner printedBanner) {

    ... ...

    // Add boot specific singleton beans
    context.getBeanFactory().registerSingleton("springApplicationArguments",
            applicationArguments);

    if (printedBanner != null) {
        context.getBeanFactory().registerSingleton("springBootBanner", printedBanner);
    }

    ... ...
}
{% endhighlight %}

**ApplicationArguments** 接口表示的是应用程序的参数。

{% highlight java %}
package org.springframework.boot;

public interface ApplicationArguments {

    /**
     * Return the raw unprocessed arguments that were passed to the application.
     * @return the arguments
     */
    String[] getSourceArgs();

    /**
     * Return then names of all option arguments. For example, if the arguments were
     * "--foo=bar --debug" would return the values {@code ["foo", "debug"]}.
     * @return the option names or an empty set
     */
    Set<String> getOptionNames();

    /**
     * Return whether the set of option arguments parsed from the arguments contains an
     * option with the given name.
     * @param name the name to check
     * @return {@code true} if the arguments contain an option with the given name
     */
    boolean containsOption(String name);

    /**
     * Return the collection of values associated with the arguments option having the
     * given name.
     * <ul>
     * <li>if the option is present and has no argument (e.g.: "--foo"), return an empty
     * collection ({@code []})</li>
     * <li>if the option is present and has a single value (e.g. "--foo=bar"), return a
     * collection having one element ({@code ["bar"]})</li>
     * <li>if the option is present and has multiple values (e.g. "--foo=bar --foo=baz"),
     * return a collection having elements for each value ({@code ["bar", "baz"]})</li>
     * <li>if the option is not present, return {@code null}</li>
     * </ul>
     * @param name the name of the option
     * @return a list of option values for the given name
     */
    List<String> getOptionValues(String name);

    /**
     * Return the collection of non-option arguments parsed.
     * @return the non-option arguments or an empty list
     */
    List<String> getNonOptionArgs();
}
{% endhighlight %}

**ApplicationArguments** 的实现类是 **DefaultApplicationArguments**。

{% highlight java %}
package org.springframework.boot;

public class DefaultApplicationArguments implements ApplicationArguments {

    private final Source source;

    private final String[] args;

    public DefaultApplicationArguments(String[] args) {
        Assert.notNull(args, "Args must not be null");
        this.source = new Source(args);
        this.args = args;
    }

    @Override
    public String[] getSourceArgs() {
        return this.args;
    }

    @Override
    public Set<String> getOptionNames() {
        String[] names = this.source.getPropertyNames();
        return Collections.unmodifiableSet(new HashSet<String>(Arrays.asList(names)));
    }

    @Override
    public boolean containsOption(String name) {
        return this.source.containsProperty(name);
    }

    @Override
    public List<String> getOptionValues(String name) {
        List<String> values = this.source.getOptionValues(name);
        return (values == null ? null : Collections.unmodifiableList(values));
    }

    @Override
    public List<String> getNonOptionArgs() {
        return this.source.getNonOptionArgs();
    }

    private static class Source extends SimpleCommandLinePropertySource {

        Source(String[] args) {
            super(args);
        }

        @Override
        public List<String> getNonOptionArgs() {
            return super.getNonOptionArgs();
        }

        @Override
        public List<String> getOptionValues(String name) {
            return super.getOptionValues(name);
        }
    }
}
{% endhighlight %}

**DefaultApplicationArguments** 内置的 **Source** 类继承自 **SimpleCommandLinePropertySource**。

{% highlight java %}
package org.springframework.core.env;

/**
 * {@link CommandLinePropertySource} implementation backed by a simple String array.
 *
 * <h3>Purpose</h3>
 * This {@code CommandLinePropertySource} implementation aims to provide the simplest
 * possible approach to parsing command line arguments.  As with all {@code
 * CommandLinePropertySource} implementations, command line arguments are broken into two
 * distinct groups: <em>option arguments</em> and <em>non-option arguments</em>, as
 * described below <em>(some sections copied from Javadoc for {@link SimpleCommandLineArgsParser})</em>:
 *
 * <h3>Working with option arguments</h3>
 * Option arguments must adhere to the exact syntax:
 * <pre class="code">--optName[=optValue]</pre>
 * That is, options must be prefixed with "{@code --}", and may or may not specify a value.
 * If a value is specified, the name and value must be separated <em>without spaces</em>
 * by an equals sign ("=").
 *
 * <h4>Valid examples of option arguments</h4>
 * <pre class="code">
 * --foo
 * --foo=bar
 * --foo="bar then baz"
 * --foo=bar,baz,biz</pre>
 *
 * <h4>Invalid examples of option arguments</h4>
 * <pre class="code">
 * -foo
 * --foo bar
 * --foo = bar
 * --foo=bar --foo=baz --foo=biz</pre>
 *
 * <h3>Working with non-option arguments</h3>
 * Any and all arguments specified at the command line without the "{@code --}" option
 * prefix will be considered as "non-option arguments" and made available through the
 * {@link #getNonOptionArgs()} method.
 *
 * <h2>Typical usage</h2>
 * <pre class="code">
 * public static void main(String[] args) {
 *     PropertySource<?> ps = new SimpleCommandLinePropertySource(args);
 *     // ...
 * }</pre>
 *
 * See {@link CommandLinePropertySource} for complete general usage examples.
 *
 * <h3>Beyond the basics</h3>
 *
 * <p>When more fully-featured command line parsing is necessary, consider using
 * the provided {@link JOptCommandLinePropertySource}, or implement your own
 * {@code CommandLinePropertySource} against the command line parsing library of your
 * choice!
 *
 * @author Chris Beams
 * @since 3.1
 * @see CommandLinePropertySource
 * @see JOptCommandLinePropertySource
 */
public class SimpleCommandLinePropertySource extends CommandLinePropertySource<CommandLineArgs> {

    /**
     * Create a new {@code SimpleCommandLinePropertySource} having the default name
     * and backed by the given {@code String[]} of command line arguments.
     * @see CommandLinePropertySource#COMMAND_LINE_PROPERTY_SOURCE_NAME
     * @see CommandLinePropertySource#CommandLinePropertySource(Object)
     */
    public SimpleCommandLinePropertySource(String... args) {
        super(new SimpleCommandLineArgsParser().parse(args));
    }

    /**
     * Create a new {@code SimpleCommandLinePropertySource} having the given name
     * and backed by the given {@code String[]} of command line arguments.
     */
    public SimpleCommandLinePropertySource(String name, String[] args) {
        super(name, new SimpleCommandLineArgsParser().parse(args));
    }

    /**
     * Get the property names for the option arguments.
     */
    @Override
    public String[] getPropertyNames() {
        return source.getOptionNames().toArray(new String[source.getOptionNames().size()]);
    }

    @Override
    protected boolean containsOption(String name) {
        return this.source.containsOption(name);
    }

    @Override
    protected List<String> getOptionValues(String name) {
        return this.source.getOptionValues(name);
    }

    @Override
    protected List<String> getNonOptionArgs() {
        return this.source.getNonOptionArgs();
    }
}
{% endhighlight %}

**SimpleCommandLinePropertySource** 构造器使用 **SimpleCommandLineArgsParser** 类解析命令参数，并返回 **CommandLineArgs**。

{% highlight java %}
package org.springframework.core.env;

/**
 * Parses a {@code String[]} of command line arguments in order to populate a
 * {@link CommandLineArgs} object.
 *
 * <h3>Working with option arguments</h3>
 * Option arguments must adhere to the exact syntax:
 * <pre class="code">--optName[=optValue]</pre>
 * That is, options must be prefixed with "{@code --}", and may or may not specify a value.
 * If a value is specified, the name and value must be separated <em>without spaces</em>
 * by an equals sign ("=").
 *
 * <h4>Valid examples of option arguments</h4>
 * <pre class="code">
 * --foo
 * --foo=bar
 * --foo="bar then baz"
 * --foo=bar,baz,biz</pre>
 *
 * <h4>Invalid examples of option arguments</h4>
 * <pre class="code">
 * -foo
 * --foo bar
 * --foo = bar
 * --foo=bar --foo=baz --foo=biz</pre>
 *
 * <h3>Working with non-option arguments</h3>
 * Any and all arguments specified at the command line without the "{@code --}" option
 * prefix will be considered as "non-option arguments" and made available through the
 * {@link CommandLineArgs#getNonOptionArgs()} method.
 *
 * @author Chris Beams
 * @since 3.1
 */
class SimpleCommandLineArgsParser {

    /**
     * Parse the given {@code String} array based on the rules described {@linkplain
     * SimpleCommandLineArgsParser above}, returning a fully-populated
     * {@link CommandLineArgs} object.
     * @param args command line arguments, typically from a {@code main()} method
     */
    public CommandLineArgs parse(String... args) {
        CommandLineArgs commandLineArgs = new CommandLineArgs();
        for (String arg : args) {
            if (arg.startsWith("--")) {
                String optionText = arg.substring(2, arg.length());
                String optionName;
                String optionValue = null;
                if (optionText.contains("=")) {
                    optionName = optionText.substring(0, optionText.indexOf("="));
                    optionValue = optionText.substring(optionText.indexOf("=")+1, optionText.length());
                }
                else {
                    optionName = optionText;
                }
                if (optionName.isEmpty() || (optionValue != null && optionValue.isEmpty())) {
                    throw new IllegalArgumentException("Invalid argument syntax: " + arg);
                }
                commandLineArgs.addOptionArg(optionName, optionValue);
            }
            else {
                commandLineArgs.addNonOptionArg(arg);
            }
        }
        return commandLineArgs;
    }
}

class CommandLineArgs {

    private final Map<String, List<String>> optionArgs = new HashMap<String, List<String>>();
    private final List<String> nonOptionArgs = new ArrayList<String>();

    /**
     * Add an option argument for the given option name and add the given value to the
     * list of values associated with this option (of which there may be zero or more).
     * The given value may be {@code null}, indicating that the option was specified
     * without an associated value (e.g. "--foo" vs. "--foo=bar").
     */
    public void addOptionArg(String optionName, String optionValue) {
        if (!this.optionArgs.containsKey(optionName)) {
            this.optionArgs.put(optionName, new ArrayList<String>());
        }
        if (optionValue != null) {
            this.optionArgs.get(optionName).add(optionValue);
        }
    }

    /**
     * Return the set of all option arguments present on the command line.
     */
    public Set<String> getOptionNames() {
        return Collections.unmodifiableSet(this.optionArgs.keySet());
    }

    /**
     * Return whether the option with the given name was present on the command line.
     */
    public boolean containsOption(String optionName) {
        return this.optionArgs.containsKey(optionName);
    }

    /**
     * Return the list of values associated with the given option. {@code null} signifies
     * that the option was not present; empty list signifies that no values were associated
     * with this option.
     */
    public List<String> getOptionValues(String optionName) {
        return this.optionArgs.get(optionName);
    }

    /**
     * Add the given value to the list of non-option arguments.
     */
    public void addNonOptionArg(String value) {
        this.nonOptionArgs.add(value);
    }

    /**
     * Return the list of non-option arguments specified on the command line.
     */
    public List<String> getNonOptionArgs() {
        return Collections.unmodifiableList(this.nonOptionArgs);
    }

}
{% endhighlight %}