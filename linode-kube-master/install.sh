#!/usr/bin/env bash

set -e
set -x

# Enforce running as root
if [ "$EUID" != 0 ]; then
  sudo "$0" "$@"
  exit $?
fi

echo "experimental-features = nix-command flakes" > ~/.config/nix/nix.conf

echo "Asking for user password (one time)"
mkpasswd -m sha-512 > /mnt/etc/mbund-passwd

echo "Asking for Linode Longview API key"
read LONGVIEW_API_KEY
echo $LONGVIEW_API_KEY > /mnt/var/lib/longview-secrets/longview.key

nixos-install --no-root-password --flake "/mnt/etc/nixos#linode-kube-master"