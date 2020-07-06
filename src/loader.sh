#!/bin/bash

# File: loader.sh
# Author: René Michalke <rene@renemichalke.de>
# Description: Loads recursively all files and directories with their TMSU tags into a .vtmsu file.

# Check for correct number of arguments.
if [[ $# -ne 3 ]]; then
	( >&2 echo "ERROR: Wrong number of arguments in $(basename $0).
Usage: $(basename $0) PATH TMPFILE LEVEL" )
	exit 1
fi

# Don't change them, as they are also hardcoded in `plugin/vim-tmsu.vim`.
# Prepend all directories with:
dprefix='🗁  '
# Prepend all files with:
fprefix='- '

# Holds the fullname of the current directory.
path="$1"
# Holds the name of the index-file.
tmpfile="$2"
# Holds the padding-offset.
leveloffset="$3"

# Load the files located in `$path`.
files=()
mapfile -d $'\0' files < <(find -L "$path" -maxdepth 1 -mindepth 1 -type f -not -name '.*' -print0)

# Load the directories located in `$path`.
directories=()
mapfile -d $'\0' directories < <(find -L "$path" -maxdepth 1 -mindepth 1 -type d -not -name '.*' -print0)

# Sort by filename/directoryname.
readarray -t filesSorted < <(for a in "${files[@]}"; do echo "$a"; done | sort)
readarray -t directoriesSorted < <(for a in "${directories[@]}"; do echo "$a"; done | sort)

# Count the number of parent directories.
level=$( echo $path | tr '/' '\n' | wc -l)
level=$( expr $level - 1 )

# Initialise offset of padding.
if [[ $leveloffset -eq -1 ]]; then
	leveloffset=$level
fi

# Calculate current level of recursion.
level=$((level - leveloffset))

# Calculate padding.
padding=""
for(( c=0; c<level; c++ )); do
	padding="$padding  "
done

# Get, parse and nicen tags of directory stored in `$path`.
tags=""
# Are there any tags?
if [[ $(tmsu tags -c --name never "$path") -ne 0 ]];then
	# Yes: Get them.
	tags="$(tmsu tags --name never -1 "$path" )"
	# Wrap each tag like this: `<TAG>`. Replace newlines with spaces.
	tags="<"$(echo "$tags" | sed -e 's/\\ / /g' | sed -e ':a;N;$!ba;s/\n/> </g')">"
else
	tags=""
fi

# Append results to the file.
echo "$padding$dprefix$path/ $tags" >> $tmpfile
	
for f in "${filesSorted[@]}"; do
	
	# Get, parse and nicen tags of file stored in `$f`.
	tags=""
	# Are there any tags?
	if [[ $(tmsu tags -c --name never "$f") -ne 0 ]];then
		# Yes: Get them.
		tags="$(tmsu tags --name never -1 "$f" )"
		# Wrap each tag like this: `<TAG>`. Replace newlines with spaces.
		tags="<"$(echo "$tags" | sed -e 's/\\ / /g' | sed -e ':a;N;$!ba;s/\n/> </g')">"
	else
		tags=""
	fi
	
	# Append results to the file.
	echo "$padding  $fprefix/"$(basename "$f")"/ $tags" >> $tmpfile
done

# Recurse.
for d in "${directoriesSorted[@]}"; do
	$0 "$path/$(basename "$d")" "$tmpfile" "$leveloffset"
done

exit 0
