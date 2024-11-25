import "@kixelated/moq/element/video"
import type { MoqVideo } from "@kixelated/moq/element/video"
import type { DOMAttributes } from "react"

type CustomElement<T> = Partial<T & DOMAttributes<T> & { children: unknown }>;

declare global {
	namespace JSX {
	  interface IntrinsicElements {
		'moq-video': CustomElement<MoqVideo>;
	  }
	}
  }

export default function Watch(props: { path: string }) {
	// Use query params to allow overriding environment variables.
	const urlSearchParams = new URLSearchParams(window.location.search)
	const params = Object.fromEntries(urlSearchParams.entries())
	const server = "localhost:4443" //params.server ?? import.meta.env.PUBLIC_RELAY_HOST

	return <moq-video src={`https://${server}/${props.path}`} autoplay={true} className="aspect-video w-full rounded-lg" />;
}
