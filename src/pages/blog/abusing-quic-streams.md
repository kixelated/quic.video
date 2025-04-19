# Abusing QUIC Streams
This is the second part of our QUIC hackathon.
Read [Abusing QUIC Datagrams](/blog/abusing-quic-datagrams) if byte streams confuse you.

Look, I may be one of the biggest QUIC fanboys on the planet.
I'm ashamed to admit that QUIC streams are meh for real-time latency.

I know, I know, I just spent the last blog post chastising you, the `I <3 node_modules` developer, for daring to dream.
For daring to vibe code.


## QUIC 101
It's by design: QUIC streams trickle.





Thi
ou could reach for datagrams like a dingus 

QUIC streams are designed to trickle, relying on retransmissions to *eventually* patch any holes caused by packet loss.
The key 

QUIC datagrams are the intended alternative, but as I outlined in my last blog post, they're bait for dinguses.

But what if I told you that we can abuse QUIC streams to better achieve real-time latency?


But don't take my wrinkle brain statements as fact.
Let's dive deeper and FIX IT.

## Detecting Loss
```
|  |i
|| |_
```

QUIC streams are continuous byte streams that rely on retransmissions to *eventually* patch any holes caused by packet loss.
The key word being *eventually*, as QUIC won't waste bandwidth on retransmissions unless theyre needed.

**Pop quiz:**
*How does a QUIC library know when a packet is lost and needs to be retransmitted?*

**Answer**:
Trick question, it doesn't.

A pop quiz this early into a blog post?
AND a trick question?
That's not fair.

There's no explicit signal from routers when a packet is lost.
L4S might change that on some networks but I wouldn't get your hopes up.
Instead, a QUIC library has to instead use FACTS and LOGIC to make an educated guess.
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


## Head-of-line Blocking
We're not done with packet loss yet, but let's put an `!Unpin` in it.

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

### Option A
*Create a stream, write the word "hello", then later write "world".*

This is classic head-of-line blocking. If the packet containing "hello" gets lost over the network, then we can't actually use the "world" message if it arrives first.
But that's okay in this scenario because of my arbitrary rules

The real problem is that when the "hello" packet is lost, it won't arrive for *at least* an RTT after "world" because of the affirmationed retransmission logic.
That's no good.

### Option B
*Create a stream and write "0hello". Later, create another stream and write "5world". The number at the start is the offset.*

I didn't explain how multiple streams work because a bad teacher blames their students.
And I wanted to blame you.

QUIC streams share a connection but are otherwise independent.
You can create as many streams *as the remote peer allows* with no\* overhead.
In fact, if you were considering retransmitting QUIC datagrams, you could totally use a QUIC stream per datagram instead.

In this example, both "hello" and "world" will be (re)transmitted independently over separate streams and it's up to the receiver to reassemble them.
That's why we had to include the offset, otherwise the receiver would have no idea that "world" comes after "hello" (duh).
At some point we would also need to include a "sentence ID" if we wanted to support multiple sentences.
The receiver receives "helloworld" and voila, our itch is scratched.

But this approach sucks.
Major suckage.

But don't feel bad if this seemed like a good idea.
You literally just reimplemented QUIC streams and this is identical to **Option A**.
We did all of this extra work for nothing.

Despite the fact that they're using separate streams, "hello" still won't be retransmitted until after "world" is acknowledged.
The fundamental problem is that QUIC retransmissions occur at the *packet level*.
We need to dive deeper, not just create an independent stream.

### Option C
*Create a stream and write "hello". Later, create another stream and write "helloworld".*

Now we're getting somewhere.
We're finally wasting bytes.

This approach is better than Option A/B (for real-time latency) because we removed a dependency.
If "hello" is lost, well it doesn't matter because "helloworld" contains a redundant copy.

But this approach is still not ideal.
What if "hello" is acknowledged *before* we write "world"?
We don't want to waste bytes unncessarily and shouldn't retransmit "hello".
Most QUIC libraries don't expose these details to the application.
And even if they did, we would have to implement **Option B** and send "5world".
And what if there's a gap, like "world" is acknowledged but not "hello" or a trailing "!"?

