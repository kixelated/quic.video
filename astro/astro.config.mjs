import { defineConfig } from "astro/config"
import react from "@astrojs/react"
import tailwind from "@astrojs/tailwind"

import mdx from "@astrojs/mdx"

// https://astro.build/config
export default defineConfig({
	integrations: [
		react(),
		mdx(),
		tailwind({
			// Disable injecting a basic `base.css` import on every page.
			applyBaseStyles: false,
		}),
	],
})
