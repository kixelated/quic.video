/// <reference types="astro/client" />

interface ImportMetaEnv {
	readonly PUBLIC_RELAY_SCHEME: string;
	readonly PUBLIC_RELAY_HOST: string;
	readonly PUBLIC_RELAY_REGIONS: string;
}

interface ImportMeta {
	readonly env: ImportMetaEnv;
}
