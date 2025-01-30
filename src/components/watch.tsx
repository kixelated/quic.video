import "@kixelated/moq/watch";

export default function Watch(props: { path: string }) {
	// Use query params to allow overriding environment variables.
	const urlSearchParams = new URLSearchParams(window.location.search);
	const params = Object.fromEntries(urlSearchParams.entries());

	const proto = params.proto ?? import.meta.env.PUBLIC_RELAY_PROTO;
	const server = params.server ?? import.meta.env.PUBLIC_RELAY_HOST;

	const url = `${proto}://${server}/${props.path}`;

	return <moq-watch prop:url={url} prop:controls={true} prop:status={true} class="rounded-lg" />;
}
