// Use the hang web components.
import "@kixelated/hang/support/element";
import "@kixelated/hang/watch/element";

export default function (props: { name: string; token?: string }) {
	// The signed token is only needed for the demo/ prefix just to prevent abuse.
	// All other broadcasts go to anon/ which is super easy to spoof.
	const url = new URL(
		`${import.meta.env.PUBLIC_RELAY_SCHEME}://${import.meta.env.PUBLIC_RELAY_HOST}/${props.name}${props.token ? `?jwt=${props.token}` : ""}`,
	);

	return (
		<>
			<hang-support prop:mode="watch" prop:show="partial" />

			<hang-watch prop:url={url} prop:muted={true} prop:controls={true}>
				<canvas style={{ "max-width": "100%", height: "auto", margin: "0 auto", "border-radius": "1rem" }} />
			</hang-watch>
		</>
	);
}
