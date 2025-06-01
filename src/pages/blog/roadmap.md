# Roadmap
If you want to add or prioritize an item, hit me up on Discord.

If something is prefixed with (HANG) then it might start closed source; I'm not sure.
Everything possible with stock WebRTC *will* be open-source.
But I do want to make an experimental product with niche features that don't make sense to open source immediately.
Maybe when my startup implodes; hit me up if you're interested.

## Phase -1: Already Implemented
This project has been meandering so I don't blame you for being unaware of what has already been completed:

- moq-relay
  - Server that fans-out publishers to subscribers.
  - Supports clustering, fetching content from other relays around the world.
  - Media agnostic. Doesn't care about the content of each track.
- moq-karp
  - Media "container" on top of moq-transfork.
  - Mostly consists of a JSON catalog.
  - CLI to convert and publish fMP4 streams.
- moq-web
  - Web playback and publishing.
  - WebComponents and Typescript API.
  - Core is in Rust (WASM+Worker). 
  - Video only: h264, h265, av1, vp8, vp9.
  

## Phase 0: Foundation 
Before diving headfirst into the product, I want to "finalize" the base so it can be built upon.
But I don't want to revert to arguing semantics at IETF.

- Refocus the base drafts:
  - Rename `moq-transfork` as `moq-lite`. The focus is simplicity and live only.
  - Publish `moq-karp` as `moq-hang`. The focus is live conferencing only.
- Implement `gstreamer` plugins:
  - Implement a `src` for receiving media over the network.
  - Improve the `sink` for sending media over the network (no more fMP4).
- Resurrect `moq-js` for web.
  - It was a fun experiment, but the web isn't designed for Rust.
  - Simpler, more performant, and less complicated web client.
  - Already has (poor) audio support.
  - Rename `kixelated/moq-rs` to `kixelated/moq` with a `native` and `web` folder.

## Phase 1: Core Product 
The basics required to have a voice chat with someone online.

- Improve web audio support:
  - Investigate getting rid of `SharedArrayBuffer`.
  - With the ability to mute/deafen/volume.
- Implement a room UI:
  - Create/join room button.
  - Grid of connected users.
  - Configurable channel display name.
  - Configurable (saved) user display names.
- Implement a simple chat protocol:
  - No history
 
## Phase 2: Branding
Improve the quic.video site so people can actually try this stuff.

- Improve the design so it looks less shit.
- Add a meeting demo.
  - List public rooms.
  - Allow creating a new room.
- Slowly release a cache of hoarded blog posts.
- Start attending IETF meetings again.

## Phase 3: Hang
Create hang.live as a true demo of what MoQ can do.

- (HANG) Replace the grid with a dynamic canvas.
  - No spoilers
- (HANG) Add notifications.
- (HANG) Improve screen sharing.
- (HANG) Mess around with shaders.

## Phase 4: Polish

## Phase N - Future?

- Implement an OBS plugin:
  - Should be easy, but low priority.
- Improve the ffmpeg integration:
  - Investigate not using pipes and an fMP4 intermediate.
  - Add the ability to receive live media.
- Clean up the async internals:
  - Reimplement the core as a synchronous state machine.
  - Support Quiche as a QUIC backend.
