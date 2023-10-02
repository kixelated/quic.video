import { defineConfig } from "astro/config"
import tailwind from "@astrojs/tailwind"
import mdx from "@astrojs/mdx"
import nodejs from "@astrojs/node"
import solidJs from "@astrojs/solid-js"

// https://astro.build/config
export default defineConfig({
	integrations: [
		mdx(),
		tailwind({
			// Disable injecting a basic `base.css` import on every page.
			applyBaseStyles: false,
		}),
		solidJs(),
	],
	adapter: nodejs({
		mode: "middleware", // or 'standalone'
	}),
	output: "hybrid",
})
