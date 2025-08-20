// Use the hang web components.
import "@kixelated/hang/support/element";
import "@kixelated/hang/watch/element";

export default function () {
	const params = new URLSearchParams(window.location.search);
	const name = params.get("name") ?? "bbb";

	let url: URL;
	if (name === "bbb") {
		url = new URL(`${import.meta.env.PUBLIC_RELAY_URL}/demo?jwt=${import.meta.env.PUBLIC_RELAY_TOKEN}`);
	} else {
		url = new URL(import.meta.env.PUBLIC_CLOUDFLARE_URL);
	}

	return (
		<>
			<hang-support prop:mode="watch" prop:show="partial" />

			<hang-watch prop:url={url} prop:name={name} prop:muted={true} prop:controls={true} prop:captions={true}>
				<canvas style={{ "max-width": "100%", height: "auto", margin: "0 auto", "border-radius": "1rem" }} />
			</hang-watch>

			<div class="mt-16">
				<h3 class="inline">Share URL:</h3>{" "}
				<a href={`/watch?name=${name}`} class="ml-2">
					{name}
				</a>
			</div>
		</>
	);
}
