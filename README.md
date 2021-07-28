# Ilk Registry

A publicly-modifiable registry of `ilk`'s in the Dai Stablecoin System.

## Public addresses

Kovan: [0xc3F42deABc0C506e8Ae9356F2d4fc1505196DCDB](https://kovan.etherscan.io/address/0xc3F42deABc0C506e8Ae9356F2d4fc1505196DCDB)

Mainnet: [0x5a464C28D19848f44199D003BeF5ecc87d090F87](https://etherscan.io/address/0x5a464C28D19848f44199D003BeF5ecc87d090F87)

## Requirements

* [Dapptools](https://github.com/dapphub/dapptools)

## About

Provides an on-chain list of `ilk` types in the DSS system.

Useful for external contracts or web frontends which need to iterate over the on-chain ilk types and/or access information about a particular ilk.

* Modify the registry

    * `add(address joinAdapter)`: Add a new ilk to the registry by passing the Join Adapter address. The adapter must be live on mainnet and can not already be included in the registry.
    * `remove(bytes32 ilk)`: Remove an ilk from the registry if it's adapter has been caged.
    * `update(bytes32 ilk)`: Update the `flip` and `pip` contracts in storage for a given `ilk`.

* Get information from the registry

    * `list()`: return a `bytes32[]` of available ilk types.
    * `list(uint256 start, uint256 end)`: returns a `bytes32[]` of a portion of the complete list.
    * `get(uint256 pos)`: get the `bytes32` ilk type from an indexed position in the array.
    * `info(bytes32 ilk)`: return information about an ilk
        * `name`: token name (`string`)
        * `symbol`: token symbol (`string`)
        * `dec`: token decimals (`uint256`)
        * `gem`: token address
        * `pip`: price feed
        * `join`: token join adapter
        * `flip`: ilk flipper
    * `count()`: return number of ilks as `uint256`
    * `pos(bytes32 ilk)`: the location in the `ilks` array for this `ilk`
    * `gem(bytes32 ilk)`: the `address` of the ilk's token contract
    * `pip(bytes32 ilk)`: the `address` of the ilk's pip contract
    * `join(bytes32 ilk)`: the `address` of the ilk's join adapter
    * `flip(bytes32 ilk)`: the `address` of the ilk's flipper contract
    * `dec(bytes32 ilk)`: the number of decimals for an `ilk` as `uint256`
    * `name(bytes32 ilk)`: the name of the token (if available) as `string`
    * `symbol(bytes32 ilk)`: the token symbol (if available) as `string`

* `auth` functions (available to MakerDAO governance)

    * `file(bytes32 what, address)`: Update core contract values
    * `file(bytes32 ilk, bytes32 what, address)`: Update ilk data values
    * `file(bytes32 ilk, bytes32 what, uint256)`: Update ilk data values
    * `file(bytes32 ilk, bytes32 what, string calldata)`: Update ilk data values
    * `rely(address)` and `deny(address)`: configure `auth` users
    * `removeAuth(bytes32 ilk)`: remove an uncaged ilk adapter


## Testing

```
$ dapp update
$ make test
```
