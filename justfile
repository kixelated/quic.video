#!/usr/bin/env just --justfile

# Using Just: https://github.com/casey/just?tab=readme-ov-file#installation

# List all of the available commands.
default:
  just --list

# Run the CI checks
check:
	pnpm i

	# Lint the JS packages
	pnpm exec biome check

	# Make sure Typescript compiles
	pnpm run check

	# Make sure the JS packages are not vulnerable
	# pnpm exec pnpm audit

	# TODO: Check for unused imports (fix the false positives)
	# pnpm exec knip --no-exit-code

# Automatically fix some issues.
fix:
	# Fix the JS packages
	pnpm i

	# Format and lint
	pnpm exec biome check --fix

	# Some additional linting.
	pnpm exec eslint . --fix

	# Make sure the JS packages are not vulnerable
	# pnpm exec pnpm audit --fix

# Run any CI tests
test:
	# Run the JS tests via node.
	pnpm test

# Upgrade any tooling
upgrade:
	# Update the NPM dependencies
	pnpm self-update
	pnpm update
	pnpm outdated

# Build the packages
build:
	pnpm i
	pnpm astro build

# Deploy the site to Cloudflare Pages
deploy env="staging": build
	pnpm wrangler deploy --env {{env}}

dev:
	pnpm i

	# Run the web development server
	pnpm astro dev --open

preview: build
	pnpm astro preview --open
