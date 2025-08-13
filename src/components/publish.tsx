import { adjectives, animals, uniqueNamesGenerator } from "unique-names-generator";

import "@kixelated/hang/support/element";
import "@kixelated/hang/publish/element";

export default function () {
	const name = uniqueNamesGenerator({ dictionaries: [adjectives, animals], separator: "-" });
	const url = new URL(`${import.meta.env.PUBLIC_RELAY_URL}/anon`);

	return (
		<div>
			<hang-support prop:mode="publish" prop:show="partial" />

			<h3>Watch URL:</h3>
			<a href={`/watch?name=${name}`} rel="noreferrer" target="_blank" class="ml-2">
				{name}
			</a>

			<h3>Preview:</h3>
			<hang-publish
				prop:url={url}
				prop:name={name}
				prop:controls={true}
				prop:video={true}
				prop:audio={true}
				prop:captions={true}
			>
				<video
					style={{ "max-width": "100%", height: "100%", margin: "0 auto", "border-radius": "1rem" }}
					autoplay
					muted
				/>
			</hang-publish>
		</div>
	);
}
