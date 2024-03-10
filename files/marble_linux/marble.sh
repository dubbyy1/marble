#!/bin/sh
echo -ne '\033c\033]0;marble\a'
base_path="$(dirname "$(realpath "$0")")"
"$base_path/marble.x86_64" "$@"
