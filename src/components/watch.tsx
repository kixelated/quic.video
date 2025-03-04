import "@kixelated/moq/watch";
import "@kixelated/moq/watch/ui";

import { createSignal } from "solid-js";

import Region from "@/components/region";

export default function Watch(props: { path: string }) {
	const [url, setUrl] = createSignal<string>("");

	return (
		<div>
			<moq-watch-ui class="rounded-lg overflow-hidden">
				<moq-watch prop:url={url()} prop:latency={100} />
			</moq-watch-ui>

			<Region setUrl={setUrl} path={props.path} />
		</div>
	);
}
