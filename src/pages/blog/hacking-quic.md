# Hacking QUIC
QUIC is pretty cool.
Dope even.
Let's bend it to our will.

We're going to hack QUIC.
"Hack" like a ROM-hack, not "hack" like a prison sentence (unless Nintendo is involved).
We're not trying to be malicious, but rather unlock new functionality while maintaining specification compliance.

We can do this easily because unlike TCP, QUIC is implemented in *userspace*.
That means we can take a QUIC library, tweak a few lines of code, and unlock new functionality while still being compliant with the spec.
We can ship our modified library as part of our (non-browser) client or server; nobody will suspect a thing.

The one disclaimer is that we can't modify web clients, as the browser safe-guards their previous UDP sockets like it's Fort Knox.
We have to use their QUIC library (via the WebTransport API), although that doesn't stop us from using a modified server.

## Proper QUIC Datagrams
I've been quite critical in the past about QUIC datagrams.
They are bait.
Developers want their beloved UDP datagrams are left disappointed if/when they learn about the underlying implementation.

QUIC datagrams are:
1. Congestion controlled.
2. Trigger acknowledgements.
3. Acknowledgements can't be surfaced to the application.
4. May be batched.

We can fix *some* of these short-comings by modifying a standard QUIC library.
Be warned though, you're entering dingus territory.

### Congestion Control
We've already established that you're a dingus.
QUIC libraries expect developers like you to show up, act like you know how networks behave, and send unlimited packets.
It was an explicit goal to not let you do that.

So let's do that.

There's nothing stopping a library from sending an unlimited number of QUIC datagrams.
You'll run into flow control limits with QUIC streams, but not with QUIC datagrams.
All we need to do is comment out one check.

But you do *need* congestion control if you're sending data over the Internet.
Otherwise you'll suffer from congestion, bufferbloat, high loss, and other symptoms that sound like a doctor's diagnosis.
But nobody said you have to use QUIC's congestion control; disable it and implement your own if you dare.

And note that this is not specific to QUIC datagrams.
You can use a custom congestion controller for QUIC streams too!

### Acknowledgements
This might sound bizarre if you're used to using UDP, but QUIC will explicitly acknowledge each datagram.
This is **not** used for retransmissions, instead it's only for congestion control.

So if we implement our own congestion control like above, we'll still get bombarded with potentially useless acknowledgements.
They are batched and quite efficient so it's not the end of the world, but so many dinguses see this as an affront.

If you control the receiver, you can tweak the `max_ack_delay`.
This is a parameter exchanged during the handshake that indicates how long the implementation can wait before sending an acknowledgement.
Crank it up to 1000ms (the default is 25ms) and the number of acknowledgement packets should slow to a trickle, acting almost as a keep-alive.

Be warned that this will (somewhat) impact other QUIC frames, especially STREAM retransmissions.
It may also throw a wrench into congestion controllers that expect timely feedback.
IMO only hack the ack delay if you've already hacked the sender to not care about acknowledgements, otherwise its not worth it.

### Batching
Most QUIC libraries will automatically fill a UDP packet with as much data as it can.
This is dope, but as we established, you're a dingus and can't have nice things.

Let's say you want to send 100 byte datagrams and don't want QUIC to coalesce them into a single UDP packet.
Maybe you're making a custom FEC scheme or something and you want the packets to be fully independent.

This is a terrible idea.
Your packets will still get coalesced at a lower level (ex. Ethernet, WiFi) that may even be using it's own FEC scheme.
More UDP packets means more context switching means worse performance.

But I'm here to pretend not to judge.
You can disable this coalescing on the sender side.


## Rapid Retransmit 
I was inspired to write this blog post because someone joined my (dope) Discord server.
They asked if they could do all of the above so they could implement their own acknowledgements and retransmissions.
...but why not use QUIC streams?

### Current State
One thing that doesn't handle well is real-time latency.

Let's say a packet gets lost over the network.
How does a QUIC library know?
The RFC outlines an algorithm that I'll attempt to simplify:

- The sender increments a sequence number for each packet.
- Upon receiving a packet, the receiver will schedule an ACK up to `max_ack_delay` in the future.
- If the sender does not receive an ACK after waiting multiple RTTs, it will send another packet (potentially an empty PING).
- After receiving an ACK, the sender will consider 

Before considering it lost, a typical QUIC library will not consider it lost until 3 newer packets have been received first, or a multiple of the RTT has elapsed.
A sender waits until an ACK has been 

## Application Limited 

## Hack the Library
https://github.com/quinn-rs/quinn/blob/6bfd24861e65649a7b00a9a8345273fe1d853a90/quinn-proto/src/frame.rs#L211
