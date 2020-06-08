pragma solidity ^0.6.7;

import "ds-test/test.sol";

import "./IlkRegistry.sol";

abstract contract Hevm {
    function warp(uint256) public virtual;
}

contract IlkRegistryTest is DSTest {

    address constant TEST_ADDR   = 0x8EE7D9235e01e6B42345120b5d270bdB763624C7;

    address constant DSS_END     = 0xaB14d3CE3F733CACB76eC2AbE7d2fcb00c99F3d5;

    address constant ETH_JOIN    = 0x2F0b23f53734252Bda2277357e97e1517d6B042A;
    bytes32 constant ETH_A = bytes32("ETH-A");

    bytes32 constant BAT_A       = bytes32("BAT-A");
    address constant BAT_GEM     = 0x0D8775F648430679A709E98d2b0Cb6250d2887EF;
    address constant BAT_PIP     = 0xB4eb54AF9Cc7882DF0121d26c5b97E802915ABe6;
    address constant BAT_JOIN    = 0x3D0B1912B66114d4096F48A8CEe3A56C231772cA;
    address constant BAT_FLIP    = 0xaA745404d55f88C108A28c86abE7b5A1E7817c07;
    uint256 constant BAT_DEC     = 18;

    bytes32 constant WBTC_A = bytes32("WBTC-A");
    address constant WBTC_JOIN   = 0xBF72Da2Bd84c5170618Fbe5914B0ECA9638d5eb5;

    bytes32 constant USDC_A = bytes32("USDC-A");
    address constant USDC_A_JOIN = 0xA191e578a6736167326d05c119CE0c90849E84B7;

    bytes32 constant USDC_B = bytes32("USDC-B");
    address constant USDC_B_JOIN = 0x2600004fd1585f7270756DDc88aD9cfA10dD0428;

    bytes32 constant TUSD_A = bytes32("TUSD-A");
    address constant TUSD_JOIN   = 0x4454aF7C8bb9463203b66C816220D41ED7837f44;

    IlkRegistry public registry;

    Hevm hevm;
    // CHEAT_CODE = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D
    bytes20 constant CHEAT_CODE =
        bytes20(uint160(uint256(keccak256('hevm cheat code'))));

    function setUp() public {
        hevm = Hevm(address(CHEAT_CODE));
        registry = new IlkRegistry(address(DSS_END));
    }

    function testAddIlk() public {
        assertEq(registry.count(), 0);
        registry.add(ETH_JOIN);
        registry.add(BAT_JOIN);
        assertEq(registry.count(), 2);
        registry.add(WBTC_JOIN);
        assertEq(registry.count(), 3);
    }

    function testIlkData() public {
        registry.add(ETH_JOIN);
        registry.add(BAT_JOIN);
        (uint256 pos, address gem, address pip, address join,
        address flip, uint256 dec) = registry.ilkData(BAT_A);
        assertEq(pos, 1); // 0-indexed
        assertEq(gem, BAT_GEM);
        assertEq(pip, BAT_PIP);
        assertEq(join, BAT_JOIN);
        assertEq(flip, BAT_FLIP);
        assertEq(dec, BAT_DEC);
    }

    function testWards() public {
        assertEq(registry.wards(TEST_ADDR), 1);
        assertEq(registry.wards(DSS_END), 0);
    }

}
