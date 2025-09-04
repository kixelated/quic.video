/// <reference types="astro/client" />

interface ImportMetaEnv {
	readonly PUBLIC_RELAY_URL: string;
	readonly PUBLIC_RELAY_TOKEN: string;
	readonly PUBLIC_CLOUDFLARE_URL: string;
}

interface ImportMeta {
	readonly env: ImportMetaEnv;
}
