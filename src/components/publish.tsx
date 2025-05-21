import { Support, Publish, PublishControls } from "@kixelated/hang";
import { uniqueNamesGenerator, adjectives, animals } from "unique-names-generator";

import { onCleanup, Show } from "solid-js";

export default function () {
	const name = uniqueNamesGenerator({ dictionaries: [adjectives, animals], separator: "-" });
	const url = new URL(
		`${import.meta.env.PUBLIC_RELAY_SCHEME}://${import.meta.env.PUBLIC_RELAY_HOST}/demo/${name}.hang`,
	);

	const video = (
		<video style={{ "max-width": "100%", height: "100%", margin: "0 auto", "border-radius": "1rem" }} autoplay muted />
	);

	const publish = new Publish({
		connection: {
			url,
		},
		broadcast: {
			video: true,
			audio: {
				// Request the browser to do some noise suppression for microphone input.
				noiseSuppression: true,
				echoCancellation: true,
			},
		},
		preview: video as HTMLVideoElement,
	});

	onCleanup(() => {
		publish.close();
	});

	return (
		<div>
			{/* biome-ignore lint/a11y/useValidAriaRole: false-positive */}
			<Support role="publish" show="partial" />

			<PublishControls lib={publish} />

			<h3>Watch URL:</h3>
			<a href={`/watch/${name}`} rel="noreferrer" target="_blank" class="ml-2">
				{name}
			</a>

			<h3>Preview:</h3>
			<Show when={publish.broadcast.device.get()} fallback={<span class="italic">No device selected</span>}>
				{video}
			</Show>
		</div>
	);
}
