import {
	Catalog,
	CatalogTrack,
	isAudioCatalogTrack,
	isVideoCatalogTrack,
} from "@kixelated/moq/media"

export function Listing(props: { name: string; catalog?: Catalog }) {
	const watchUrl = "/watch/" + props.name

	return (
		<div className="p-4">
			<a href={watchUrl} className="text-xl" target="_blank" rel="noreferrer">
				{props.name}
			</a>
			<Tracks catalog={props.catalog} />
		</div>
	)
}

function Tracks(props: { catalog?: Catalog }) {
	if (!props.catalog) return "loading..."

	return (
		<div className="ml-4 text-xs italic text-gray-300">
			{props.catalog.tracks.map((track, index) => (
				<Track key={index} track={track} />
			))}
		</div>
	)
}

function Track(props: { track: CatalogTrack }) {
	const track = props.track

	if (isVideoCatalogTrack(track)) {
		const bitrate = track.bit_rate ? (track.bit_rate / 1000000).toFixed(1) + " mb/s" : ""
		return (
			<p>
				video: {track.codec} {track.width}x{track.height} {bitrate}
			</p>
		)
	} else if (isAudioCatalogTrack(track)) {
		const bitrate = track.bit_rate ? Math.round(track.bit_rate / 1000) + "kb/s" : ""
		return (
			<p>
				audio: {track.codec} {track.sample_rate}Hz {track.channel_count}ch {bitrate}
			</p>
		)
	} else {
		return <p>unknown</p>
	}
}
