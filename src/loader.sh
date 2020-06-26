#!/bin/bash

# File: loader.sh
# Author: René Michalke <rene@renemichalke.de>
# Last Change: 2020 Jun 26
# Description: A vim wrapper for tmsu.

# check for correct number of arguments
if [[ $# -ne 3 ]]; then
	( >&2 echo "ERROR: Wrong number of arguments in $(basename $0).
Usage: $(basename $0) PATH TMPFILE LEVEL" )
	exit 1
fi

dprefix='📂 '
dprefix='🗁  '
fprefix='🔹'
fprefix='📝 '
fprefix='- '

path="$1"
tmpfile="$2"
leveloffset="$3"
# notify-send "path: $path"

files=()
mapfile -d $'\0' files < <(find "$path" -maxdepth 1 -mindepth 1 -type f -not -name '.*' -print0)

directories=()
mapfile -d $'\0' directories < <(find "$path" -maxdepth 1 -mindepth 1 -type d -not -name '.*' -print0)

readarray -t filesSorted < <(for a in "${files[@]}"; do echo "$a"; done | sort)
readarray -t directoriesSorted < <(for a in "${directories[@]}"; do echo "$a"; done | sort)

# count the number of parent directories
level=$( echo $path | tr '/' '\n' | wc -l)
level=$( expr $level - 1 )

# initialise offset of padding
if [[ $leveloffset -eq -1 ]]; then
	echo $leveloffset
	leveloffset=$level
	echo $leveloffset
fi

# calculate current level
level=$((level - leveloffset))

# calculate padding
padding=""
for(( c=0; c<level; c++ )); do
	padding="$padding  "
done

# echo path
# TODO collect tags of path
echo "$padding$dprefix$path/" >> $tmpfile
	
for f in "${filesSorted[@]}"; do
	
	# parse and nicen tags
	tags=""
	if [[ $(tmsu tags -c --name never "$f") -ne 0 ]];then
		tags="$tags$(tmsu tags --name never -1 "$f" )"
		tags="<"$(echo "$tags" | sed -e 's/\\ / /g' | sed -e ':a;N;$!ba;s/\n/> </g')">"
	else
		tags=""
	fi
	
	# echo files with tags
	echo "$padding  $fprefix/"$(basename "$f")"/ $tags" >> $tmpfile
done

# recurse
for d in "${directoriesSorted[@]}"; do
	$0 "$path/$(basename "$d")" "$tmpfile" "$leveloffset"
done

exit 0
