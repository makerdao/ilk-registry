#!/bin/bash

## Example deployment script for Kovan

[[ "$ETH_RPC_URL" && "$(seth chain)" == "kovan"  ]] || { echo "Please set a kovan ETH_RPC_URL"; exit 1;  }

CWD=$(pwd)
PARENT_PATH=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )

cd "$PARENT_PATH"/..

make

export ETH_GAS=6000000

#                                   Vat                                        Dog                                        Cat                                        Spot
REGISTRY="$(dapp create IlkRegistry 0xbA987bDB501d131f766fEe8180Da5d81b34b69d9 0x121D0953683F74e9a338D40d9b4659C0EBb539a0 0xdDb5F7A3A5558b9a6a1f3382BD75E2268d1c6958 0x3a042de6413eDB15F2784f2f97cC68C7E9750b2D)"
echo "Registry: ${REGISTRY}"

export ETH_GAS=3000000

# ETH-A
seth send $REGISTRY "add(address)" "0x775787933e92b709f2a3C70aa87999696e74A9F8"
# ETH-B
seth send $REGISTRY "add(address)" "0xd19A770F00F89e6Dd1F12E6D6E6839b95C084D85"
# ETH-C
seth send $REGISTRY "add(address)" "0xD166b57355BaCE25e5dEa5995009E68584f60767"
# BAT-A
seth send $REGISTRY "add(address)" "0x2a4C485B1B8dFb46acCfbeCaF75b6188A59dBd0a"
# USDC-A
seth send $REGISTRY "add(address)" "0x4c514656E7dB7B859E994322D2b511d99105C1Eb"
# USDC-B
seth send $REGISTRY "add(address)" "0xaca10483e7248453BB6C5afc3e403e8b7EeDF314"
# WBTC-A
seth send $REGISTRY "add(address)" "0xB879c7d51439F8e7AC6b2f82583746A0d336e63F"
# TUSD-A
seth send $REGISTRY "add(address)" "0xe53f6755A031708c87d80f5B1B43c43892551c17"
# ZRX-A
seth send $REGISTRY "add(address)" "0x85D38fF6a6FCf98bD034FB5F9D72cF15e38543f2"
# KNC-A
seth send $REGISTRY "add(address)" "0xE42427325A0e4c8e194692FfbcACD92C2C381598"
# MANA-A
seth send $REGISTRY "add(address)" "0xdC9Fe394B27525e0D9C827EE356303b49F607aaF"
# USDT-A
seth send $REGISTRY "add(address)" "0x9B011a74a690dFd9a1e4996168d3EcBDE73c2226"
# PAXUSD-A
seth send $REGISTRY "add(address)" "0x3d6a14C9542B429a4e3d255F6687754d4898D897"
# COMP-A
seth send $REGISTRY "add(address)" "0x16D567c1F6824ffFC460A11d48F61E010ae43766"
# LRC-A
seth send $REGISTRY "add(address)" "0x436286788C5dB198d632F14A20890b0C4D236800"
# LINK-A
seth send $REGISTRY "add(address)" "0xF4Df626aE4fb446e2Dcce461338dEA54d2b9e09b"
# BAL-A
seth send $REGISTRY "add(address)" "0x8De5EA9251E0576e3726c8766C56E27fAb2B6597"
# YFI-A
seth send $REGISTRY "add(address)" "0x5b683137481F2FE683E2f2385792B1DeB018050F"
# GUSD-A
seth send $REGISTRY "add(address)" "0x0c6B26e6AB583D2e4528034037F74842ea988909"
# UNI-A
seth send $REGISTRY "add(address)" "0xb6E6EE050B4a74C8cc1DfdE62cAC8C6d9D8F4CAa"
# RENBTC-A
seth send $REGISTRY "add(address)" "0x12F1F6c7E5fDF1B671CebFBDE974341847d0Caa4"
# AAVE-A
seth send $REGISTRY "add(address)" "0x9f1Ed3219035e6bDb19E0D95d316c7c39ad302EC"
# UNIV2DAIETH-A
seth send $REGISTRY "add(address)" "0x03f18d97D25c13FecB15aBee143276D3bD2742De"
# PAXG-A
seth send $REGISTRY "add(address)" "0x822248F31bd899DE327A760a78B6C84889aF180D"
# PSM-USDC-A
seth send $REGISTRY "add(address)" "0x4BA159Ad37FD80D235b4a948A8682747c74fDc0E"


# put(bytes32 _ilk, address _join, address _gem, uint256 _dec, uint256 _class, address _pip, address _xlip, string calldata _name, string calldata _symbol)

seth send $REGISTRY "put(bytes32,address,address,uint256,uint256,address,address,string,string)" \
  $(seth --to-bytes32 "$(seth --from-ascii "RWA001-A")") \
  "0x029A554f252373e146f76Fa1a7455f73aBF4d38e" \
  "0x8F9A8cbBdfb93b72d646c8DEd6B4Fe4D86B315cB" \
  "18" \
  "3" \
  "0x09710C9440e5FF5c473efe61d5a2f14cA05A6752" \
  "0x0" \
  '"RWA001-A: 6s Capital"' \
  '"RWA001-A"'

seth send $REGISTRY "put(bytes32,address,address,uint256,uint256,address,address,string,string)" \
  $(seth --to-bytes32 "$(seth --from-ascii "NS2DRP-A")") \
  "0x4B8C10da2B70dE45f7Ea106A961F2Fb79f5bC2bE" \
  "0x1C3765c94aF9b7eB3fdEC69Eddb7Ddf27f2BcFf4" \
  "18" \
  "3" \
  "0x82a561D6f5013766203776a26123ce5B9389109b" \
  "0x0" \
  '"NS2DRP-A: Centrifuge: New Silver"' \
  '"NS2DRP-A"'

# RELY pauseProxy
seth send $REGISTRY "rely(address)" "0x0e4725db88Bb038bBa4C4723e91Ba183BE11eDf3"
# DENY self
seth send $REGISTRY "deny(address)" $ETH_FROM

# return to starting dir
cd "$CWD"
