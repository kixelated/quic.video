import fs from "node:fs"
import path from "node:path"
import mdx from "@astrojs/mdx"
import nodejs from "@astrojs/node"
import solidJs from "@astrojs/solid-js"
import tailwind from "@astrojs/tailwind"
import { defineConfig } from "astro/config"

import mkcert from "vite-plugin-mkcert"
import wasm from "vite-plugin-wasm"

// https://astro.build/config
export default defineConfig({
	integrations: [
		mdx(),
		solidJs(),
		tailwind({
			// Disable injecting a basic `base.css` import on every page.
			applyBaseStyles: false,
		}),
	],
	// Renders any non-static pages using node
	adapter: nodejs({
		mode: "standalone",
	}),
	// Default to static rendering, but allow server rendering per-page
	output: "hybrid",
	vite: {
		build: {
			target: "esnext",
		},
		base: "./",
		server: {
			// HTTPS is required for SharedArrayBuffer
			https: true,
			fs: {
				allow: [
					".",
					// Allow `bun link`
					fs.realpathSync(path.resolve("node_modules/@kixelated/moq")),
				],
			},
		},
		plugins: [
			// Generates a self-signed certificate using mkcert
			mkcert(),

			wasm(),
		],
		worker: {
			plugins: [wasm()],
		},
		resolve: {
			alias: {
				"@": "/src",
			},
		},
	},
	// Don't add trailing slashes to paths
	trailingSlash: "never",
})
