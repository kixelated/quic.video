import { Connection, Publish, Support } from "@kixelated/hang";
import { adjectives, animals, uniqueNamesGenerator } from "unique-names-generator";

import { Show, createEffect, onCleanup } from "solid-js";

export default function () {
	const name = uniqueNamesGenerator({ dictionaries: [adjectives, animals], separator: "-" });
	const url = new URL(
		`${import.meta.env.PUBLIC_RELAY_SCHEME}://${import.meta.env.PUBLIC_RELAY_HOST}/anon/${name}.hang`,
	);

	const preview = (
		<video style={{ "max-width": "100%", height: "100%", margin: "0 auto", "border-radius": "1rem" }} autoplay muted />
	) as HTMLVideoElement;

	const connection = new Connection({ url });

	const broadcast = new Publish.Broadcast(connection, {
		enabled: true,
		video: true,
		audio: {
			// Request the browser to do some noise suppression for microphone input.
			noiseSuppression: true,
			echoCancellation: true,
		},
	});

	createEffect(() => {
		const media = broadcast.video.media.get();
		if (!media || !preview) return;

		preview.srcObject = new MediaStream([media]);
		onCleanup(() => {
			preview.srcObject = null;
		});
	});

	onCleanup(() => {
		connection.close();
		broadcast.close();
	});

	return (
		<div>
			{/* biome-ignore lint/a11y/useValidAriaRole: false-positive */}
			<Support.Modal role="publish" show="partial" />

			<Publish.Controls broadcast={broadcast} />

			<h3>Watch URL:</h3>
			<a href={`/watch/${name}`} rel="noreferrer" target="_blank" class="ml-2">
				{name}
			</a>

			<h3>Preview:</h3>
			<Show when={broadcast.device.get()} fallback={<span class="italic">No device selected</span>}>
				{preview}
			</Show>
		</div>
	);
}
