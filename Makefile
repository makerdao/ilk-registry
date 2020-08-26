all    :; SOLC_FLAGS="--optimize --optimize-runs=1000000" dapp --use solc:0.6.7 build
clean  :; dapp clean
test   :; ./test-ilk-registry.sh
test-dss   :; dapp --use solc:0.6.7 build && dapp test --match "_dss" -v
deploy-mainnet :; SOLC_FLAGS="--optimize --optimize-runs=1000000" dapp --use solc:0.6.7 create IlkRegistry 0xaB14d3CE3F733CACB76eC2AbE7d2fcb00c99F3d5
deploy-kovan :; SOLC_FLAGS="--optimize --optimize-runs=1000000" dapp --use solc:0.6.7 create IlkRegistry 0x24728AcF2E2C403F5d2db4Df6834B8998e56aA5F
