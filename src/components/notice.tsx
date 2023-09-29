/* eslint-disable @next/next/no-img-element */

import Link from "next/link"

export function Issues() {
	return (
		<div className="my-2 flex flex-row items-center gap-4 rounded-md bg-slate-700 px-4 py-2">
			<img src="/img/warning.svg" alt="Warning" className="h-12" />
			<div>
				This is an early-stage proof-of-concept. Check out the current <Link href="/issues">limitations</Link>.
				Contributions are welcome!
			</div>
		</div>
	)
}

export function Failure(props: { error?: Error }) {
	if (!props.error) return null

	return (
		<div className="rounded-md bg-red-600 px-4 py-2 font-bold">
			{props.error.name}: {props.error.message}
		</div>
	)
}
