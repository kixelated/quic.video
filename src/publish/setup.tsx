import { Broadcast, VideoEncoder, AudioEncoderCodecs } from "@kixelated/moq/contribute"
import { Connection } from "@kixelated/moq/transport"
import { asError } from "@kixelated/moq/common"

import { createEffect, Switch, Match, createMemo, createSignal, For, createResource, createSelector } from "solid-js"

import { SetStoreFunction, Store, createStore } from "solid-js/store"

interface AudioConfig {
	sampleRate: number
	bitrate: number
	codec: string
	deviceId: string
}

const AUDIO_CONSTRAINTS = {
	sampleRate: [44100, 48000],
	bitrate: { min: 64_000, max: 256_000 },
	codec: AudioEncoderCodecs,
}

const AUDIO_DEFAULT = {
	sampleRate: 48000,
	bitrate: 128_000,
	codec: AudioEncoderCodecs[0],
	deviceId: "",
}

interface VideoConfig {
	height: number
	fps: number
	bitrate: number
	codec: string
	deviceId: string
}

interface VideoCodec {
	name: string
	profile: string
	value: string
}

const VIDEO_CODEC_UNDEF: VideoCodec = { name: "", profile: "", value: "" }

const VIDEO_CONSTRAINTS = {
	height: [240, 360, 480, 720, 1080],
	fps: [15, 30, 60],
	bitrate: { min: 500_000, max: 4_000_000 },
}

