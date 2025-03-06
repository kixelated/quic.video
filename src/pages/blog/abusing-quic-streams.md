# Abusing QUIC Streams
This is the second part of our QUIC hackathon.
Read [Abusing QUIC Datagrams](/blog/abusing-quic-datagrams) if byte streams confuse you.

Look, I may be one of the biggest QUIC fanboys on the planet, but I've got to admit that QUIC streams are pretty poor for real-time latency.
They're designed for not designed for bulk delivery, not small payloads that need to arrive ASAP like voice calls.
It's the reason why the dinguses reach for datagrams.

But don't take my wrinkle brain statements as fact.
Let's dive deeper and FIX IT.

## Detecting Loss
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

See, there's no requirement that a STREAM frame is retransmitted verbatim.
If STREAM 10-20 is lost, we could retransmit it as STREAM 10-15, STREAM 17-20, and STREAM 15-17 if we wanted to.
This is actually super useful because we can cram a UDP packet full of miscallenous STREAM frames without worrying about overrunning the MTU.

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
There's nothing actually stopping us flooding the network with duplicate copies.
We could just send it again, and again, and again, and again, and again every 50ms.
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
