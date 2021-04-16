#!/bin/bash

## Example deployment script for Mainnet

[[ "$ETH_RPC_URL" && "$(seth chain)" == "ethlive"  ]] || { echo "Please set a mainnet ETH_RPC_URL"; exit 1;  }

CWD=$(pwd)
PARENT_PATH=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )

cd "$PARENT_PATH"/..

make

export ETH_GAS=6000000

#                                   Vat                                        Dog                                        Cat                                        Spot
REGISTRY="$(dapp create IlkRegistry 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B 0x135954d155898D42C90D2a57824C690e0c7BEf1B 0xa5679C04fc3d9d8b0AaB1F0ab83555b301cA70Ea 0x65C79fcB50Ca1594B025960e539eD7A9a6D434A3)"
echo "Registry: ${REGISTRY}"

export ETH_GAS=3000000

# ETH-A
seth send $REGISTRY "add(address)" "0x2F0b23f53734252Bda2277357e97e1517d6B042A"
# ETH-B
seth send $REGISTRY "add(address)" "0x08638eF1A205bE6762A8b935F5da9b700Cf7322c"
# ETH-C
seth send $REGISTRY "add(address)" "0xF04a5cC80B1E94C69B48f5ee68a08CD2F09A7c3E"
# BAT-A
seth send $REGISTRY "add(address)" "0x3D0B1912B66114d4096F48A8CEe3A56C231772cA"
# USDC-A
seth send $REGISTRY "add(address)" "0xA191e578a6736167326d05c119CE0c90849E84B7"
# USDC-B
seth send $REGISTRY "add(address)" "0x2600004fd1585f7270756DDc88aD9cfA10dD0428"
# WBTC-A
seth send $REGISTRY "add(address)" "0xBF72Da2Bd84c5170618Fbe5914B0ECA9638d5eb5"
# TUSD-A
seth send $REGISTRY "add(address)" "0x4454aF7C8bb9463203b66C816220D41ED7837f44"
# ZRX-A
seth send $REGISTRY "add(address)" "0xc7e8Cd72BDEe38865b4F5615956eF47ce1a7e5D0"
# KNC-A
seth send $REGISTRY "add(address)" "0x475F1a89C1ED844A08E8f6C50A00228b5E59E4A9"
# MANA-A
seth send $REGISTRY "add(address)" "0xA6EA3b9C04b8a38Ff5e224E7c3D6937ca44C0ef9"
# USDT-A
seth send $REGISTRY "add(address)" "0x0Ac6A1D74E84C2dF9063bDDc31699FF2a2BB22A2"
# PAXUSD-A
seth send $REGISTRY "add(address)" "0x7e62B7E279DFC78DEB656E34D6a435cC08a44666"
# COMP-A
seth send $REGISTRY "add(address)" "0xBEa7cDfB4b49EC154Ae1c0D731E4DC773A3265aA"
# LRC-A
seth send $REGISTRY "add(address)" "0x6C186404A7A238D3d6027C0299D1822c1cf5d8f1"
# LINK-A
seth send $REGISTRY "add(address)" "0xdFccAf8fDbD2F4805C174f856a317765B49E4a50"
# BAL-A
seth send $REGISTRY "add(address)" "0x4a03Aa7fb3973d8f0221B466EefB53D0aC195f55"
# YFI-A
seth send $REGISTRY "add(address)" "0x3ff33d9162aD47660083D7DC4bC02Fb231c81677"
# GUSD-A
seth send $REGISTRY "add(address)" "0xe29A14bcDeA40d83675aa43B72dF07f649738C8b"
# UNI-A
seth send $REGISTRY "add(address)" "0x3BC3A58b4FC1CbE7e98bB4aB7c99535e8bA9b8F1"
# RENBTC-A
seth send $REGISTRY "add(address)" "0xFD5608515A47C37afbA68960c1916b79af9491D0"
# AAVE-A
seth send $REGISTRY "add(address)" "0x24e459F61cEAa7b1cE70Dbaea938940A7c5aD46e"
# UNIV2DAIETH-A
seth send $REGISTRY "add(address)" "0x2502F65D77cA13f183850b5f9272270454094A08"
# UNIV2WBTCETH-A
seth send $REGISTRY "add(address)" "0xDc26C9b7a8fe4F5dF648E314eC3E6Dc3694e6Dd2"
# UNIV2USDCETH-A
seth send $REGISTRY "add(address)" "0x03Ae53B33FeeAc1222C3f372f32D37Ba95f0F099"
# UNIV2DAIUSDC-A
seth send $REGISTRY "add(address)" "0xA81598667AC561986b70ae11bBE2dd5348ed4327"
# UNIV2ETHUSDT-A
seth send $REGISTRY "add(address)" "0x4aAD139a88D2dd5e7410b408593208523a3a891d"
# UNIV2LINKETH-A
seth send $REGISTRY "add(address)" "0xDae88bDe1FB38cF39B6A02b595930A3449e593A6"
# UNIV2UNIETH-A
seth send $REGISTRY "add(address)" "0xf11a98339FE1CdE648e8D1463310CE3ccC3d7cC1"
# UNIV2WBTCDAI-A
seth send $REGISTRY "add(address)" "0xD40798267795Cbf3aeEA8E9F8DCbdBA9b5281fcC"
# UNIV2AAVEETH-A
seth send $REGISTRY "add(address)" "0x42AFd448Df7d96291551f1eFE1A590101afB1DfF"
# UNIV2DAIUSDT-A
seth send $REGISTRY "add(address)" "0xAf034D882169328CAf43b823a4083dABC7EEE0F4"
# PSM-USDC-A
seth send $REGISTRY "add(address)" "0x0A59649758aa4d66E25f08Dd01271e891fe52199"



# put(bytes32 _ilk, address _join, address _gem, uint256 _dec, uint256 _class, address _pip, address _xlip, string calldata _name, string calldata _symbol)

seth send $REGISTRY "put(bytes32,address,address,uint256,uint256,address,address,string,string)" \
  $(seth --to-bytes32 "$(seth --from-ascii "RWA001-A")") \
  "0x476b81c12Dc71EDfad1F64B9E07CaA60F4b156E2" \
  "0x10b2aa5d77aa6484886d8e244f0686ab319a270d" \
  "18" \
  "3" \
  "0x76A9f30B45F4ebFD60Ce8a1c6e963b1605f7cB6d" \
  "0x0" \
  '"RWA001-A: 6s Capital"' \
  '"RWA001-A"'

seth send $REGISTRY "put(bytes32,address,address,uint256,uint256,address,address,string,string)" \
  $(seth --to-bytes32 "$(seth --from-ascii "RWA002-A")") \
  "0xe72C7e90bc26c11d45dBeE736F0acf57fC5B7152" \
  "0xAAA760c2027817169D7C8DB0DC61A2fb4c19AC23" \
  "18" \
  "3" \
  "0xd2473237e20bd52f8e7ce0fd79403a6a82fbaec8" \
  "0x0" \
  '"RWA002-A: Centrifuge: New Silver"' \
  '"RWA002-A"'


# RELY pauseProxy
seth send $REGISTRY "rely(address)" "0xBE8E3e3618f7474F8cB1d074A26afFef007E98FB"
# DENY self
seth send $REGISTRY "deny(address)" $ETH_FROM

# return to starting dir
cd "$CWD"
