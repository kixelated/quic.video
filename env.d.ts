/// <reference types="astro/client" />

interface ImportMetaEnv {
	readonly PUBLIC_RELAY_URL: string;
	readonly PUBLIC_RELAY_TOKEN: string;
}

interface ImportMeta {
	readonly env: ImportMetaEnv;
}
