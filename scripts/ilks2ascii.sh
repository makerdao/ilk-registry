#!/bin/bash
### ilks2ascii -- list ilks from ilks registry in ascii
### Usage: ./ilks2ascii <ilk-registry-address>

ILKS=$(seth call "$1" "list()(bytes32[])")

for ilk in $(echo "$ILKS" | sed "s/,/ /g")
do
	seth --to-ascii "$ilk"

done
