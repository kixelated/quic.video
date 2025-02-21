# Hacking QUIC
We're going to hack QUIC.
"Hack" like a ROM-hack, not "hack" like a prison sentence (unless Nintendo is involved).
We're not trying to be malicious, but rather unlock new functionality while remaining compliant with the specification.
That's a top 10 nerd pickup line right there.

We can do this easily because unlike TCP, QUIC is implemented in *userspace*.
That means we can take a QUIC library, tweak a few lines of code, and unlock new functionality while still being compliant with the spec.
We can ship our modified library as part of our application; nobody will suspect a thing.

The one disclaimer is that we can't modify web clients, as the browser safe-guards their previous UDP sockets like it's Fort Knox.
We have to use the WebTransport API which uses the browser's built in QUIC library.
Although that doesn't stop us from using a modified server so many of these are still possible.

## Proper QUIC Datagrams
I've been quite critical in the past about QUIC datagrams.
Bold statements like "they are bait" and "never use datagrams".
But some developers don't want to know the truth, and just want their beloved UDP datagrams.

The problem is that QUIC datagrams are not UDP datagrams, they are:
1. Congestion controlled.
2. Trigger acknowledgements.
3. Acknowledgements can't be surfaced to the application.
4. May be batched.

We can fix *some* of these short-comings by modifying a standard QUIC library.
Be warned though, you're entering dingus territory.

### Congestion Control
We've already established that you're a dingus.
QUIC libraries expect developers like to act like you understand how networks behave and send unlimited packets.
It was an explicit goal to not let you do that.

So let's do it anyway.

The "truth" is that there's nothing stopping a library from sending an unlimited number of QUIC datagrams.
The specification is the equivalent of a pinky promise because there's no mechanism to enforce a limit on the receiving end.
You'll run into flow control limits with QUIC streams, but not with QUIC datagrams.
All we need to do is comment out one check.

But you do *need* congestion control if you're sending data over the Internet.
Otherwise you'll suffer from congestion, bufferbloat, high loss, and other symptoms 
These are not symptoms of the latest disease kept under wraps by the Trump administration, but rather a reality of the internet being a shared resource.
But nobody said you *have* to use QUIC's congestion control; disable it and implement your own if you dare.

percentile meme

And note that congestion control is not specific to QUIC datagrams.
You can use a custom congestion controller for QUIC streams too!

### Acknowledgements
This might sound bizarre if you're used to using UDP, but QUIC will explicitly acknowledge each datagram.
However, these are **not** used for retransmissions, so what are they for?

...they're only for congestion control.
But we just disabled QUIC's congestion control!
We'll just get bombarded with useless acknowledgements.
They are batched and quite efficient so it's not the end of the world, but I can already feel your angst.

The most cleverest of dinguses amongst us (amogus?) may think you could leverage these ACKs for your own application.
Unfortunately, there's an edge case discovered by yours truely where QUIC may acknowledge a datagram but never deliver it to the application.
So if you're using QUIC datagrams, yes you do have to implement your own ACK/NACK protocol in the application and yes, it does feel terrible.

But let's get rid of these useless ACKs.
If you control the receiver, you can tweak the `max_ack_delay`.
This is a parameter exchanged during the handshake that indicates how long the implementation can wait before sending an acknowledgement.
Crank it up to 1000ms (the default is 25ms) and the number of acknowledgement packets should slow to a trickle, acting almost as a keep-alive.

Be warned that this will (somewhat) impact other QUIC frames, especially STREAM retransmissions.
It may also throw a wrench into congestion controllers that expect timely feedback.
IMO only hack the ack delay if you've already hacked the sender to not care about acknowledgements, otherwise its not worth it, and even then it's borderline.

### Batching
Most QUIC libraries will automatically fill a UDP packet with as much data as it can.
This is dope, but as we established, you're a dingus and can't have nice things.

Let's say you want to send 100 byte datagrams and don't want QUIC to coalesce them into a single UDP packet.
Maybe you're making a custom FEC scheme or something and you want the packets to be fully independent.

I interupt this example to proclaim that this is a terrible idea.
Your packets will still get coalesced at a lower level (ex. Ethernet, WiFi) that may even be using it's own FEC scheme.
More UDP packets means more context switching means worse performance.

But I'm here to pretend not to judge.
You can disable this coalescing on the sender side.
Tweak a few lines of code and boop, you're sending a proper UDP packet for each QUIC datagram.


## Rapid Retransmit 
I was inspired to write this blog post because someone joined my (dope) Discord server.
They asked if they could do all of the above so they could implement their own acknowledgements and retransmissions.

