#!/bin/sh
echo -ne '\033c\033]0;Project_MultiplicationTable\a'
base_path="$(dirname "$(realpath "$0")")"
"$base_path/Project_MultiplicationTable.x86_64" "$@"
