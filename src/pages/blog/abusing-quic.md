# Abusing QUIC
We're going to hack QUIC.
"Hack" like a ROM-hack, not "hack" like a prison sentence.
Unless Nintendo is involved.

We're not trying to be malicious, but rather unlock new functionality while remaining compliant with the specification.
We can do this easily because unlike TCP, QUIC is implemented in *userspace*.
That means we can take a QUIC library, tweak a few lines of code, and unlock *new* functionality that the greybeards wanted to keep from us.
We can ship our modified library as part of our application; nobody will suspect a thing.

The one disclaimer is that we can't modify web clients; the browser safe-guards their precious UDP sockets like it's Fort Knox.
We have to use the WebTransport API which uses the browser's built in QUIC library.
Our server-side modifications will still work, but short of wasting a zero-day exploit, we can't modify the client.

But first, a disclaimer:

## Dingus Territory 
QUIC was designed with developers like *you* in mind.
Yes *you*, wearing your favorite "I 💕 node_modules" T-shirt about to rewrite your website again using the Next-est framework released literally seconds ago.

*You are a dingus*.

The greybeards that designed QUIC, the QUIC libraries, and the related web APIs do not respect you.
They think that given a shotgun, the first thing you're going to do is blow your own foot off.
And they're right of course.

That's why there is no UDP socket Web API.
WebRTC data channels claim to have "unreliable" messages but don't even get me started.
Heck, there's not even a TCP socket Web API; WebSockets force a HTTP handshake for *reasons*.

