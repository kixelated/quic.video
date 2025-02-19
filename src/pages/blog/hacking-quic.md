# Hacking QUIC
QUIC is pretty cool.
Dope even.
Let's bend it to our will.

We're going to hack QUIC.
"Hack" like a ROM-hack, not "hack" like a prison sentence (unless Nintendo is involved).
We're not trying to be malicious, but rather unlock new functionality while remaining compliant.

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
- Upon receiving a packet, the receiver will start a timer to ACK the sequence number, batching with any others that arrive within `max_ack_delay`.
- If the sender does not receive an ACK after waiting multiple RTTs, it will send another packet (like a PING) to poke the receiver.
- After finally receiving an ACK, the sender *may* decide that a packet was lost if:
  - 3 newer sequences were ACKed.
  - or a multiple of the RTT has elapsed.
- As the congestion controller allows, retransmit any lost packets and repeat. 

You don't need to understand the algorithm: I'll help.
If a packet is lost, it takes anywhere from 1-3 RTTs to detect the loss and retransmit.
It's particularly bad for the last few packets of a burst.

### We Can Do Better 
So how can we make QUIC better support real-time applications that can't wait multiple round trips?

The trick is that a QUIC receiver MUST be prepared to accept duplicate or redundant packets.
This can happen naturally if a packet is reordered or excessively queued over the network.
Nothing is stopping us from sending a boatload of packets.

Instead of sitting around doing nothing, our QUIC library could pre-emptively retransmit data even before it's considered lost.
Maybe we only enable this above a certain RTT where retransmissions cause unacceptable delay.
But sending redundant copies of data is nothing new; let's go a step further and embrace QUIC streams.

At the end of the day, a QUIC STREAM frame is a byte offset and payload.
Let's say we transmit our game state as STREAM 0-230 and 33ms later we transmit any deltas as STREAM 230-250.
If the original STREAM frame is lost, well we can't actually decode the delta and suffer from HEAD-OF-LINE blocking.

If latency is critical, you could instead modify the QUIC library to transmit STREAM 0-250 as the second packet.
There's no need to wait a fixed amount before retransmitting dependencies.

And this is exactly what the game dev was doing but using a custom UDP protocol, complete with acknowledgements and all sorts of stuff QUIC provides for free.
Forking a library and changing a few lines feels *so wrong* but it can a valid solution.

## Application Limited 

## Hack the Library
https://github.com/quinn-rs/quinn/blob/6bfd24861e65649a7b00a9a8345273fe1d853a90/quinn-proto/src/frame.rs#L211
