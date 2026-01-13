#!/usr/bin/env bash

RED=$(tput setaf 1)
NORMAL=$(tput sgr0)

PLUGIN_DIR="$(dirname -- "$( readlink -f -- "$0"; )")"
for pastebuf in "${PLUGIN_DIR}/../pastebufs/$1/b"*; do
  echo "${RED}${pastebuf##*/}${NORMAL}: $(head -n1 "$pastebuf")"
done
