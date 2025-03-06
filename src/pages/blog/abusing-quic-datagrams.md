# Abusing QUIC Datagrams
This is the first part of our QUIC hackathon.
Read [Abusing QUIC Streams](/blog/abusing-quic-streams) if you like ordered data like a normal human being.

We're going to hack QUIC.
"Hack" like a ROM-hack, not "hack" like a prison sentence.
Unless Nintendo is involved.

We're not trying to be malicious, but rather unlock new functionality while remaining compliant with the specification.
We can do this easily because unlike TCP, QUIC is implemented in *userspace*.
That means we can take a QUIC library, tweak a few lines of code, and unlock new functionality that the greybeards *attempted* to keep from us.
We then ship our modified library as part of our application and nobody will suspect a thing.

But before we continue, a disclaimer:

## Dingus Territory
QUIC was designed with developers like *you* in mind.
Yes *you*, wearing your favorite "I 💕 node_modules" T-shirt about to rewrite your website again using the Next-est framework released literally seconds ago.

*You are a dingus*.

The greybeards that designed QUIC, the QUIC libraries, and the related web APIs do not respect you.
They think that given a shotgun, the first thing you're going to do is blow your own foot off.
And they're right of course.

That's why there is no UDP socket Web API.
WebRTC data channels claim to have "unreliable" messages but don't even get me started.
Heck, there's not even a native TCP API; WebSockets are a close approximation but force a HTTP handshake and additional framing for *reasons*.

QUIC doesn't change that mentality.
Short of wasting a zero-day exploit, we have to use the browser's built-in QUIC library via the WebTransport API.
Browser vendors like Google don't want *you*, the `node_modules` enjoyer, doing any of the stuff mentioned in this article on *their* web clients.
But that's not going to stop us from modifying the server or the clients we control (ex. native app).

