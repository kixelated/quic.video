# Media over QUIC

Media over QUIC (MoQ) is a live media delivery protocol utilizing QUIC streams.
See the [Warp draft](https://datatracker.ietf.org/doc/draft-lcurley-warp/).

This repository is the source code for [quic.video](https://quic.video).
It uses [moq-js](https://github.com/kixelated/moq-js) for the web components and [moq-rs](https://github.com/kixelated/moq-rs) for the server components.

## Setup

Install dependencies using `npm`:

```
npm install
```

Install [mkcert](https://github.com/FiloSottile/mkcert) to generate a self-signed certificate.
This is merely for convinence to avoid TLS errors when using parcel.

```
npm run cert
```

## Serve

Host a simple demo on `https://localhost:4444`. Note that you'll have to accept any TLS errors.

```
npm run serve
```

This a requires a [MoQ server](https://github.com/kixelated/moq-rs) running on `https://localhost:4443`.

## License

Licensed under either:

-   Apache License, Version 2.0, ([LICENSE-APACHE](LICENSE-APACHE) or http://www.apache.org/licenses/LICENSE-2.0)
-   MIT license ([LICENSE-MIT](LICENSE-MIT) or http://opensource.org/licenses/MIT)
