#!/usr/bin/env bash
### ilks2ascii -- list ilks from the IlkRegistry in ascii
### Usage: ./ilks2ascii.sh

set -e

[[ "$ETH_RPC_URL" ]] || { echo "Please set a ETH_RPC_URL"; exit 1; }

CHANGELOG=0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F

ILK_REGISTRY=$(seth call "$CHANGELOG" 'getAddress(bytes32)(address)' "$(seth --to-bytes32 "$(seth --from-ascii "ILK_REGISTRY")")")

LIST=$(seth call "$ILK_REGISTRY" 'list()(bytes32[])')

echo -e "Network: $(seth chain)"
for ilk in $(echo -e "$LIST" | sed "s/,/ /g")
do
    seth --to-ascii "$ilk"
done
