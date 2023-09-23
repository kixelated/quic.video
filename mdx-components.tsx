import type { MDXComponents } from "mdx/types"
import Link from "next/link"
import { AnchorHTMLAttributes } from "react"

const MDXLink: React.FC<AnchorHTMLAttributes<HTMLAnchorElement>> = (props) => {
	// Check if the link is an external link
	const isExternal =
		props.href && (props.href.startsWith("http://") || props.href.startsWith("https://"))

	if (isExternal) {
		return <a {...props} target="_blank" rel="noopener noreferrer" />
	}

	return (
		<Link href={props.href || ""}>
			<a {...props} />
		</Link>
	)
}

// This file is required to use MDX in `app` directory.
export function useMDXComponents(components: MDXComponents): MDXComponents {
	return {
		// Convert <a> to <Link> tags.
		a: MDXLink,
		// Allows customizing built-in components, e.g. to add styling.
		// h1: ({ children }) => <h1 style={{ fontSize: "100px" }}>{children}</h1>,
		...components,
	}
}
