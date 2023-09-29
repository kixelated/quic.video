"use client";

import { Broadcast, VideoEncoder, AudioEncoder } from "@kixelated/moq/contribute"
import { Client, Connection } from "@kixelated/moq/transport"

import { Issues, Failure } from "@/components/notice"

import { ReactNode, useEffect, useMemo, useReducer, useRef, useState } from "react"
import { Listing } from "@/components/listing"

const AUDIO_CODECS = [
	"Opus",
	"mp4a" // TODO support AAC
]

interface VideoCodec {
	name: string
	profile: string
	value: string
}

// A list of codecs and profiles sorted in preferred order.
// TODO automate this list by looping over profile/level pairs
const VIDEO_CODECS: VideoCodec[] = [
	// HEVC Main10 Profile, Main Tier, Level 4.0
	{ name: "h.265", profile: "main", value: "hev1.2.4.L120.B0" },

	// AV1 Main Profile, level 3.0, Main tier, 8 bits
	{ name: "av1", profile: "main", value: "av01.0.04M.08" },

	// AVC High Level 3
	{ name: "h.264", profile: "high", value: "avc1.64001e" },

	// AVC High Level 4
	{ name: "h.264", profile: "high", value: "avc1.640028" },

	// AVC High Level 5
	{ name: "h.264", profile: "high", value: "avc1.640032" },

	// AVC High Level 5.2
	{ name: "h.264", profile: "high", value: "avc1.640034" },

	// AVC Main Level 3
	{ name: "h.264", profile: "main", value: "avc1.4d001e" },

	// AVC Main Level 4
	{ name: "h.264", profile: "main", value: "avc1.4d0028" },

	// AVC Main Level 5
	{ name: "h.264", profile: "main", value: "avc1.4d0032" },

	// AVC Main Level 5.2
	{ name: "h.264", profile: "main", value: "avc1.4d0034" },

	// AVC Baseline Level 3
	{ name: "h.264", profile: "baseline", value: "avc1.42001e" },

	// AVC Baseline Level 4
	{ name: "h.264", profile: "baseline", value: "avc1.420028" },

	// AVC Baseline Level 5
	{ name: "h.264", profile: "baseline", value: "avc1.420032" },

	// AVC Baseline Level 5.2
	{ name: "h.264", profile: "baseline", value: "avc1.420034" },
]

export function Publish() {
	const [ name, setName ] = useState("");
	const [ conn, setConn ] = useState<Connection | undefined>()
	const [ input, setInput] = useState<MediaStream | undefined>()
	const [ audio, setAudio ] = useState<AudioEncoderConfig | undefined>()
	const [ video, setVideo ] = useState<VideoEncoderConfig | undefined>()

	const [advanced, toggleAdvanced] = useReducer((advanced) => !advanced, false);
	const [error, setError] = useState<Error | undefined>();

	const [ broadcast, start ] = useReducer(() => {
		if (!input) {
			setError(new Error("No media selected"))
			return
		}

		if (!conn) {
			setError(new Error("No connection"))
			return
		}

		return new Broadcast({
			connection: conn,
			media: input,
			audio,
			video,
		})
	}, undefined)

	useEffect(() => {
		if (!broadcast) return
		broadcast.closed().then(setError).catch(setError)
		return () => broadcast.close()
	}, [broadcast])

	// Close the connection on teardown
	useEffect(() => {
		return () => conn?.close()
	}, [conn])

	return (
		<>
			<Issues />
			<Failure error={error} />

			<Listing name={name} catalog={broadcast?.catalog} />

			<form>
				<Input setInput={setInput} setError={setError} audio={audio} video={video} />
				<Connect setName={name} setConn={setConn} setError={setError} advanced={advanced}/>
				<Video
					setConfig={setVideo}
					setError={setError}
					advanced={advanced}
				/>
				<Audio
					setConfig={setAudio}
					setError={setError}
					advanced={advanced}
				/>

				<button
					className="col-start-2 rounded-md bg-green-600 p-2 font-semibold shadow-sm hover:bg-green-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2"
					type="submit"
					onClick={start}
				>
					Go Live
				</button>
				<a onClick={toggleAdvanced} className="p-2 text-center">
					{advanced ? "Simple": "Advanced"}
				</a>
			</form>
		</>
	)
}

