import { Publish, PublishControls } from "@kixelated/hang/publish";
import { uniqueNamesGenerator, adjectives, animals } from "unique-names-generator";

import { onCleanup, Show } from "solid-js";
import { Support } from "@kixelated/hang";

export default function (props: { room: string }) {
	const url = new URL(`${import.meta.env.PUBLIC_RELAY_SCHEME}://${import.meta.env.PUBLIC_RELAY_HOST}`);

	const randomName = uniqueNamesGenerator({ dictionaries: [adjectives, animals], separator: "-" });

	const video = (
		<video style={{ "max-width": "100%", height: "100%", margin: "0 auto", "border-radius": "1rem" }} autoplay muted />
	);

	const publish = new Publish({
		connection: {
			url,
		},
		broadcast: {
			room: props.room,
			name: randomName,
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
		<div class="flex flex-col gap-8">
			{/* biome-ignore lint/a11y/useValidAriaRole: false-positive */}
			<Support role="publish" show="partial" />

			<div>
				<span class="font-bold decoration-2 decoration-green-500 underline underline-offset-4">Broadcast Name:</span>
				<a href={`/watch/${props.room}/${randomName}`} rel="noreferrer" target="_blank" class="ml-2 no-underline">
					{randomName}
				</a>
			</div>

			<PublishControls lib={publish} />

			<span class="font-bold decoration-2 decoration-green-500 underline underline-offset-4">Preview:</span>
			<Show when={publish.broadcast.device.get()} fallback={<span class="italic">No device selected</span>}>
				{video}
			</Show>
		</div>
	);
}
