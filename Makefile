all    :; SOLC_FLAGS="--optimize --optimize-runs=1000000" dapp --use solc:0.6.7 build
clean  :; dapp clean
test   :; dapp --use solc:0.6.7 build && dapp test -v
deploy-mainnet :; SOLC_FLAGS="--optimize --optimize-runs=1000000" dapp --use solc:0.6.7 create IlkRegistry 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B 0xa5679C04fc3d9d8b0AaB1F0ab83555b301cA70Ea 0x65C79fcB50Ca1594B025960e539eD7A9a6D434A3
deploy-kovan :; SOLC_FLAGS="--optimize --optimize-runs=1000000" dapp --use solc:0.6.7 create IlkRegistry 0xbA987bDB501d131f766fEe8180Da5d81b34b69d9 0xdDb5F7A3A5558b9a6a1f3382BD75E2268d1c6958 0x3a042de6413eDB15F2784f2f97cC68C7E9750b2D