function Advanced(props: { enabled: boolean, children: ReactNode }) {
	if (!props.enabled) return
	return props.children
}

function Connect({ setConn, setError, advanced }: { setConn: (conn: Connection | undefined) => void, setError: (err: Error) => void, advanced: boolean }) {
	const [ server, setServer ] = useState(process.env.RELAY_HOST || "")
	const [ name, setName ] = useState(crypto.randomUUID())

	useEffect(() => {
		setConn(undefined)

		const url = `https://${server}/${name}`

		// Special case localhost to fetch the TLS fingerprint from the server.
		// TODO remove this when WebTransport correctly supports self-signed certificates
		const fingerprint = server.startsWith("localhost")
			? `https://${server}/fingerprint`
			: undefined

		const client = new Client({
			url,
			fingerprint,
			role: "publisher",
		})

		client.connect().then(setConn).catch(setError)
	}, [ setConn, setError, name, server ])

	return (
		<>
		<Advanced enabled={advanced}>
			<h1>General</h1>
			<label>
				Server
				<input
					type="text"
					name="server"
					placeholder={process.env.RELAY_HOST}
					className="rounded-md border-0 bg-slate-700 text-sm shadow-sm focus:ring-1 focus:ring-inset focus:ring-green-600"
					onBlur={(e) => setServer(e.target.value)}
				/>
			</label>

			<label>
				Name
				<input
					type="text"
					name="name"
					placeholder="random"
					className="col-span-2 rounded-md border-0 bg-slate-700 text-sm shadow-sm focus:ring-1 focus:ring-inset focus:ring-green-600"
					onBlur={(e) => setName(e.target.value)}
				/>
			</label>
		</Advanced>
		</>
	)
}

function Input({ setInput, setError, audio, video }: { setInput: (input: MediaStream) => void, setError: (err: Error) => void, audio: AudioEncoderConfig | undefined, video: VideoEncoderConfig | undefined }) {
	const [ mode, setMode ] = useState<"none" | "user" | "display">("none")
	const [ device, setDevice ] = useState<MediaStream | undefined>()

	const audioDevice = useMemo(() => {
		const tracks = device?.getAudioTracks();
		if (tracks && tracks.length > 0) return tracks[0]
	}, [ device ]);

	const videoDevice = useMemo(() => {
		const tracks = device?.getVideoTracks();
		if (tracks && tracks.length > 0) return tracks[0]
	}, [ device ]);

	const preview = useRef<HTMLVideoElement>(null);

	useEffect(() => {
		if (mode == "none") return;

		const getMedia = async (constraints: MediaStreamConstraints) => {
			if (mode == "user") {
				return navigator.mediaDevices.getUserMedia(constraints);
			 } else {
				return navigator.mediaDevices.getDisplayMedia(constraints);
			}
		};

		getMedia({
			audio: audio ? {
				channelCount: { ideal: 2, max: 2 },
				deviceId: audioDevice?.id, // Use the same selected device again
			} : false,
			video: video ? {
				aspectRatio: { ideal: 16 / 9 },
				height: { ideal: video.height, min: video.height },
				width: { ideal: video.width, min: video.width },
				frameRate: { ideal: video.framerate, min: video.framerate },
				deviceId: videoDevice?.id, // Use the same selected device again
			} : false,
		}).then(setDevice).catch(setError)
	}, [ setDevice, setError, audio, mode, video, audioDevice?.id, videoDevice?.id ])

	// Preview the input source.
	useEffect(() => {
		if (!device) return
		if (preview.current) preview.current.srcObject = device
		setInput(device)
	}, [ setInput, device, preview ])

	return (<>
				<h1>Preview</h1>
				<input type="button" onClick={() => setMode("user")}>Use Webcam</input>
				<input type="button" onClick={() => setMode("display")}>Use Screen</input>
				<video autoPlay muted className="rounded-md h-96" ref={preview} />
			</>)
}

