/* eslint-disable @next/next/no-img-element */

import "./globals.css"
import type { Metadata } from "next"

import { Inter } from "next/font/google"
import Link from "next/link"

const inter = Inter({ subsets: ["latin"] })

export const metadata: Metadata = {
	title: "quic.video",
	description: "(live) Media over QUIC",
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
	return (
		<html lang="en">
			<body className={inter.className}>
				<div className="flex flex-col gap-4 sm:flex-row">
					<div className="flex-grow" />
					<nav className="flex basis-[120px] flex-row items-center sm:basis-[200px] sm:flex-col">
						<Link href="/" className="p-4">
							<img src="img/logo-small.svg" width="200" alt="Media over QUIC" />
						</Link>
						<div className="flex flex-row flex-wrap items-center justify-start gap-4 p-4 sm:justify-center">
							<Link href="/watch">
								<img src="img/watch.svg" width="120" alt="Watch" />
							</Link>
							<Link href="/publish">
								<img src="img/publish.svg" width="120" alt="Publish" />
							</Link>
							<Link href="/explain">
								<img src="img/explain.svg" width="120" alt="Explain" />
							</Link>
							<Link href="/github">
								<img src="img/github.svg" width="120" alt="Github" />
							</Link>
							<Link href="https://discord.gg/FCYF3p99mr">
								<img src="img/discord.svg" width="120" alt="Discord" />
							</Link>
						</div>
					</nav>
					<div className="basis-[720px]">{children}</div>
					<div className="flex-grow" />
				</div>
			</body>
		</html>
	)
}
