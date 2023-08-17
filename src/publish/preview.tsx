import { Broadcast } from "@kixelated/moq/contribute"
import { asError } from "@kixelated/moq/common"

import { createEffect, onMount } from "solid-js"

export function Preview(props: { broadcast: Broadcast; setBroadcast(): void; setError(e: Error): void }) {
	let preview: HTMLVideoElement

	onMount(() => {
		props.broadcast.preview(preview)
	})

	createEffect(async () => {
		try {
			await props.broadcast.run()
		} catch (e) {
			props.setError(asError(e))
		} finally {
			props.setBroadcast()
		}
	})

	return <video ref={preview!} autoplay muted></video>
}
