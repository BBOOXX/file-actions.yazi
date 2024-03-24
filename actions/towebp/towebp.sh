#!/usr/bin/env bash
set -e
IFS=$'\t'

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

if command -v parallel >/dev/null 2>&1; then
	parallel '
	magick {} -quality ${quality} $([ "$lossless" = true ] && echo "-define	webp:lossless=true") {.}.webp &&
	touch -r {} {.}.webp
	' ::: $selection
else
	for file in ${selection}; do
		magick "$file" -quality ${quality} $([ "$lossless" = true ] && echo $'-define\twebp:lossless=true') "${file%.*}.webp"
		touch -r "$file" "${file%.*}.webp"
	done
fi