However, in doing so, you must constantly evaluate if you are the *dingus* in the exchange.
QUIC famously does not let you disable encryption because otherwise *some dingus* would disable it because they think it make computer go slow (it doesn't) and oh no now North Korea has some more bitcoins.
So many people believe that encryption is slow, but once you actually benchmark AES-GCM, it turns out that so many people are *the dingus*.

Yes, there are legitimate use-cases where a full TLS handshake is not worth it.
But when the safe API is the best API 99% of the time, then it becomes the only API.
This article is the equivalent of using the `unsafe` keyword in Rust.
You can do these things and you'll super feel smart, but are you smart?

So heed my warnings.
Friends don't let friends design UDP protocols.
(And we're friends?)
You should start simple and use the intended QUIC API before reaching for that shotgun.


## Proper QUIC Datagrams
I've been quite critical in the past about QUIC datagrams.
Bold statements like "they are bait",  "never use datagrams", and "try using QUIC streams first ffs".
But some developers don't want to know the truth and just want their beloved UDP datagrams.

The problem is that QUIC datagrams are *not* UDP datagrams.
That would be something closer to DTLS.
Unlike UDP datagrams, QUIC datagrams:
1. Are congestion controlled.
2. Trigger acknowledgements.
3. Do not expose these acknowledgements.
4. May be batched.

We're going to try to fix some of these short-comings in the standard by modifying a standard QUIC library.
Be warned though, you're entering dingus territory.

### Congestion Control
The truth is that there's nothing stopping a QUIC library from sending an unlimited number of QUIC datagrams.
There's only a few pixels in the standard that say you SHOULD NOT do this.

"Congestion Control" is what a library SHOULD do.
There's many congestion control algorithms out there, and put simply they are little more than an educated guess on if the network can handle more traffic.
The simplest form of congestion control is to send less data when packet loss is high and send more data when packet loss is low.

But this is an artifical limit that is begging to be broken.
It's often a hiderance as many networks could sustain a higher throughput without this pesky congestion control.
All we need to do is comment out one check and bam, we can send QUIC datagrams at an unlimited rate.

But please do not do this unless you know what you are doing... or are convinced that you know what you are doing.

[ percentile meme ]

You *need* some form of congestion control if you're sending data over the internet.
Otherwise you'll suffer from congestion, bufferbloat, high loss, and other symptoms.
These are not symptoms of the latest disease kept under wraps by the Trump administration, but rather a reality of the internet being a shared resource.
Routers will queue and eventually drop excess packets, wrecking any algorithm that treats the internet like an unlimited pipe.

But it's no fun starting a blog with back to back lectures.
We're here to abuse QUIC damnit, not the readers.

But I did not say that you should use the *default* congestion control.
The QUIC RFC is based on the dated TCP New Reno algorithm which performs poorly when latency is important or bufferbloat rampant.
That's because QUIC is designed with pluggable congestion control in mind.
Most libraries expose an interface so you choose the congestion controller or make your own.
You can't do this with TCP as it's buried inside the kernel, so +1 points to QUIC.

And note that custom congestion control is not specific to QUIC datagrams.
You can use a custom congestion controller for QUIC streams too!

So use a battle tested algorithm like BBR instead of the default.
Or make your own by piping each ACK to ChatGPT and let the funding roll in.
Or be extra boring and write a master's thesis about curve fitting or something
Or completely disable congestion control altogether, you do you.

### Acknowledgements
QUIC will reply with an acknowledgement packet are receiving each datagram.
This might sound absolutely bonkers if you're used to UDP.
These are **not** used for retransmissions, so what are they for?

...they're only for congestion control.
But what if we just disabled QUIC's congestion control?
Now we're going to get bombarded with useless acknowledgements!

The good news is that QUIC acknowledgements are batched, potentially appended to your data packets, and are quite efficient.
It's only a few extra bytes/packets so it's not the end of the world.
But I can already feel your angst; your uncontrollable urge to optimize this *wasted bandwidth*.

The most cleverest of dinguses amongst us (amogus?) might try to leverage these ACKs.
What if we used these otherwise "useless" ACKs to tell our application if a packet was received?
That way we won't have to implement our own ACK/NACK mechanism for reliability.
Somebody call Nobel, that's a dynamite idea.

You can absolutely hack a QUIC library to expose which datagrams were acknowledged by the remote.
More information is always better, right?
Why don't QUIC libraries provide this?

...unfortunately there's an edge case discovered by yours truely.
The QUIC may acknowledge a datagram but it gets dropped before being delivered it to the application.
This will happen if a QUIC library processes a packet, sends an ACK, but the application (ex. Javascript web page) is too slow and we run out of memory to queue it.
**Note:** QUIC streams don't suffer from this issue because they use flow control.

This might not be a deal breaker depending on your application.
However, it's a quite unfortunate footgun if you're expecting QUIC ACKs to be the definitive signal that your application has received a packet.
If you want that reliability... then you should implement your own ACK/NACK protocol on top of QUIC datagrams.
This is gross because one datagram will trigger a QUIC ACK, your custom ACK, and a QUIC ACK for your custom ACK.
I bet the angst is overwhelming now.

So let's get rid of these useless ACKs instead.
If you control the receiver, you can tweak the `max_ack_delay` parameter.
This is a parameter exchanged during the handshake that indicates how long the implementation can wait before sending an acknowledgement.
Crank it up to 1000ms (the default is 25ms) and the number of acknowledgement packets should slow to a trickle.

Be warned that this will impact all QUIC frames, *especially* STREAM retransmissions.
It may also throw a wrench into the congestion controller too as they expect timely feedback..
So only consider this route if you've gone *full dingus* and completely disabled congestion control and streams.
The chaos you've sown will be legendary.

### Batching
Most QUIC libraries will automatically fill a UDP packet with as much data as it can.
This is dope, but as we established, you can't settle for nice things.
We're here to strip a transport protocol to its core.

But why would you do this?
Let's you're high on the thrill of sending unlimited packets after disabling congestion control.
However, sometimes a bunch of packets get lost and you need to figure out why.
Surely it can't be the consequences of your actions?

"No!
It's the network's fault!
I'm going to shotgun additional copies to ensure at least one arrives..."

I cringed a bit writing that (while you cringed reading this blog).
See, I've sat through too presentations by staff (video) engineers claiming the same thing.
FEC is the solution to a problem that they don't understand.
It turns out there's no secret cheat code to the internet: sending more packets will cause proportially *more* packet loss as devices get fully saturated.

But we're going to save that for the finale rant and instead focus on **atomicity**.
Packet loss instinctively feels like an independent event: a coin toss on a router somewhere.
Sending the same packet back-to-back means you get to toss the coin again, right?

Not really, because a "packet" is a high level abstraction.
Even the humble UDP packet will get coalesced at a lower level with it's own recovery scheme.
For example, 7 UDP packets (1.2KB MTU*) can fit snug into a jumbo Ethernet frame.
If your protocol depends on "independent" packets, then you may be distraught to learn that they are actually somewhat fate-bound and may be dropped in batches.

QUIC takes this a step further and batches everything, including datagrams.
You may send ten, 100 byte datagrams that appear disjoint in your application but may secretly get combined into one UDP datagram under the covers.
You're at the mercy of the QUIC library, which is at the mercy of the lower level transport.

Fortunately, QUIC cannot split a datagram across multiple UDP packets.
If your datagrams are large enough (>600 bytes*) then you can sleep easy knowing they won't get combined with other datagrams.
But just like everything else thus far, we can disable this behavior entirely.
Tweak a few lines of code and boop, you're sending a proper UDP packet for each QUIC datagram.

I'm not sure why you would, because it can only worsen performance, but I'm here (to pretend) not to judge.
Your brain used to be smooth but now it's wrinkly af 🧠🔥.

## Real-time Streams
Look, I may be one of the biggest QUIC fanboys on the planet, but I've got to admit that QUIC streams are pretty poor for real-time latency.
They're designed for not designed for bulk delivery, not small payloads that need to arrive ASAP like voice calls.
It's the reason why the dinguses reach for datagrams.

But don't take my wrinkle brain statements as fact.
Let's dive deeper and FIX IT.

### Detecting Loss
```
|  |i
|| |_
```

*How does a QUIC library know when a packet is lost?*

It doesn't.
There's no explicit signal from routers (yet?) when a packet is lost.
A QUIC library has to instead use FACTS and LOGIC to make an educated guess.
The RFC outlines a *recommended* algorithm that I'll attempt to simplify:

- The sender increments a sequence number for each packet.
- Upon receiving a packet, the receiver will start a timer to ACK that sequence number, batching with any others that arrive within `max_ack_delay`.
- If the sender does not receive an ACK after waiting multiple RTTs, it will send another packet (like a PING) to poke the receiver and hopefully start the ACK timer.
- After finally receiving an ACK, the sender *may* decide that a packet was lost if:
  - 3 newer sequences were ACKed.
  - or a multiple of the RTT has elapsed.
- As the congestion controller allows, retransmit any lost packets and repeat.

Skipped that boring, "simplified" wall of text?
I don't blame you.
You're just here for the funny blog and *maaaaybe* learn something along the way.

I'll help.
If a packet is lost, it takes anywhere from 1-3 RTTs to detect the loss and retransmit.
It's particularly bad for the last few packets in a burst because if they're lost, nothing starts the acknowledgement timer and the sender will have to poke.
"You still alive over there?".
The tail of our stream will take longer (on average) to arrive unless there's other data in flight to perform this poking.

And just in case I lost you in the acronym soup, RTT is just another way of saying "your ping".
So if you're playing Counter Strike cross-continent with a ping of 150ms, you're already at a disadvantage.
Throw QUIC into the mix and some packets will take 300ms to 450ms of conservative retransmissions.
*cyka bylat*


### Head-of-line Blocking
We're not done yet.
QUIC streams are also poor for real-time because they introduce head-of-line blocking.

Let's suppose we want to stream real-time chat over QUIC.
But we're super latency sensitive, like it's a bad rash, and need the latest sentence as soon as possible.
We can't settle for random words; we need the full thing in order baby.
The itch is absolutely unbearable and we're okay being a little bit wasteful.

If the broadcaster types "hello" followed shortly by "world", we have a few options.
Pop quiz, which approach is subjectively the best:

Option A: Create a stream, write the word "hello", then later write "world".
Option B: Create a stream and write "0hello". Later, create another stream and write "5world". The number at the start is the offset.
Option C: Create a stream and write "hello". Later, create another stream and write "helloworld".
Option D: Abuse QUIC (no spoilers)

If you answered D then you're correct.
Let's use a red pen and explain why the other students are failing the exam.
No cushy software engineering gig for you.

#### Option A
*Create a stream, write the word "hello", then later write "world".*

This is classic head-of-line blocking. If the packet containing "hello" gets lost over the network, then we can't actually use the "world" message if it arrives first.
But that's okay in this scenario because of my arbitrary rules

The real problem is that when the "hello" packet is lost, it won't arrive for *at least* an RTT after "world" because of the affirmationed retransmission logic.
That's no good.

#### Option B
*Create a stream and write "0hello". Later, create another stream and write "5world". The number at the start is the offset.*

I didn't explain how multiple streams work because a bad teacher blames their students.
And I wanted to blame you.


QUIC will retransmit any unacknowledged fragments of a stream.
But like I said above, only when a packet is considered lost.
But with the power of h4cks, we could have the QUIC library *assume* the rest of the stream is lost and needs to be retransmitted.
For you library maintainers out there, consider adding this as a `stream.retransmit()` method and feel free to forge my username into the git commit.

### BBR

## Improper QUIC Streams
Okay so we've hacked QUIC datagrams to pieces, but why?

I was actually inspired to write this blog post because someone joined my (dope) Discord server.
They asked if they could do all of the above so they would have proper QUIC datagrams.

The use-game is vidya games.
The most common approach for video games is to process game state at a constant "tick" rate.
VALORANT, for example, uses a tick rate of [128 Hz](https://playvalorant.com/en-us/news/dev/how-we-got-to-the-best-performing-valorant-servers-since-launch/) meaning each update covers a 7.8ms period.
It's really not too difficult from frame rate (my vidya background) but latency is more crucial otherwise nerds get mad.

So the idea is to transmit each game tick as a QUIC datagram.
However, that would involve transmitting a lot of redundant information, as two game ticks may be very similar to each other.
So the idea is to implement custom acknowledgements and (re)transmit only the unacknowledged deltas.

If you've had the pleasure of implementing QUIC before, this might sound very similar to how QUIC streams work internally.
In fact, this line of thinking is what lead me to ditch RTP over QUIC (datagrams) and embrace Media over QUIC (streams).
So why disassemble QUIC only to reassemble parts of it?
If we used QUIC streams instead, what more could you want?

### What More Could We Want?
Look, I may be one of the biggest QUIC fanboys, but I've got to admit that QUIC is pretty poor for real-time latency.
It's not designed for small payloads that need to arrive ASAP, like voice calls.

But don't take my wrinkle brain statements as fact.
Let's dive deeper.

*How does a QUIC library know when a packet is lost?*

It doesn't.
There's no explicit signal from routers (yet?) when a packet is lost.
A QUIC library has to instead use FACTS and LOGIC to make an educated guess.
The RFC outlines a *recommended* algorithm that I'll attempt to simplify:

- The sender increments a sequence number for each packet.
- Upon receiving a packet, the receiver will start a timer to ACK that sequence number, batching with any others that arrive within `max_ack_delay`.
- If the sender does not receive an ACK after waiting multiple RTTs, it will send another packet (like a PING) to poke the receiver and hopefully start the ACK timer.
- After finally receiving an ACK, the sender *may* decide that a packet was lost if:
  - 3 newer sequences were ACKed.
  - or a multiple of the RTT has elapsed.
- As the congestion controller allows, retransmit any lost packets and repeat.

Skipped that boring wall of text?
I don't blame you.
You're just here for the funny blog and *maaaaybe* learn something along the way.

I'll help.
If a packet is lost, it takes anywhere from 1-3 RTTs to detect the loss and retransmit.
It's particularly bad for the last few packets in a burst because if they're lost, nothing starts the acknowledgement timer and the sender will have to poke.
"You still alive over there?"

And just in case I lost you in the acronym soup, RTT is just another way of saying "your ping".
So if you're playing Counter Strike cross-continent with a ping of 150ms, you're already at a disadvantage.
Throw QUIC into the mix and some packets will take 300ms to 450ms of conservative retransmissions.
*cyka bylat*

### We Can Do Better?
So how can we make QUIC better support real-time applications that can't wait multiple round trips?
Should we give up and admit that networking peaked with UDP?

Of course not what a dumb rhetorical question.

We can use QUIC streams!
A QUIC stream is nothing more than a byte slice.
The stream is arbitrarily split into STREAM frames that consists of an offset and a payload.
The QUIC reviever reassembles these frames in order before flushing to the application.
Some QUIC libraries even allow the application to read stream chunks out of order.

How do we use QUIC streams for vidya games?
Let's suppose we start with a base game state of 1000 bytes and each tick there's an update of 100 bytes.
We make a new stream, serialize the base game state, and constantly append each update.
QUIC will ensure that the update and deltas arrive in the intended order so it's super easy to parse.

But not so fast, there's a **huge** issue.
We just implemented head-of-line blocking and our protocol is suddenly no better than TCP!
I was promised that QUIC was supposed to fix this...



We can abuse the fact that a QUIC receiver must be prepared to accept duplicate or redundant STREAM frames.
This can happen naturally if a packet is lost or arrives out of order.
You might see where this is going: nothing can stop us from sending a boatload of packets.




Our QUIC library does not need to wait for a (negative) acknowledgement before retransmitting a stream chunk.
We could just send it again, and again, and again every 50ms.
If it's a duplicate, then QUIC will silently ignore it.

## A Problem

But there's a pretty major issue with this approach:
**BUFFERBLOAT**.
Surprise!
It turns out that some routers may queue packets for an undisclosed amount of time when overloaded.

Let's say you retransmit every 50ms and everything works great on your PC.
A user from Brazil or India downloads your application and it initially works great too.
But eventually their ISP gets overwhelmed and congestion causes the RTT to (temporarily) increase to 500ms.
...well now you're transmitting 10x the data, potentially aggravating any congestion and preventing recovery.
It's a vicious loop and you've basically built your own DDoS agent.

For the distributed engineers amogus, this is the networking equivalent of an F5 refresh storm.


Either way, sending redundant copies of data is nothing new.
Let's go a step further and embrace QUIC streams.

### How I Learned to Embrace the Stream


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

## Hack the Library
https://github.com/quinn-rs/quinn/blob/6bfd24861e65649a7b00a9a8345273fe1d853a90/quinn-proto/src/frame.rs#L211
