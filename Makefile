all    :; DAPP_BUILD_OPTIMIZE=1 DAPP_BUILD_OPTIMIZE_RUNS=1000000 dapp --use solc:0.6.12 build
clean  :; dapp clean
test   :; DAPP_BUILD_OPTIMIZE=1 DAPP_BUILD_OPTIMIZE_RUNS=1000000 dapp --use solc:0.6.12 test -v
deploy-mainnet :; make && dapp create IlkRegistry 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B TODO:DOG 0xa5679C04fc3d9d8b0AaB1F0ab83555b301cA70Ea 0x65C79fcB50Ca1594B025960e539eD7A9a6D434A3
deploy-kovan :; ./scripts/deploy-kovan.sh
