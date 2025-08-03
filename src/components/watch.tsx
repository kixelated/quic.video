// Use the hang web components.
import "@kixelated/hang/support/element";
import "@kixelated/hang/watch/element";

export default function (props: { name: string; token?: string }) {
	// The signed token is only needed for the demo/ prefix just to prevent abuse.
	// All other broadcasts go to anon/ which is super easy to spoof.

	// Determine the path based on whether it's a demo broadcast or anonymous
	let url: URL;
	if (props.token) {
		url = new URL(`${import.meta.env.PUBLIC_RELAY_URL}/demo?jwt=${props.token}`);
	} else {
		// Anonymous broadcasts use /anon path without token
		url = new URL(`${import.meta.env.PUBLIC_RELAY_URL}/anon`);
	}

	return (
		<>
			<hang-support prop:mode="watch" prop:show="partial" />

			<hang-watch prop:url={url} prop:name={props.name} prop:muted={true} prop:controls={true} prop:captions={true}>
				<canvas style={{ "max-width": "100%", height: "auto", margin: "0 auto", "border-radius": "1rem" }} />
			</hang-watch>
		</>
	);
}
