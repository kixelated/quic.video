import { Broadcast } from "@kixelated/moq/contribute"

import { createEffect, createSignal, Match, Show, Switch } from "solid-js"

import { Preview } from "./preview"
import { Setup } from "./setup"

export function Main() {
	const [error, setError] = createSignal<Error | undefined>()
	const [broadcast, setBroadcast] = createSignal<Broadcast | undefined>()

	createEffect(() => {
		const err = error()
		if (err) console.error(err)
	})

	return (
		<div class="flex flex-col">
			<Show when={error()}>
				<div class="bg-red-600 px-4 py-2 font-bold">
					{error()?.name}: {error()?.message}
				</div>
			</Show>

			<Switch>
				<Match when={broadcast()}>
					<Preview broadcast={broadcast()!} />
				</Match>
				<Match when={!broadcast()}>
					<Setup setBroadcast={setBroadcast} setError={setError} />
				</Match>
			</Switch>
		</div>
	)
}