We're delving back into *reimplementing QUIC streams* territory.
The wheel has been invented already.
If only there was a way to hack a QUIC library to do what we want...

### Option D
*Abuse QUIC (no spoilers)*

A QUIC stream is broken into STREAM frames that consist of an offset and payload.
The QUIC sender keeps track of which STREAM frames were stuffed into which UDP packets so it knows what to retransmit if a packet is lost.
The QUIC receiver reassembles these STREAM frames based on the offset then flushes it to the application.

The magic trick depends on an important fact:
A QUIC receiver must be prepared to accept duplicate, overlapping, or otherwise redundant STREAM frames.

See, there's no requirement that the *same* STREAM frame is retransmitted.
If STREAM 10-20 is lost, we could retransmit it as STREAM 10-15, STREAM 17-20, and STREAM 15-17 if we wanted to.
This is on purpose and super useful because we can cram a UDP packet full of miscallenous STREAM frames without worrying about overrunning the MTU.

Grab your favorite sleeveless shirt because we are *abusive*.

We're going to use a single stream like **Option A**.
Normally, "hello" is sent as STREAM 0-5 and "world" is sent as STREAM 5-10.
However, we can modify our QUIC library to actually transmit STREAM 0-10 instead, effectively sending "helloworld" in one packet.
More generally, we can retransmit any unacknowledged fragments of a stream.

The easiest way to implement this is to have the QUIC library *assume* the in-flight fragments of a stream are lost and need to be retransmitted.
This won't impact congestion control because we don't consider the packets as lost... just some of their contents.
For you library maintainers out there, consider adding this as a `stream.retransmit()` method and feel free to forge my username into the git commit.

## Revisiting Retransmissions
Remember the part where I said:

> We're not done with packet loss yet, but let's put an `!Unpin` in it.

We're back baby.
That's because as covered in the previous section, it's totally legal to retransmit a stream chunk without waiting for an acknowledgement.
The specification says don't do it, but there's nothing *actually* stopping us flooding the network with duplicate copies.
If QUIC receives a duplicate stream chunk, it will silently ignore it.

So rather than wait 450ms for a (worst-case) acknowledgement, what if we just... don't?
We could just transmit the same stream chunk again, and again, and again, and again, and again every 50ms.

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
Blind retransmissions are the easiest way to join the UDP Wall of Shame.


### Congestion Control to the Rescue
Actually I just lied.

This infinite loop of pain, suffering, and bloat is what would happen if you retransmitted using UDP datagrams.
But not with QUIC streams (and datagrams).

Retransmissions are gated by congestion conntrol.
Even when a packet is considered lost, or my hypothetical `stream.retransmit()` is called, a QUIC library won't immediately retransmit.
Instead, stream retransmissions are queued up until the congestion controller allows more packets to be sent.

The QUIC greybeards will stop you from doing bad thing.
The children yearn for the mines, but the adults yearn for child protection laws.

But now we have a new problem.
Our precious data is getting queued locally and latency starts to climb.
If we do nothing, then nothing gets dropped and oh no, we just reimplemented TCP.

At some point we have to take the L and wipe the buffer clean.
QUIC lets you do this by resetting a stream, notifying the receiver and cancelling any queued (re)transmissions.
We can then make a new stream (for free*) and start over with a new base.
For those more media inclined, this would mean resetting the current GoP and encoding a new I-frame on a new stream.

To recap:
- Using UDP directly: our data gets queued and arbitrarily dropped by some router in the void.
- Using QUIC datagrams, our data get dropped locally (congestion control) and arbitrarily dropped by the void, although less often.
- Using QUIC streams, our data gets queued locally (congestion control) and explicitly dropped when we choose.

I can't believe there aren't more QUIC stream fanboys.
It's a great abstraction because *you do not understand networking* nor should your application care how stuff gets split into IP packets.
Your application should deal with queues that get drained at an unpredictable rate.
