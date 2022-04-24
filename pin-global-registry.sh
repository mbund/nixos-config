unpinned=${1-/etc/nixos/global-flake-registry-unpinned.json}
pinned=${2-/etc/nixos/global-flake-registry.json}

if [ ! -f "$unpinned" ]; then
  echo "unpinned registry at ${unpinned} must exist"
  exit 1
fi

if ! jq empty "$unpinned"; then
  echo "unpinned registry at ${unpinned} must be valid json"
  exit 1
fi

cp "$unpinned" "$pinned"

for row in $(jq -c '.flakes[].from' "$unpinned"); do
  type=$(echo "$row" | jq -r '.type')
  id=$(echo "$row" | jq -r '.id')

  if [ "$type" == 'indirect' ]; then
    nix registry pin "$id" --registry "$pinned"
  else
    echo "input \"${id}\" must be \"indirect\" but was \"${type}\""
  fi
done
