import "@kixelated/moq/video";
import { createEffect, createSignal, For, type Setter } from "solid-js";

// Exposes a region selector to allow overriding the region used by the relay.
export default function Region(props: { path: string; setUrl: Setter<string> }) {
	// Use query params to allow overriding environment variables.
	const urlSearchParams = new URLSearchParams(window.location.search);
	const params = Object.fromEntries(urlSearchParams.entries());

	const [region, setRegion] = createSignal<string | null>(params.region ?? null);
	const regions = import.meta.env.PUBLIC_RELAY_REGIONS ? import.meta.env.PUBLIC_RELAY_REGIONS.split(",") : [];
	const host = params.server || import.meta.env.PUBLIC_RELAY_HOST;

	createEffect(() => {
		const scheme = params.scheme || import.meta.env.PUBLIC_RELAY_SCHEME || "https";

		const r = region();
		const server = r === null ? host : `${r}.${host}`;

		props.setUrl(`${scheme}://${server}/${props.path}`);
	});

	return (
		<div class="flex gap-4 items-center mt-8 mb-8">
			<span
				class="font-bold"
				title="Connect to the indicated server. 'Auto' will use Geo-DNS to select the closest server for the best latency and quality. Select a far-away region to test the performance with increased congestion and latency."
			>
				Relay:
			</span>
			<button
				type="button"
				onClick={() => setRegion(null)}
				classList={{
					"bg-blue-500": region() === null,
				}}
			>
				auto
			</button>
			<For each={regions}>
				{(r) => (
					<button type="button" onClick={() => setRegion(r)} classList={{ "bg-blue-500": region() === r }}>
						{r}
					</button>
				)}
			</For>
		</div>
	);
}
