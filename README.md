# Media over QUIC

Media over QUIC (MoQ) is a live media delivery protocol utilizing QUIC streams.
See the [Warp draft](https://datatracker.ietf.org/doc/draft-lcurley-warp/).

This repository is the source code for [quic.video](https://quic.video).
It uses [moq-js](https://github.com/kixelated/moq-js) for the web components and [moq-rs](https://github.com/kixelated/moq-rs) for the server components.

## Setup

Install dependencies using `npm`:

```bash
npm install
```

Install [mkcert](https://github.com/FiloSottile/mkcert) to generate a self-signed certificate.
This is merely for convinence to avoid TLS errors when using parcel.

```bash
npm run cert
```

## Development

Host a simple demo on `https://localhost:4444`.

```bash
npm run serve
```

By default, the site will use a [moq-rs](https://github.com/kixelated/moq-rs) relay running on `https://localhost:4443`.

### Linking

If you want to test changes to [@kixelated/moq](https://github.com/kixelated/moq-js), use `npm link` set up a global symlink.

```bash
npm link @kixelated/moq
```

Unfortunately, [parcel doesn't monitor symlinks for changes](https://github.com/parcel-bundler/parcel/issues/4332).
You'll need to restart the parcel server each time until I can figure out a work-around.

## License

Licensed under either:

-   Apache License, Version 2.0, ([LICENSE-APACHE](LICENSE-APACHE) or http://www.apache.org/licenses/LICENSE-2.0)
-   MIT license ([LICENSE-MIT](LICENSE-MIT) or http://opensource.org/licenses/MIT)
