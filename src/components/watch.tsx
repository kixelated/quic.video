import "@kixelated/moq/watch";

import { createSignal } from "solid-js";

import Region from "@/components/region";

export default function Watch(props: { path: string }) {
	const [url, setUrl] = createSignal<string>("");

	return (
		<div>
			<moq-watch prop:url={url()} prop:controls={true} prop:status={true} class="rounded-lg overflow-hidden" />
			<Region setUrl={setUrl} path={props.path} />
		</div>
	);
}