// We have to pay for bandwidth so we're cheap and default to 480p
const VIDEO_DEFAULT: VideoConfig = {
	height: 480,
	fps: 30,
	bitrate: 1_500_000,
	codec: "",
	deviceId: "",
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

export function Setup(props: {
	connection: Connection | undefined
	setBroadcast(v: Broadcast | undefined): void
	setError(e: Error): void
}) {
	const [name, setName] = createSignal("")
	const [audio, setAudio] = createStore<AudioConfig>(AUDIO_DEFAULT)
	const [video, setVideo] = createStore<VideoConfig>(VIDEO_DEFAULT)
	const [inputDevices, setInputDevices] = createStore<MediaDeviceInfo[]>([])

	const [loading, setLoading] = createSignal(false)

	const [broadcast] = createResource(loading, async () => {
		const width = Math.ceil((video.height * 16) / 9)

		const media = await window.navigator.mediaDevices.getUserMedia({
			audio: {
				sampleRate: { ideal: audio.sampleRate },
				channelCount: { max: 2, ideal: 2 },
				deviceId: audio.deviceId,
			},
			video: {
				aspectRatio: { ideal: 16 / 9 },
				width: { ideal: width, max: width },
				height: { ideal: video.height, max: video.height },
				frameRate: { ideal: video.fps, max: video.fps },
				deviceId: video.deviceId,
			},
		})

		const conn = props.connection
		if (!conn) throw new Error("disconnected")

		let full = name() != "" ? name() : crypto.randomUUID()
		full = `anon.quic.video/${full}`

		return new Broadcast({
			conn,
			media,
			name: full,
			audio: { codec: "opus", bitrate: 128_000 },
			video: { codec: video.codec, bitrate: video.bitrate },
		})
	})

	createEffect(() => {
		try {
			const b = broadcast()
			props.setBroadcast(b)
		} catch (e) {
			props.setError(asError(e))
		} finally {
			setLoading(false)
		}
	})

	// Fetch the list of devices.
	const [devices] = createResource(async () => {
		return await window.navigator.mediaDevices.enumerateDevices()
	})

	createEffect(() => {
		const allDevices = devices()
		if (allDevices && allDevices.length > 0) {
			setInputDevices(
				allDevices.filter(
					(device: MediaDeviceInfo) => device.kind == "videoinput" || device.kind == "audioinput",
				),
			)
		}
	})

	const getDevices = (deviceType: MediaDeviceKind) => {
		return inputDevices.filter((device: MediaDeviceInfo) => device.kind == deviceType)
	}

	const start = (e: Event) => {
		e.preventDefault()
		setLoading(true)
	}

	const state = createMemo(() => {
		if (!props.connection) return "connecting"
		if (broadcast.loading) return "loading"
		return "ready"
	})

	const isState = createSelector(state)

	return (
		<form class="grid grid-cols-3 items-center justify-center gap-x-4 gap-y-2 text-sm">
			<General name={name()} setName={setName} />
			<Video config={video} setConfig={setVideo} devices={getDevices("videoinput")} />
			<Audio config={audio} setConfig={setAudio} devices={getDevices("audioinput")}/>

			<button
				class="col-start-2 mt-3 rounded-md bg-green-500 px-3 py-2 text-sm font-semibold shadow-sm hover:bg-green-600 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2"
				type="submit"
				onClick={start}
			>
				<Switch>
					<Match when={isState("ready")}>Go Live</Match>
					<Match when={isState("loading")}>Loading</Match>
					<Match when={isState("connecting")}>Connecting</Match>
				</Switch>
			</button>
		</form>
	)
}

function General(props: { name: string; setName(name: string): void }) {
	return (
		<>
			<div class="col-span-3 mt-3 border-b-2 border-green-500 pl-3 text-lg">General</div>
			<label for="name" class="col-start-1 block font-medium">
				Name
			</label>
			<div class="form-input col-span-2 w-full rounded-md border-0 bg-slate-700 text-sm">
				<span>anon.quic.video/</span>
				<input
					type="text"
					name="name"
					placeholder="random"
					class="block border-0 bg-transparent p-1 pl-3 text-sm placeholder-slate-400 focus:ring-0"
					value={props.name}
					onInput={(e) => props.setName(e.target.value)}
				/>
			</div>
		</>
	)
}

function Video(props: {
	config: Store<VideoConfig>
	setConfig: SetStoreFunction<VideoConfig>
	devices: MediaDeviceInfo[]
}) {
	const [codec, setCodec] = createStore<VideoCodec>(VIDEO_CODEC_UNDEF)
	const [deviceId, setDeviceId] = createSignal(props.devices[0]?.deviceId)

	// Fetch the list of supported codecs.
	const [supportedCodecs] = createResource(
		() => ({ height: props.config.height, fps: props.config.fps, bitrate: props.config.bitrate }),
		async (config) => {
			const isSupported = async (codec: VideoCodec) => {
				const supported = await VideoEncoder.isSupported({
					codec: codec.value,
					width: Math.ceil((config.height * 16) / 9),
					...config,
				})

				if (supported) return codec
			}

			// Call isSupported on each codec
			const promises = VIDEO_CODECS.map((codec) => isSupported(codec))

			// Wait for all of the promises to return
			const codecs = await Promise.all(promises)

			// Remove any undefined values, using this syntax so Typescript knows they aren't undefined
			return codecs.filter((codec): codec is VideoCodec => !!codec)
		},
		{ initialValue: [] },
	)

	// Default to the first valid codec if the settings are invalid.
	createEffect(() => {
		const supported = supportedCodecs()
		const valid = supported.find((supported) => {
			return supported.name == codec.name && supported.profile == codec.profile
		})

		// If we found a valid codec, make sure the valid is set
		if (valid) return setCodec(valid)

		// We didn't find a valid codec, so default to the first supported one.
		const defaultCodec = supported.at(0)
		if (defaultCodec) {
			setCodec(defaultCodec)
		} else {
			// Nothing supports this configuration, wipe the form
			setCodec(VIDEO_CODEC_UNDEF)
		}
	})

	// Return supported codec names in preference order.
	const supportedCodecNames = () => {
		const unique = new Set<string>()
		for (const codec of supportedCodecs()) {
			if (!unique.has(codec.name)) unique.add(codec.name)
		}
		return [...unique]
	}

	// Returns supported codec profiles in preference order.
	const supportedCodecProfiles = () => {
		const unique = new Set<string>()
		for (const supported of supportedCodecs()) {
			if (supported.name == codec.name && !unique.has(supported.profile)) unique.add(supported.profile)
		}
		return [...unique]
	}

	const getDeviceId = (deviceId: string) => {
		const device = props.devices.find((device: MediaDeviceInfo) => device.deviceId == deviceId)
		return device ? device.deviceId : ""
	}

	// Update the store with our computed value.
	createEffect(() => {
		props.setConfig({ codec: codec.value })
	})

	createEffect(() => {
		props.setConfig({ deviceId: deviceId() })
	})

	return (
		<>
			<div class="col-span-3 mt-3 border-b-2 border-green-500 pl-3 text-lg">Video</div>
			<label class="col-start-1 font-medium leading-6">Video Input</label>
			<select
				name="videoInputDeviceId"
				class="rounded-md border-0 bg-slate-700 text-sm shadow-sm focus:ring-1 focus:ring-inset focus:ring-green-500"
				onInput={(e) => setDeviceId(getDeviceId(e.target.value))}
			>
				<For each={[...props.devices]}>
					{(device) => {
						return (
							<option value={device.deviceId} selected={deviceId() === device.deviceId}>
								{device.label}
							</option>
						)
					}}
				</For>
			</select>
			<label class="col-start-1 font-medium leading-6">Codec</label>
			<select
				name="codec"
				class="rounded-md border-0 bg-slate-700 text-sm shadow-sm focus:ring-1 focus:ring-inset focus:ring-green-500"
				onInput={(e) => setCodec({ name: e.target.value })}
			>
				<For each={[...supportedCodecNames()]}>
					{(supported) => {
						return (
							<option value={supported} selected={supported === codec.name}>
								{supported}
							</option>
						)
					}}
				</For>
			</select>
			<select
				name="profile"
				class="col-start-3 rounded-md border-0 bg-slate-700 text-sm shadow-sm focus:ring-1 focus:ring-inset focus:ring-green-500"
				onInput={(e) => setCodec({ profile: e.target.value })}
			>
				<For each={[...supportedCodecProfiles()]}>
					{(supported) => {
						return (
							<option value={supported} selected={supported === codec.profile}>
								{supported}
							</option>
						)
					}}
				</For>
			</select>
			<label class="col-start-1 font-medium leading-6">Resolution</label>
			<select
				name="resolution"
				class="rounded-md border-0 bg-slate-700 text-sm focus:ring-1 focus:ring-inset focus:ring-green-500"
				onInput={(e) => props.setConfig({ height: parseInt(e.target.value) })}
			>
				<For each={VIDEO_CONSTRAINTS.height}>
					{(res) => {
						return (
							<option value={res} selected={res === props.config.height}>
								{res}p
							</option>
						)
					}}
				</For>
			</select>
			<select
				name="fps"
				class="rounded-md border-0 bg-slate-700 text-sm shadow-sm focus:ring-1 focus:ring-inset focus:ring-green-500"
				onInput={(e) => props.setConfig({ fps: parseInt(e.target.value) })}
			>
				<For each={VIDEO_CONSTRAINTS.fps}>
					{(fps) => {
						return (
							<option value={fps} selected={fps === props.config.fps}>
								{fps}fps
							</option>
						)
					}}
				</For>
			</select>
			<label class="col-start-1 font-medium leading-6">Bitrate</label>
			<input
				type="range"
				name="bitrate"
				min={VIDEO_CONSTRAINTS.bitrate.min}
				max={VIDEO_CONSTRAINTS.bitrate.max}
				step="1000"
				value={props.config.bitrate}
				onInput={(e) => props.setConfig({ bitrate: parseInt(e.target.value) })}
			/>
			<span class="text-xs leading-6">{Math.floor(props.config.bitrate / 1000)} Kb/s</span>
		</>
	)
}

function Audio(props: {
	config: Store<AudioConfig>
	setConfig: SetStoreFunction<AudioConfig>
	devices: MediaDeviceInfo[]
}) {
	const [deviceId, setDeviceId] = createSignal(props.devices[0]?.deviceId)

	const getDeviceId = (deviceId: string) => {
		const device = props.devices.find((device: MediaDeviceInfo) => device.deviceId == deviceId)
		return device ? device.deviceId : ""
	}

	createEffect(() => {
		props.setConfig({ deviceId: deviceId() })
	})

	return (
		<>
			<div class="col-span-3 mt-3 border-b-2 border-green-500 pl-3 text-lg">Audio</div>
			<label class="col-start-1 font-medium leading-6">Audio Input</label>
			<select
				name="audioInputDeviceId"
				class="rounded-md border-0 bg-slate-700 text-sm shadow-sm focus:ring-1 focus:ring-inset focus:ring-green-500"
				onInput={(e) => setDeviceId(getDeviceId(e.target.value))}
			>
				<For each={[...props.devices]}>
					{(device) => {
						return (
							<option value={device.deviceId} selected={deviceId() === device.deviceId}>
								{device.label}
							</option>
						)
					}}
				</For>
			</select>
			<label for="codec" class="col-start-1 font-medium leading-6">
				Codec
			</label>
			<select
				name="codec"
				class="rounded-md border-0 bg-slate-700 text-sm shadow-sm focus:ring-1 focus:ring-inset focus:ring-green-500"
				onInput={(e) => props.setConfig({ codec: e.target.value })}
			>
				<For each={AUDIO_CONSTRAINTS.codec}>
					{(supported) => {
						return (
							<option value={supported} selected={supported === props.config.codec}>
								{supported}
							</option>
						)
					}}
				</For>
			</select>
			<select
				name="sampleRate"
				class="rounded-md border-0 bg-slate-700 text-sm shadow-sm focus:ring-1 focus:ring-inset focus:ring-green-500"
				onInput={(e) => props.setConfig({ sampleRate: parseInt(e.target.value) })}
			>
				<For each={AUDIO_CONSTRAINTS.sampleRate}>
					{(supported) => {
						return (
							<option value={supported} selected={supported === props.config.sampleRate}>
								{supported}hz
							</option>
						)
					}}
				</For>
			</select>
			<label for="bitrate" class="col-start-1 font-medium">
				Bitrate
			</label>
			<input
				type="range"
				name="bitrate"
				min={AUDIO_CONSTRAINTS.bitrate.min}
				max={AUDIO_CONSTRAINTS.bitrate.max}
				step="1000"
				value={props.config.bitrate}
				onInput={(e) => props.setConfig({ bitrate: parseInt(e.target.value) })}
			/>
			<span class="text-left text-xs">{Math.floor(props.config.bitrate / 1000)} Kb/s</span>
		</>
	)
}
