import { Content, usePageData } from 'rspress/runtime';

function Layout() {
	const page = usePageData().page;
	return <div className="flex flex-col md:flex-row gap-8 md:p-8 p-4 ">
			<nav className="flex flex-row items-center md:flex-col md:w-72 md:gap-12 gap-4 w-full">
				<a href="/" className="w-1/2 md:w-auto">
					<img src="/logo.svg" className="w-52" alt="Media over QUIC" />
				</a>
				<div className="flex flex-row flex-wrap items-center justify-center gap-4 w-1/2">
					<a href="/demo">
						<img src="/sidebar/watch.svg" className="w-28" alt="Watch" />
					</a>
					<a href="/publish">
						<img src="/sidebar/publish.svg" className="w-28" alt="Publish" />
					</a>
					<a href="/blog">
						<img src="/sidebar/explain.svg" className="w-28" alt="Blog" />
					</a>
					<a href="/source">
						<img src="/sidebar/source.svg" className="w-28" alt="Source" />
					</a>
					<a href="https://discord.gg/FCYF3p99mr">
						<img src="/sidebar/discord.svg" className="w-28" alt="Discord" />
					</a>
				</div>
			</nav>
			<article className="markdown">
				{ page.title && <h1>{page.title}</h1> }
				<Content />
			</article>
		</div>
}

// The setup function will be called when the page is initialized. It is generally used to monitor global events, and it can be an empty function
const setup = () => {};

// Export all content of the default theme to ensure that your theme configuration can work properly
export * from 'rspress/theme';

// Export Layout component and setup function
// Note: both must export
export default { Layout, setup };
