#!/usr/bin/env bash
set -e
IFS=$'\t'

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

for file in ${selection}; do
	if [[ "$(uname -s)" == "Darwin" && "$(uname -m)" == "arm64" ]];then
		ffmpeg -hwaccel videotoolbox -i "$file" -vcodec h264_videotoolbox -vf scale=420:-2,format=yuv420p -vb 500k -n "${file%.*}.mp4"
	else
		ffmpeg -i "$file" -vf scale=420:-2,format=yuv420p -n "${file%.*}.mp4"
	fi
    touch -r "$file" "${file%.*}.mp4"
done
