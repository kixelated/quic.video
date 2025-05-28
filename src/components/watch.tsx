import { Support } from "@kixelated/hang";
import { Watch, WatchControls } from "@kixelated/hang";
import { onCleanup } from "solid-js";

export default function (props: { name: string; token?: string }) {
	// The signed token is only needed for the demo/ prefix just to prevent abuse.
	// All other broadcasts go to anon/ which is super easy to spoof.
	const url = new URL(
		`${import.meta.env.PUBLIC_RELAY_SCHEME}://${import.meta.env.PUBLIC_RELAY_HOST}/${props.token ? `demo/${props.token}` : `${props.name}.hang`}`,
	);
	const canvas = <canvas style={{ "max-width": "100%", height: "auto", margin: "0 auto", "border-radius": "1rem" }} />;

	const watch = new Watch({
		connection: {
			url,
		},
		audio: {
			muted: true,
		},
		video: {
			canvas: canvas as HTMLCanvasElement,
		},
	});

	let root!: HTMLDivElement;

	onCleanup(() => {
		watch.close();
	});

	return (
		<div ref={root}>
			{/* biome-ignore lint/a11y/useValidAriaRole: false-positive */}
			<Support role="watch" show="partial" />

			{canvas}

			<WatchControls lib={watch} root={root} />
		</div>
	);
}
