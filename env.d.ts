/// <reference types="astro/client" />

interface ImportMetaEnv {
	readonly PUBLIC_RELAY_HOST: string;
	readonly PUBLIC_RELAY_PROTO: "http" | "https";
}

interface ImportMeta {
	readonly env: ImportMetaEnv;
}
