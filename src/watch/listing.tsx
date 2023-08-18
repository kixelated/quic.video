import { Connection } from "@kixelated/moq/transport"
import { Player, Broadcast, Broadcasts } from "@kixelated/moq/playback"
import { CatalogTrack, isAudioCatalogTrack, isVideoCatalogTrack, asError } from "@kixelated/moq/common"

import { For, createSignal, createEffect, Show } from "solid-js"

export function Listing(props: { connection: Connection; setPlayer(v: Player): void; setError(e: Error): void }) {
	// Create an object that we'll use to list all of the broadcasts
	const announced = new Broadcasts(props.connection)

	const [broadcast, setBroadcast] = createSignal<Broadcast | undefined>()
	const [broadcasts, setBroadcasts] = createSignal<Broadcast[]>([])

	createEffect(async () => {
		try {
			for (;;) {
				const broadcast = await announced.next()
				setBroadcasts((prev) => prev.concat(broadcast))
			}
		} catch (e) {
			props.setError(asError(e))
		}
	})

	createEffect(() => {
		const selected = broadcast()
		if (!selected) return

		const player = new Player(props.connection, selected)
		props.setPlayer(player)
	})

	return (
		<ul>
			<For each={broadcasts()} fallback={"No live broadcasts"}>
				{(broadcast) => {
					const select = () => {
						setBroadcast(broadcast)
					}
					return (
						<li class="mt-4">
							<Available broadcast={broadcast} select={select} />
						</li>
					)
				}}
			</For>
		</ul>
	)
}

function Available(props: { broadcast: Broadcast; select: () => void }) {
	// A function because Match doesn't work with Typescript type guards
	const trackInfo = (track: CatalogTrack) => {
		if (isVideoCatalogTrack(track)) {
			return (
				<>
					video: {track.codec} {track.width}x{track.height}
					<Show when={track.bit_rate}> {track.bit_rate} b/s</Show>
				</>
			)
		} else if (isAudioCatalogTrack(track)) {
			return (
				<>
					audio: {track.codec} {track.sample_rate}Hz {track.channel_count}ch
					<Show when={track.bit_rate}> {track.bit_rate} b/s</Show>
				</>
			)
		} else {
			return "unknown track type"
		}
	}

	const watch = (e: MouseEvent) => {
		e.preventDefault()
		props.select()
	}

	return (
		<>
			<a onClick={watch}>{props.broadcast.name.replace(/\//, " / ")}</a>
			<div class="ml-4 text-xs italic text-gray-300">
				<For each={props.broadcast.catalog.tracks}>
					{(track) => {
						return <div>{trackInfo(track)}</div>
					}}
				</For>
			</div>
		</>
	)
}
