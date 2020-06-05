pragma solidity ^0.5.15;

import "ds-test/test.sol";

import "./IlkRegistry.sol";

contract IlkRegistryTest is DSTest {
    IlkRegistry registry;

    function setUp() public {
        registry = new IlkRegistry();
    }

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }
}
