import "@kixelated/moq";

export default function Watch(props: { path: string }) {
	// Use query params to allow overriding environment variables.
	const urlSearchParams = new URLSearchParams(window.location.search);
	const params = Object.fromEntries(urlSearchParams.entries());
	const server = params.server ?? import.meta.env.PUBLIC_RELAY_HOST;

	const url = `https://${server}/${props.path}`;

	return (
		<moq-video prop:src={url} prop:autoplay={true}>
			<canvas slot="canvas" class="rounded-lg" />
		</moq-video>
	);
}
