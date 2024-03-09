#!/bin/bash
set -e
IFS=$'\t'
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

for file in ${selection}; do
	if [[ "$(uname -m)" == "arm64" ]];then
		ffmpeg -hwaccel videotoolbox -i "$file" -vcodec hevc_videotoolbox -acodec copy -tag:v hvc1 "${file%.*}.HEVC.mp4"
	else
		ffmpeg -i "$file" -vcodec libx265 -acodec copy -tag:v hvc1 "${file%.*}.HEVC.mp4"
	fi
	touch -r "$file" "${file%.*}.HEVC.mp4" 
done
