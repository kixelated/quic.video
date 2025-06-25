import { Connection, Support } from "@kixelated/hang";
import { Watch } from "@kixelated/hang";
import { onCleanup } from "solid-js";

export default function (props: { name: string; token?: string }) {
	// The signed token is only needed for the demo/ prefix just to prevent abuse.
	// All other broadcasts go to anon/ which is super easy to spoof.
	const url = new URL(
		`${import.meta.env.PUBLIC_RELAY_SCHEME}://${import.meta.env.PUBLIC_RELAY_HOST}/${props.token ? `${props.token}.jwt` : `${props.name}.hang`}`,
	);
	const canvas = (
		<canvas style={{ "max-width": "100%", height: "auto", margin: "0 auto", "border-radius": "1rem" }} />
	) as HTMLCanvasElement;

	const connection = new Connection({ url });
	const broadcast = new Watch.Broadcast(connection, { path: "", enabled: true });
	const video = new Watch.VideoRenderer(broadcast.video, { canvas });
	const audio = new Watch.AudioEmitter(broadcast.audio, { muted: true });

	let root!: HTMLDivElement;

	onCleanup(() => {
		connection.close();
		broadcast.close();
		video.close();
		audio.close();
	});

	return (
		<div ref={root}>
			{/* biome-ignore lint/a11y/useValidAriaRole: false-positive */}
			<Support.Modal role="watch" show="partial" />

			{canvas}

			<Watch.Controls broadcast={broadcast} video={video} audio={audio} root={root} />
		</div>
	);
}
