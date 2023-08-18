import { Broadcast } from "@kixelated/moq/contribute"
import { Listing } from "../common/catalog"

import { onMount } from "solid-js"

export function Preview(props: { broadcast: Broadcast }) {
	let preview: HTMLVideoElement

	onMount(() => {
		props.broadcast.preview(preview)
	})

	return (
		<>
			<Listing name={props.broadcast.name} catalog={props.broadcast.catalog} />
			<video ref={preview!} autoplay muted class="mt-6"></video>
		</>
	)
}
