all    :; dapp build
clean  :; dapp clean
test   :; dapp test --match "_dss" -v
deploy :; dapp create IlkRegistry
