---
layout: post
title: Pipeline调用流程
---

第一：NioSocketChannel获取pipeline实例，调用其fireChannelRead()。

{% highlight java %}
final ChannelPipeline pipeline = pipeline();
pipeline.fireChannelRead(byteBuf);
{% endhighlight %}


---

第二：DefaultChannelPipeline再调用AbstractChannelHandlerContext.invokeChannelRead()。

{% highlight java %}
public class DefaultChannelPipeline implements ChannelPipeline {

    final AbstractChannelHandlerContext head;
    final AbstractChannelHandlerContext tail;

    @Override
    public final ChannelPipeline fireChannelRead(Object msg) {
        AbstractChannelHandlerContext.invokeChannelRead(head, msg);
        return this;
    }
}
{% endhighlight %}

DefaultChannelPipeline构建了一个ChannelHandlerContext双向链表，inbound从前到后，outbound从后到前。

{% highlight java %}
public class DefaultChannelPipeline implements ChannelPipeline {

    final AbstractChannelHandlerContext head;
    final AbstractChannelHandlerContext tail;

    protected DefaultChannelPipeline(Channel channel) {
        tail = new TailContext(this);
        head = new HeadContext(this);

        // 链表现在是空的
        // head和tail表示链表的头和尾
        head.next = tail;
        tail.prev = head;
    }

    // 在链表前面添加一个元素
    private void addFirst0(AbstractChannelHandlerContext newCtx) {
        AbstractChannelHandlerContext nextCtx = head.next;
        newCtx.prev = head;
        newCtx.next = nextCtx;
        head.next = newCtx;
        nextCtx.prev = newCtx;
    }

    // 在链表末尾添加一个元素
    private void addLast0(AbstractChannelHandlerContext newCtx) {
        AbstractChannelHandlerContext prev = tail.prev;
        newCtx.prev = prev;
        newCtx.next = tail;
        prev.next = newCtx;
        tail.prev = newCtx;
    }
}
{% endhighlight %}


---

第三：AbstractChannelHandlerContext提供了一些静态方法，辅助调用invokeChannelRead()。

{% highlight java %}
abstract class AbstractChannelHandlerContext implements ChannelHandlerContext {

    // 注意，这里是静态方法
    static void invokeChannelRead(final AbstractChannelHandlerContext next, Object msg) {
        next.invokeChannelRead(m);
    }
}
{% endhighlight %}

注意，在DefaultChannelPipeline.fireChannelRead()调用AbstractChannelHandlerContext.invokeChannelRead()时，传入的参数是head，

所以，next = DefaultPipeline.head = HeadContext

上面的是AbstractChannelHandlerContext的静态方法，然后转到这里的实例方法。

{% highlight java %}
abstract class AbstractChannelHandlerContext implements ChannelHandlerContext {

    // 注意，这里是实例方法，上面是静态方法，两者参数也不同
    private void invokeChannelRead(Object msg) {
        if (invokeHandler()) {
            try {

                // 转而调用ChannelHandler的channelRead()
                ((ChannelInboundHandler) handler()).channelRead(this, msg);

            } catch (Throwable t) {
                notifyHandlerException(t);
            }
        } else {
            fireChannelRead(msg);
        }
    }
}
{% endhighlight %}


---

第四：调用ChannelHandler.channelRead()方法。

在AbstractChannelHandlerContext的invokeChannelRead()里面，会转而调用ChannelHandler的channelRead()。

因为next等于head，而且HeadContext实现了ChannelHander接口，所以最开始调用的是HeadContext的channelRead()。

{% highlight java %}
final class HeadContext extends AbstractChannelHandlerContext
            implements ChannelOutboundHandler, ChannelInboundHandler {

    HeadContext(DefaultChannelPipeline pipeline) {
        super(pipeline, null, HEAD_NAME, false, true);
    }

    @Override
    public void channelRead(ChannelHandlerContext ctx, Object msg) throws Exception {

        // 因为HeadContext实现了ChannelHandlerContext和ChannelHandler两种接口
        // 这里ctx = this = HeadContext
        ctx.fireChannelRead(msg);

    }

    // AbstractChannelHandlerContext定义方法
    @Override
    public ChannelHandlerContext fireChannelRead(final Object msg) {

        // 调用AbstractChannelHandlerContext的invokeChannelRead()方法
        // findContextInbound()是寻找下一个ChannelHandler

        // * * * * * * * * * * * * * * * * * * * * * * * * 
        //
        // 转移到第三步，这里是整个调用的关键
        //
        // 如果所有ChannelHandler都有调用ctx.fireChannelRead()，
        // 就会遍历到所有ChannelHandler
        //
        // 如果其中某个ChannelHandler没有调用ctx.fireChannelRead()，
        // 那这个遍历就断了，后面的ChannelHandler就不会被执行，当然这可能就是需要的
        // 
        // 因为ChannelPipeline是双向链表，这样可能会又执行到tail，然后又执行到head，又重复开始
        // 所以得有一个截至点
        // 这个截至点就在tail
        // TailConext.channelRead()就没有调用ctx.fireChannelRead()，
        // 
        // * * * * * * * * * * * * * * * * * * * * * * * * 

        invokeChannelRead(findContextInbound(), msg);

        return this;
    }

    // AbstractChannelHandlerContext定义方法
    // 寻找下一个ChannelHandler
    private AbstractChannelHandlerContext findContextInbound() {
        AbstractChannelHandlerContext ctx = this;
        do {
            ctx = ctx.next;
        } while (!ctx.inbound);
        return ctx;
    }
}
{% endhighlight %}


这个流程可以这样总结（=表示一定会执行，-表示可能会执行）：

{% highlight java %}
channel.fireChannelRead() 
    ===> head.channelRead() 
        ===> handler1.channelRead() 
            ---> handler2.channelRead()
                ---> handler3.channelRead()
                    ---> tail.channelRead()
{% endhighlight %}



对于出站来说，调用顺序是反方向的，从tail开始，到head结束。

{% highlight java %}
abstract class AbstractChannelHandlerContext implements ChannelHandlerContext {

    private AbstractChannelHandlerContext findContextOutbound() {
        AbstractChannelHandlerContext ctx = this;
        do {
            
            // 注意，这里是往前找
            ctx = ctx.prev;

        } while (!ctx.outbound);
        return ctx;
    }
}
{% endhighlight %}