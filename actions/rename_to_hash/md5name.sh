#!/usr/bin/env bash
set -e
IFS=$'\t'

OS="$(uname -s)"

for file in ${selection}; do
	case "$OS" in
		Darwin) digest=`md5 -q "$file"` ;;
		Linux) digest=`md5sum "$file" | awk '{print $1}'` ;;
		*) echo "Unsupported operating system"; exit 1 ;;
	esac
	mv "$file" "${file%/*}/${digest%% *}.${file##*.}"
done
