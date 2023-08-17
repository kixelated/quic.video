import { Broadcast } from "@kixelated/moq/contribute"
import { Connection, Client } from "@kixelated/moq/transport"
import { asError } from "@kixelated/moq/common"

import { createEffect, createSignal, Match, Show, Switch } from "solid-js"

import { Preview } from "./preview"
import { Setup } from "./setup"

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

	const [broadcast, setBroadcast] = createSignal<Broadcast | undefined>()

	return (
		<div class="flex flex-col overflow-hidden rounded-lg bg-gray-100 shadow-xl ring-1 ring-gray-900/5">
			<Show when={error()}>
				<div class="bg-red-400 px-4 py-2 font-bold">
					{error()?.name}: {error()?.message}
				</div>
			</Show>

			<div class="p-6">
				<Switch>
					<Match when={broadcast()}>
						<Preview broadcast={broadcast()!} setBroadcast={setBroadcast} setError={setError} />
					</Match>
					<Match when={!broadcast()}>
						<Setup connection={connection()} setBroadcast={setBroadcast} setError={setError} />
					</Match>
				</Switch>
			</div>
		</div>
	)
}
