import { MoqVideo } from "@kixelated/moq/element/video"

import Fail from "./fail"

import { createEffect, createMemo, createSignal, onCleanup } from "solid-js"

export default function Watch(props: { path: string }) {
	// Use query params to allow overriding environment variables.
	const urlSearchParams = new URLSearchParams(window.location.search)
	const params = Object.fromEntries(urlSearchParams.entries())
	const server = params.server ?? import.meta.env.PUBLIC_RELAY_HOST

	const [error, setError] = createSignal<Error | undefined>()

	const element = createMemo(() => {
		const video = new MoqVideo();
		video.src = `https://${server}/${props.path}`;
		video.autoplay = true;
		video.classList.add("aspect-video", "w-full", "rounded-lg");
		return video;
	})

	// NOTE: The canvas automatically has width/height set to the decoded video size.
	// TODO shrink it if needed via CSS
	return (
		<>
			<Fail error={error()} />
			{element()}
		</>
	)
}