So I asked them... why not use QUIC streams?
They already provide reliability, ordering, and can be cancelled.
What more could you want?

### What More Could We Want?
QUIC is pretty poor for real-time latency.
It's not designed for small payloads that need to arrive ASAP, even if it means worse efficiency.

Let's say a packet gets lost over the network.
How does a QUIC library know?

The unfortunate reality (for now) is that there's no explicit signal.
A QUIC library has to use maths and logic to make an educated guess that a packet is lost and needs to be retransmitted.
The RFC outlines an algorithm that I'll attempt to simplify:

- The sender increments a sequence number for each packet.
- Upon receiving a packet, the receiver will start a timer to ACK the sequence number, batching with any others that arrive within `max_ack_delay`.
- If the sender does not receive an ACK after waiting multiple RTTs, it will send another packet (like a PING) to poke the receiver.
- After finally receiving an ACK, the sender *may* decide that a packet was lost if:
  - 3 newer sequences were ACKed.
  - or a multiple of the RTT has elapsed.
- As the congestion controller allows, retransmit any lost packets and repeat. 

Skipped that boring wall of text?
I don't blame you.
You're just here for the funny blog and *maaaaybe* learn something along the way.

I'll help.
If a packet is lost, it takes anywhere from 1-3 RTTs to detect the loss and retransmit.
It's particularly bad for the last few packets of a burst.
That means if you're trying to send data cross-continent, some data will randomly take 100ms to 200ms longer to deliver.

### We Can Do Better 
So how can we make QUIC better support real-time applications that can't wait multiple round trips?

The trick is that a QUIC receiver MUST be prepared to accept duplicate or redundant packets.
This can happen naturally if a packet is reordered or excessively queued over the network.
You might see where this is going: nothing can stop us from abusing this behavior and sending a boatload of packets.

Instead of sitting around doing nothing, our QUIC library could pre-emptively retransmit data even before it's considered lost.
Maybe we only enable this above a certain RTT where retransmissions cause unacceptable delay.
But sending redundant copies of data is nothing new; let's go a step further and embrace QUIC streams.

At the end of the day, a QUIC STREAM frame is a byte offset and payload.
Let's say we transmit our game state as STREAM 0-230 and 33ms later we transmit 20 bytes of deltas as STREAM 230-250.
If the original STREAM frame is lost, well even if we receive those 20 bytes, we can't actually decode them and suffer from HEAD-OF-LINE blocking.

My game dev friend thinks this is unacceptable and made his own ACK-based algorithm on top of QUIC datagrams instead.
The sender ticks every 30ms and sends a delta from the last acknowledged state, even if that data might be in-flight already.
Pretty cool right?
Why doesn't QUIC do this?

It does.

(mind blown)

QUIC will retransmit any unacknowledged fragments of a stream.
But like I said above, only when a packet is considered lost.
But with the power of h4cks, we could have the QUIC library *assume* the rest of the stream is lost and needs to be retransmitted.
For you library maintainers out there, consider adding this as a `stream.retransmit()` method and feel free to forge my username into the git commit.

So to continue our example above, we can modify QUIC to send byte offsets 0-250 instead of just 230-250.
And now we can accomplish the exact* same behavior as the game dev but without custom acknowledgements, retransmissions, deltas, and reassembly buffers.

Forking a library feels *so dirty* but it magically works.


### Some Caveats
Okay it's not the same as the game dev solution; it's actually better.

Retransmitting data can quickly balloon out of control.
Congestion can cause bufferbloat, which is when routers queue packets instead of dropping them.
If you retransmit every 30ms, but let's say congestion causes the RTT to (temporarily) increase to 500ms... well now you're transmitting 15x the data and further aggravating any congestion.
It's a vicious loop and you've basically built your own DDoS agent.

This is yet another reason why you should never disable congestion control.
Yes, I'm still scarred by a Q&A "question" after one of my talks.
Your home grown live video protocol without congestion control is not novel or smart.

QUIC retransmission are gated by congestion control, so while your real-time application may be clammoring for MORE PACKETS, fortunately QUIC is smart enough to ignore you.
If the network is fully saturated, you need to send fewer packets to drain any queues, not more.

And if the network is fully saturated, or the receiver just drove through a tunnel with no internet access (increasingly rare), you can start over.
Cancel the previous QUIC stream and make a new one once the deltas become larger than a snapshot.
It's that easy.

## Application Limited 

## Hack the Library
https://github.com/quinn-rs/quinn/blob/6bfd24861e65649a7b00a9a8345273fe1d853a90/quinn-proto/src/frame.rs#L211
