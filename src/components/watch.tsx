import { Support } from "@kixelated/hang";
import { Watch, WatchControls } from "@kixelated/hang/watch";
import { onCleanup } from "solid-js";

export default function (props: { name: string }) {
	const url = new URL(
		`${import.meta.env.PUBLIC_RELAY_SCHEME}://${import.meta.env.PUBLIC_RELAY_HOST}/demo/${props.name}.hang`,
	);
	const canvas = <canvas style={{ "max-width": "100%", height: "100%", margin: "0 auto", "border-radius": "1rem" }} />;

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
