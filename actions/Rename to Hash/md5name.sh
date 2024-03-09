set -e
IFS=$'\t'

for file in ${selection}; do
	digest=`md5 -q "$file"`
	mv "$file" "${file%/*}/${digest%% *}.${file##*.}"
done
