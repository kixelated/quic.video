import { adjectives, animals, uniqueNamesGenerator } from "unique-names-generator";

import "@kixelated/hang/support/element";
import "@kixelated/hang/publish/element";

export default function () {
	const name = uniqueNamesGenerator({ dictionaries: [adjectives, animals], separator: "-" });
	const url = new URL(import.meta.env.PUBLIC_CLOUDFLARE_URL);

	return (
		<div>
			<hang-support prop:mode="publish" prop:show="partial" />

			<div class="mb-8">
				<h3 class="inline">Broadcast:</h3>{" "}
				<a href={`/watch?name=${name}`} rel="noreferrer" target="_blank" class="ml-2 text-2xl">
					{name}
				</a>
			</div>

			<hang-publish
				prop:url={url}
				prop:name={name}
				prop:controls={true}
				prop:video={true}
				prop:audio={true}
				prop:captions={true}
			>
				<video
					style={{ "max-width": "100%", height: "100%", margin: "0 auto", "border-radius": "1rem" }}
					autoplay
					muted
				/>
			</hang-publish>

			<h3>Features:</h3>
			<ul>
				<li>
					🔓 <strong>Open Source</strong>: <a href="/source">Typescript and Rust libraries</a>; this demo is{" "}
					<a href="https://github.com/kixelated/moq/blob/main/js/hang-demo/src/publish.html">here</a>.
				</li>
				<li>
					🌐 <strong>100% Web</strong>: WebTransport, WebCodecs, WebAudio, WebWorkers, WebEtc.
				</li>
				<li>
					🎬 <strong>Modern Codecs</strong>: Supports AV1, H.265, H.264, VP9, Opus, AAC, etc.
				</li>
				<li>
					💬 <strong>Automatic Captions</strong>: Generated{" "}
					<a href="https://huggingface.co/docs/transformers.js/en/index">in-browser</a> using WebGPU and{" "}
					<a href="https://github.com/openai/whisper">Whisper</a>.
				</li>
				<li>
					⚡ <strong>Real-time Latency</strong>: Minimal buffer, old media is skipped during congestion.
				</li>
				<li>
					🚀 <strong>Massive Scale</strong>: Everything is deduplicated and distributed across a global CDN.
				</li>
				<li>
					💪 <strong>Efficient</strong>: No bandwidth is used until a viewer needs it.
				</li>
				<li>
					🔧 <strong>Compatible</strong>: TCP fallback via{" "}
					<a href="https://github.com/kixelated/web-transport/tree/main/web-transport-ws">WebSocket</a>, Safari fallback
					via <a href="https://github.com/Yahweasel/libav.js/">libav.js.</a>
				</li>
			</ul>

			<h3>Hosted on:</h3>
			<a href="/blog/first-cdn" rel="noreferrer" target="_blank">
				<img src="/blog/first-cdn/cloudflare.png" alt="Cloudflare" class="w-64" />
			</a>
		</div>
	);
}
