---
layout: post
title: Motan编码与解码
---

Motan在使用netty时，创建了自己的私有协议。这里将该协议的编码和解码过程做一下说明。

该协议由消息头和数据两部分注册。消息头长度为固定16个字节，数据长度不固定，其长度通过消息头说明。

{% highlight java %}
+-------+--------+--------------------------------+----------------+--------------+
0       2        4                               12               16              |  
| MAGIC |  TYPE  |           REQUEST_ID           |    DATA-LEN    |      DATA    |
+-------+--------+--------------------------------+----------------+--------------+
{% endhighlight %}

补充说明一下JAVA中8种基本类型的字节长度：
* byte 1字节
* short 2字节
* int 4字节
* long 8字节
* float 4字节
* double 8字节
* char 2字节
* boolean 1字节

---

协议说明：
* 从0开始的2个字节：short，协议标识，NETTY_MAGIC_TYPE = 0xF1F1。
* 从2开始的2个字节：short，消息类型，FLAG_REQUEST = 0x00，FLAG_RESPONSE = 0x01，FLAG_RESPONSE_VOID = 0x03。
* 从4开始的8个字节：long，请求ID。
* 从12开始的4个字节：int，数据长度。

---

### Encoder 编码

{% highlight java %}
public class NettyEncoder extends OneToOneEncoder 

    @Override
    protected Object encode(ChannelHandlerContext ctx, Channel nettyChannel, Object message) throws Exception {
        
        long requestId = getRequestId(message);

        // message是要传递的对象，
        // 通过codec转换成二进制数据
        byte[] data = codec.encode(client, message);

        // NETTY_HEADER=16，创建消息头，其长度固定=16
        byte[] transportHeader = new byte[MotanConstants.NETTY_HEADER];

        // 协议标识，short类型=2个字节，从偏移量0开始
        ByteUtil.short2bytes(MotanConstants.NETTY_MAGIC_TYPE, transportHeader, 0);

        // 消息类型，short类型=2个字节，从偏移量2开始
        // 因为类型只有1、2，3这几种类型，
        // 将它放到3字节，2字节没有赋值，为0
        // 按照小端Littile Endian模式，高字节在前，低字节在后，读取出来的short=0x0001或0x0002，
        // 这样处理也是正确的
        transportHeader[3] = getType(message);

        // 请求ID，long类型=8个字节，从偏移量4开始
        ByteUtil.long2bytes(getRequestId(message), transportHeader, 4);

        // 数据长度，int类型=4个字节，从偏移量12开始
        ByteUtil.int2bytes(data.length, transportHeader, 12);

        // 合并消息头和数据
        return ChannelBuffers.wrappedBuffer(transportHeader, data);
    }

    private byte getType(Object message) {
        if (message instanceof Request) {
            return MotanConstants.FLAG_REQUEST;
        } else if (message instanceof Response) {
            return MotanConstants.FLAG_RESPONSE;
        } else {
            return MotanConstants.FLAG_OTHER;
        }
    }
}
{% endhighlight %}


---

### Decoder 解码

{% highlight java %}
public class NettyDecoder extends FrameDecoder {

    @Override
    protected Object decode(ChannelHandlerContext ctx, Channel channel, ChannelBuffer buffer) 
                throws Exception {

        // 可读数据长度必须大于NETTY_HEADER=16，才是合理的
        if (buffer.readableBytes() <= MotanConstants.NETTY_HEADER) {
            return null;
        }

        buffer.markReaderIndex();

        // 协议标识，short类型=2个字节，从偏移量0开始
        short type = buffer.readShort();        
        if (type != MotanConstants.NETTY_MAGIC_TYPE) {
            buffer.resetReaderIndex();
            throw new MotanFrameworkException("NettyDecoder transport header not support, type: " + type);
        }

        // 消息类型，short类型=2个字节，从偏移量2开始
        byte messageType = (byte) buffer.readShort();

        // 请求ID，long类型=8个字节，从偏移量4开始
        long requestId = buffer.readLong();

        // 数据长度，int类型=4个字节，从偏移量12开始
        int dataLength = buffer.readInt();

        // 后面的数据，其长度要>=dataLength
        if (buffer.readableBytes() < dataLength) {
            buffer.resetReaderIndex();
            return null;
        }
        
        // 数据，先是二进制格式
        byte[] data = new byte[dataLength];
        buffer.readBytes(data);

        // 将二进制的数据转换成对象
        return codec.decode(client, data);
    }
}
{% endhighlight %}