function Video({setConfig, setError, advanced}: {
	setConfig: (config: VideoEncoderConfig | undefined) => void,
	setError: (err: Error) => void,
	advanced: boolean
}) {
	const [ enabled, setEnabled ] = useState(true);
	const [ height, setHeight ] = useState(480);
	const width = useMemo(() => Math.ceil((height * 16) / 9), [ height ]);
	const [ fps , setFps ] = useState(30);
	const [ bitrate, setBitrate ] = useState(1_500_000);
	const [ codec, setCodec ] = useState("")
	const [ profile, setProfile ] = useState("")
	const [ supported, setSupported ] = useState<VideoCodec[]>()

	// Fetch the list of supported codecs.
	useEffect(() => {
		const isSupported = async (codec: VideoCodec) => {
			const supported = await VideoEncoder.isSupported({
				codec: codec.value,
				width: width,
				height: height,
				framerate: fps,
				bitrate: bitrate,
			})

			if (supported) return codec
		}

		// Call isSupported on each codec
		const promises = VIDEO_CODECS.map((codec) => isSupported(codec))

		// Wait for all of the promises to return
		Promise.all(promises).then((codecs) => {
			// Remove any undefined values, using this syntax so Typescript knows they aren't undefined
			return codecs.filter((codec): codec is VideoCodec => !!codec)
		}).then(setSupported).catch(setError);
	}, [  bitrate, fps, width, height, setError ])

	// Return supported codec names in preference order.
	const supportedCodecNames = () => {
		const unique = new Set<string>()
		for (const codec of supported || []) {
			if (!unique.has(codec.name)) unique.add(codec.name)
		}
		return [...unique]
	}

	// Returns supported codec profiles in preference order.
	const supportedCodecProfiles = () => {
		const unique = new Set<string>()
		for (const valid of supported || []) {
			if (valid.name == codec && !unique.has(valid.profile))
				unique.add(valid.profile)
		}
		return [...unique]
	}

	// Update the config with a valid config
	useEffect(() => {
		if (!enabled) {
			setConfig(undefined)
			return;
		}

		if (!supported) return // wait until we load available codecs

		const valid = supported.find((supported) => {
			return supported.name == codec && supported.profile == profile
		})

		// We didn't find a valid codec, so default to the first supported one.
		if (!valid) {
			const defaultCodec = supported.at(0)
			if (defaultCodec) {
				// NOTE: This will cause this useEffect again, which will work this time
				setCodec(defaultCodec.name)
				setProfile(defaultCodec.profile)
			}

			setConfig(undefined)
			return
		}

		setConfig({
			codec: valid.value,
			height,
			width,
			bitrate: bitrate,
			framerate: fps,
		})
	}, [setConfig, enabled, codec, height, width, bitrate, fps, profile, supported])

	return (
		<>
		<h1>Video</h1>

			<label>
				Enabled
				<input
					type="checkbox"
					name="enabled"
					checked={enabled}
					onChange={(e) => setEnabled(e.target.checked)}
				/>
			</label>

		<Advanced enabled={advanced}>
			<label>
				Codec
				<select
					name="codec"
					className="rounded-md border-0 bg-slate-700 text-sm shadow-sm focus:ring-1 focus:ring-inset focus:ring-green-600"
					onChange={(e) => setCodec(e.target.value)}
				>
					{supportedCodecNames()?.map((v) =>
						<option key={v} value={v} selected={v === codec}>
							{v}
						</option>
					)}
				</select>
				<select
					name="profile"
					className="flex-grow rounded-md border-0 bg-slate-700 text-sm shadow-sm focus:ring-1 focus:ring-inset focus:ring-green-600"
					onChange={(e) => setProfile(e.target.value)}
				>
					{supportedCodecProfiles()?.map((v) =>
						<option key={v} value={v} selected={v === profile}>
							{v}
						</option>
					)}
				</select>
			</label>
		</Advanced>

		<label>
			Resolution
			<select
				name="resolution"
				className="rounded-md border-0 bg-slate-700 text-sm focus:ring-1 focus:ring-inset focus:ring-green-600"
				onChange={(e) => setHeight(parseInt(e.target.value))}
			>
				{[240, 360, 480, 720, 1080].map((v) =>
					<option key={v} value={v} selected={v === height}>
						{v}p
					</option>
				)}
			</select>
		</label>

		<Advanced enabled={advanced}>
			<select
				name="fps"
				className="rounded-md border-0 bg-slate-700 text-sm shadow-sm focus:ring-1 focus:ring-inset focus:ring-green-600"
				onChange={(e) => setFps(parseInt(e.target.value))}
			>
				{[15, 30, 60].map((v) =>
					<option key={v} value={v} selected={v=== fps}>
						{v}fps
					</option>
)}
			</select>
		</Advanced>

			<label>
				Bitrate
				<input
					type="range"
					name="bitrate"
					min={500_000}
					max={4_000_000}
					step={100_000}
					value={bitrate}
					onChange={(e) => setBitrate(parseInt(e.target.value))}
				/>
				<div>{(bitrate / 1_000_000).toFixed(1)} Mb/s</div>
			</label>
		</>
	)
}

