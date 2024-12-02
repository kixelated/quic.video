import "@kixelated/moq" // Import the MoQ custom elements
import type { MoqVideoElement } from "@kixelated/moq"
import type { DOMAttributes } from "react"

type CustomElement<T> = Partial<T & DOMAttributes<T> & { children: React.ReactNode }>;

declare global {
	namespace JSX {
	  interface IntrinsicElements {
		'moq-video': CustomElement<MoqVideoElement>;
		'canvas': React.DetailedHTMLProps<React.CanvasHTMLAttributes<HTMLCanvasElement>, HTMLCanvasElement>;
	  }
	}
  }

export default function Watch(props: { path: string }) {
	const server = "localhost:4443" //params.server ?? import.meta.env.PUBLIC_RELAY_HOST

	return <moq-video src={`https://${server}/${props.path}`} autoplay={true}>
		<canvas slot="canvas" style={{borderRadius: "0.5em"}} />
	</moq-video>;
}
