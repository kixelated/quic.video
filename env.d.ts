/// <reference types="astro/client" />

interface ImportMetaEnv {
	readonly PUBLIC_RELAY_SCHEME: "http" | "https"
	readonly PUBLIC_RELAY_HOST: string
	readonly PUBLIC_DEMO_TOKEN: string
}

interface ImportMeta {
	readonly env: ImportMetaEnv
}