function Audio({ setConfig, setError, advanced}: {
	setConfig: (config: AudioEncoderConfig | undefined) => void,
	setError: (err: Error) => void,
	advanced: boolean
}) {
	const [enabled, setEnabled ] = useState(true)
	const [ codec, setCodec ] = useState("")
	const [ bitrate, setBitrate ] = useState(128_000)
	const [ supported, setSupported ] = useState<string[]>([])

	// Fetch the list of supported codecs.
	useEffect(() => {
		const isSupported = async (codec: string) => {
			const supported = await AudioEncoder.isSupported({
				codec,
				bitrate: bitrate,
			})

			if (supported) return codec
		}

		// Call isSupported on each codec
		const promises = AUDIO_CODECS.map((codec) => isSupported(codec))

		// Wait for all of the promises to return
		Promise.all(promises).then((codecs) => {
			// Remove any undefined values, using this syntax so Typescript knows they aren't undefined
			return codecs.filter((codec): codec is string => !!codec)
		}).then(setSupported).catch(setError);
	}, [  bitrate, setError ])

	useEffect(() => {
		if (!enabled) {
			setConfig(undefined)
			return;
		}

		setConfig({
			codec,
			bitrate: bitrate,
		})
	}, [ setConfig, enabled, codec, bitrate ])

	return (
		<>
			<h1>Audio</h1>

			<label>
				Enabled
				<input
					type="checkbox"
					name="enabled"
					checked={enabled}
					onChange={(e) => setEnabled(e.target.checked)}
				/>
			</label>

			<Advanced enabled={advanced}>
				<label>
					Codec
					<select
						name="codec"
						className="rounded-md border-0 bg-slate-700 text-sm shadow-sm focus:ring-1 focus:ring-inset focus:ring-green-600"
						onChange={(e) => setCodec(e.target.value)}
					>
						{supported?.map((v) =>
							<option
							key={v}
								value={v}
								selected={v === codec}
							>
								{v}
							</option>
						)}
					</select>
				</label>

				<label>
					Bitrate
					<input
						type="range"
						name="bitrate"
						min={64_000}
						max={256_000}
						step={1_000}
						value={bitrate}
						onChange={(e) => setBitrate(parseInt(e.target.value))}
					/>
					<div>{Math.floor(bitrate / 1000)} Kb/s</div>
				</label>
			</Advanced>
		</>
	)
}