QUIC (via WebTransport) doesn't change that mentality.
You can't even disable encryption aka TLS aka HTTPS.
Because otherwise *some dingus* would disable it because they think it make computer go slow (it doesn't) and oh no now North Korea has some more bitcoins.
It's not a good look to provide users with unsafe APIs.

But let's suspend reality for a second.
Let's say that *You* are a savant who fully understands QUIC and networking.
You're here because you understand the ramifications of your actions and want to push the boundaries of QUIC.
That's great because I have a blog post for you.

For everyone else, heed my warnings.
Friends don't let friends design UDP protocols.
(And we're friends?)
You should start simple and use the intended QUIC API before reaching for that shotgun.


## Proper QUIC Datagrams
I've been quite critical in the past about QUIC datagrams.
Bold statements like "they are bait" and "never use datagrams".
But some developers don't want to know the truth and just want their beloved UDP datagrams.

The problem is that QUIC datagrams are *not* UDP datagrams.
That would be something closer to DTLS.
Instead, QUIC datagrams:
1. Are congestion controlled.
2. Trigger acknowledgements.
3. Do not expose these acknowledgements.
4. May be batched.

We're going to try to fix *some* of these short-comings by modifying a standard QUIC library.
Be warned though, you're entering dingus territory.

### Congestion Control
The "truth" is that there's nothing stopping a library from sending an unlimited number of QUIC datagrams.
There's only some black pixels on a text document forming the word SHOULD and sometimes SHOULD NOT.

"Congestion Control" is that SHOULD NOT preventing you from flooding the network.
There's many algorithms out there, but basically they guess if the network can handle more traffic.
The simplest form of congestion control is to send less data when packet loss is high.

But to the dingus, this looks like an artifical limit.
And it's true, many networks could sustain a higher throughput if this pesky congestion control is disabled.
All we need to do is comment out one check and bam, we can send QUIC datagrams at an unlimited rate.

I joke but PLEASE do not do this.

You *need* some form of congestion control if you're sending data over the internet.
Otherwise you'll suffer from congestion, bufferbloat, high loss, and other symptoms.
These are not symptoms of the latest disease kept under wraps by the Trump administration, but rather a reality of the internet being a shared resource.

But it's no fun starting a blog with back to back lectures.
We're here to abuse QUIC damnit, not the readers.

But nobody said that you have to use *QUIC's congestion control*.
It's pluggable, implement your own!
Unlike TCP, which buries the congestion controller in the kernel, QUIC libraries often expose it as an interace.
Found a startup where you pipe each ACK to ChatGPT and let the funding roll in.
Or do something boring and write a master's thesis.

percentile meme

And note that custom congestion control is not specific to QUIC datagrams.
You can use a custom congestion controller for QUIC streams too!

Or completely disable it, you do you.

### Acknowledgements
QUIC will reply with an acknowledgement packet are receiving each datagram.
This might sound absolutely bonkers if you're used to UDP.
These are **not** used for retransmissions, so what are they for?

...they're only for congestion control.
But what if we just disabled QUIC's congestion control!
Now we're going to get bombarded with useless acknowledgements!

The good news is that QUIC acknowledgements are batched, potentially at the end of your data packets, and aee quite efficient.
It's only a few extra bytes/packsts and not the end of the world, but I can already feel your angst.

The most cleverest of dinguses amongst us (amogus?) may think you could leverage these ACKs.
What if we used these otherwise "useless" ACKs to tell our application if a packet was received?
That way we won't have to implement our own ACK/NACK mechanism for reliability.

Unfortunately, there's an edge case discovered by yours truely where QUIC may acknowledge a datagram but not deliver it to the application.
This will happen if a QUIC library processes a packet but the application (ex. Javascript web page) is too slow.

So yes, if you're using QUIC datagrams, then you will have to implement your own ACK/NACK protocol in your application dor any reliable data.
One datagram will trigger a QUIC ACK, your custom ACK, and a QUIC ACK for your custom ACK.
Yes, it does feel terrible; like a mud shower on Wednesday.

So let's get rid of these useless ACKs.
If you control the receiver, you can tweak the `max_ack_delay`.
This is a parameter exchanged during the handshake that indicates how long the implementation can wait before sending an acknowledgement.
Crank it up to 1000ms (the default is 25ms) and the number of acknowledgement packets should slow to a trickle, acting almost as a keep-alive.

Be warned that this will impact all QUIC frames, *especially* STREAM retransmissions.
It may also throw a wrench into the congestion controller too as they expect timely feedback.
The chaos you've sown will be legendary.

So only consider this route if you've gone full dingus and completely disabled congestion control and retransmissions.
I'm sure it couldn't get worse.

### Batching
Most QUIC libraries will automatically fill a UDP packet with as much data as it can.
This is dope, but as we established, you're a dingus and can't have nice things.

Maybe you're high on the thrill of sending unlimited packets and now need to figure out why so many of them are getting dropped now.
What if we sent 100 byte packets along with extra some parity bits to fix this pesky "random" packet loss.
Somebody call Nobel, I've got a dynamite idea.






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
They asked if they could do all of the above so they would have proper QUIC datagrams.
Then they could implement their own acknowledgements and retransmissions.

So I asked them... why not use QUIC streams?
They already provide reliability, ordering, and can be cancelled.
What more could you want?

### What More Could We Want?
Unfortunately, QUIC is pretty poor for real-time latency.
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
Okay it's not the same as the game dev solution; it's actually better because of **congestion control**.
And once again, you do ~need~ want congestion control.

Otherwise, retransmitting data can quickly balloon out of control.
Congestion can cause bufferbloat, which is when routers queue packets for an unknown amount of time (potentially for seconds).
Surprise!
It turns out that a router doesn't have to drop a packet when overloaded, but instead it can queue it in RAM.

Let's say you retransmit every 30ms and everything works great on your PC.
A user from Brazil or India downloads your application and it initially works great too.
But eventually their ISP gets overwhelmed and congestion causes the RTT to (temporarily) increase to 500ms.
...well now you're transmitting 15x the data and further aggravating any congestion.
It's a vicious loop and you've basically built your own DDoS agent.

But QUIC can avoid this issue because retransmissions are gated by congestion control.
Even when a packet is considered lost, or my hypothetical `stream.retransmit()` is called, a QUIC library won't immediately retransmit.
Instead, retransmissions are queued up until the congestion controller deems it appropriate.
Note that a late acknowledgement or stream reset will cancel a queued retransmission (unless your QUIC library sucks).

Why?
If the network is fully saturated, you need to send fewer packets to drain any network queues, not more.
Even ignoring bufferbloat, networks are finite resources and blind retransmissions are the easiest way to join the UDP Wall of Shame.
In this instance,.the QUIC greybeards will stop you from doing bad thing.
The children yearn for the mines, but the adults yearn for child protection laws.

Under extreme congestion, or when temporarily offline, the backlog of queued data will keep growing and growing.
Once the size of queued delta updates grows larger than the size of a new snapshot, cut your losses and start over.
Reset the stream with deltas to prevent new transmissions and create a new stream with the snapshot.
Repeat as needed; it's that easy!

I know this horse has already been beaten, battered, and deep fried, but this is yet another benefit of congestion control.
Packets are queued locally so they can be cancelled instantaneously.
Otherwise they would be queued on some intermediate router (ex. for 500ms).

## Application Limited 

## Hack the Library
https://github.com/quinn-rs/quinn/blob/6bfd24861e65649a7b00a9a8345273fe1d853a90/quinn-proto/src/frame.rs#L211
