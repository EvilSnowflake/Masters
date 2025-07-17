#!/bin/sh
echo -ne '\033c\033]0;MultiplicactionTeachingSystem\a'
base_path="$(dirname "$(realpath "$0")")"
"$base_path/MultiplicationSystem.x86_64" "$@"
