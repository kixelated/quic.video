import { Player } from "@kixelated/moq/playback"
import { Client, Connection } from "@kixelated/moq/transport"

import { Failure, Issues } from "@/components/notice"

import { useEffect, useRef, useState } from "react"
import { Catalog } from "@kixelated/moq/media"
import { Listing } from "@/components/listing"

export function Watch() {
	const [ error, setError ] = useState<Error | undefined>();

	// Render the canvas when the DOM is inserted
	const canvas = useRef<HTMLCanvasElement>(null);

	const server = process.env.RELAY_HOST || "";
	const name = "foobar" // TODO based on query params.

	const [ connection, setConnection ] = useState<Connection| undefined>();
	useEffect(() => {
		const url = `https://${server}/${name}`

		// Special case localhost to fetch the TLS fingerprint from the server.
		// TODO remove this when WebTransport correctly supports self-signed certificates
		const fingerprint = server.startsWith("localhost")
			? `https://${server}/fingerprint`
			: undefined

		const client = new Client({
			url,
			fingerprint,
			role: "subscriber",
		})

		client.connect().then(setConnection).catch(setError)
	}, [ server, name ])

	useEffect(() => {
		connection?.closed().then(setError).catch(setError);
		return () => connection?.close()
	}, [connection]);

	const [ _player, setPlayer ] = useState<Player | undefined>();
	const [ catalog, setCatalog ] = useState<Catalog | undefined>();

	useEffect(() => {
		if (!canvas.current) return;
		if (!connection) return;

		const player = new Player({ connection, canvas: canvas.current })
		setPlayer(player)

		player.closed().then(setError).catch(setError)
		player.catalog().then(setCatalog).catch(setError)

		return () => player.close()
	}, [connection, canvas]);

	// NOTE: The canvas automatically has width/height set to the decoded video size.
	// TODO shrink it if needed via CSS
	return (
		<>
			<Issues />
			<Failure error={error} />

			<canvas height="0" className="rounded-md" ref={canvas} />
			<Listing name={name} catalog={catalog} />
		</>
	)
}
