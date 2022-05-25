#!/usr/bin/env bash

set -e
set -x

# Enforce running as root
if [ "$EUID" != 0 ]; then
  sudo "$0" "$@"
  exit $?
fi

