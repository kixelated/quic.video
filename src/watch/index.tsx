import { Connection, Client } from "@kixelated/moq/transport"
import { Player } from "@kixelated/moq/playback"
import { asError } from "@kixelated/moq/common"

import { createSignal, createEffect, Show, Switch, Match } from "solid-js"
import { Setup } from "./setup"
import { Controls } from "./controls"

export function Main() {
	const [error, setError] = createSignal<Error | undefined>()
	const [connection, setConnection] = createSignal<Connection | undefined>()

	const params = new URLSearchParams(window.location.search)

	let url = params.get("url") ?? undefined
	let fingerprint = params.get("fingerprint") ?? undefined

	// Change the default URL based on the environment.
	if (process.env.NODE_ENV === "production") {
		url ??= "https://moq-demo.englishm.net:4443"
	} else {
		url ??= "https://localhost:4443"
		fingerprint ??= url + "/fingerprint"
	}

	const client = new Client({
		url,
		role: "both",
		fingerprint,
	})

	createEffect(async () => {
		try {
			const conn = await client.connect()
			setConnection(conn)
			await conn.run()
		} catch (e) {
			setError(asError(e))
		} finally {
			setConnection()
		}
	})

	createEffect(() => {
		const err = error()
		if (err) console.error(err)
	})

	const [player, setPlayer] = createSignal<Player | undefined>()

	return (
		<div class="flex flex-col overflow-hidden rounded-lg bg-gray-100 shadow-xl ring-1 ring-gray-900/5">
			<Show when={error()}>
				<div class="bg-red-400 px-4 py-2 font-bold">
					{error()?.name}: {error()?.message}
				</div>
			</Show>

			<div class="p-6">
				<Switch fallback="Connecting...">
					<Match when={player()}>
						<Controls player={player()!} setError={setError} setPlayer={setPlayer} />
					</Match>
					<Match when={connection()}>
						<Setup connection={connection()!} setPlayer={setPlayer} setError={setError} />
					</Match>
				</Switch>
			</div>
		</div>
	)
}
