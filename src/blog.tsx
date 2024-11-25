export function Post(props: { name: string, cover: string, title: string, description: string, author: string, date: string }) {
	return <article className="mb-6 rounded-lg grid grid-cols-3 hover:bg-blue-950 hover:scale-110 hover:translate-x-2 transition-all ease-in-out">
		<a href={`/blog/${props.name}`} className="rounded-2xl">
			<img className="object-cover h-24 w-48 rounded-2xl" src={`/blog/${props.name}/${props.cover}`} alt="blog cover" />
		</a>
		<div className="grid grid-cols-1 col-span-2 gap-2 text-2xl place-content-center flex-grow">
			<a href={`/blog/${props.name}`} className="text-white">
				{props.title}
			</a>
			<div className="text-sm font-light">{props.description}</div>
			<div className="text-sm font-bold ">by {props.author}</div>
		</div>
	</article>
}
