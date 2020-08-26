all    :; dapp build
clean  :; dapp clean
test-dss   :; dapp --use solc:0.6.7 build && dapp test --match "_dss" -v
deploy :; dapp create IlkRegistry
