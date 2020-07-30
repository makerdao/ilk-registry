pragma solidity ^0.6.7;

import "ds-test/test.sol";

import "./IlkRegistry.sol";

interface Hevm {
    function warp(uint256) external;
}

interface JoinCageLike {
    function cage() external;
}

interface DSPauseAbstract {
    function delay() external view returns (uint256);
    function plot(address, bytes32, bytes calldata, uint256) external;
    function exec(address, bytes32, bytes calldata, uint256) external returns (bytes memory);
}

interface DSChiefAbstract {
    function hat() external view returns (address);
    function lock(uint256) external;
    function vote(address[] calldata) external returns (bytes32);
    function lift(address) external;
}

interface DSTokenAbstract {
    function approve(address, uint256) external returns (bool);
    function balanceOf(address) external view returns (uint256);
}

contract CageSpellAction {
    function execute() public {
        address BAT_JOIN = 0x3D0B1912B66114d4096F48A8CEe3A56C231772cA;
        JoinCageLike joinCage = JoinCageLike(BAT_JOIN);
        // cage it
        joinCage.cage();
    }
}

contract Spell {
    DSPauseAbstract public pause =
        DSPauseAbstract(0xbE286431454714F511008713973d3B053A2d38f3);
    address   public action;
    bytes32   public tag;
    uint256   public eta;
    bytes     public sig;
    bool      public done;

    constructor() public {
        sig = abi.encodeWithSignature("execute()");
        action = address(new CageSpellAction());
        bytes32 _tag;
        address _action = action;
        assembly { _tag := extcodehash(_action) }
        tag = _tag;
    }

    function schedule() public {
        require(eta == 0, "spell-already-scheduled");
        eta = now + DSPauseAbstract(pause).delay();
        pause.plot(action, tag, sig, eta);
    }

    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        pause.exec(action, tag, sig, eta);
    }
}

contract IlkRegistryTest is DSTest {

    address constant TEST_ADDR   = 0x8EE7D9235e01e6B42345120b5d270bdB763624C7;

    address constant DSS_END     = 0xaB14d3CE3F733CACB76eC2AbE7d2fcb00c99F3d5;

    address constant ETH_JOIN    = 0x2F0b23f53734252Bda2277357e97e1517d6B042A;
    bytes32 constant ETH_A       = bytes32("ETH-A");

    bytes32 constant BAT_A       = bytes32("BAT-A");
    address constant BAT_GEM     = 0x0D8775F648430679A709E98d2b0Cb6250d2887EF;
    address constant BAT_PIP     = 0xB4eb54AF9Cc7882DF0121d26c5b97E802915ABe6;
    address constant BAT_JOIN    = 0x3D0B1912B66114d4096F48A8CEe3A56C231772cA;
    address constant BAT_FLIP    = 0x5EdF770FC81E7b8C2c89f71F30f211226a4d7495;
    uint256 constant BAT_DEC     = 18;
    string  constant BAT_NAME    = "Basic Attention Token";
    string  constant BAT_SYMBOL  = "BAT";

    bytes32 constant WBTC_A      = bytes32("WBTC-A");
    address constant WBTC_PIP    = 0xf185d0682d50819263941e5f4EacC763CC5C6C42;
    string  constant WBTC_SYMBOL = "WBTC";
    string  constant WBTC_NAME   = "Wrapped BTC";
    address constant WBTC_JOIN   = 0xBF72Da2Bd84c5170618Fbe5914B0ECA9638d5eb5;
    uint256 constant WBTC_DEC    = 8;

    bytes32 constant USDC_A      = bytes32("USDC-A");
    string  constant USDC_SYMBOL = "USDC";
    string  constant USDC_NAME   = "USD//C";
    address constant USDC_GEM    = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant USDC_A_PIP  = 0x77b68899b99b686F415d074278a9a16b336085A0;
    address constant USDC_A_JOIN = 0xA191e578a6736167326d05c119CE0c90849E84B7;
    address constant USDC_A_FLIP = 0x545521e0105C5698f75D6b3C3050CfCC62FB0C12;
    uint256 constant USDC_A_DEC  = 6;

    bytes32 constant USDC_B      = bytes32("USDC-B");
    address constant USDC_B_JOIN = 0x2600004fd1585f7270756DDc88aD9cfA10dD0428;

    bytes32 constant TUSD_A      = bytes32("TUSD-A");
    address constant TUSD_JOIN   = 0x4454aF7C8bb9463203b66C816220D41ED7837f44;

    IlkRegistry public registry;

    Spell public spell;
    DSPauseAbstract pause =
        DSPauseAbstract(0xbE286431454714F511008713973d3B053A2d38f3);
    DSChiefAbstract chief  = DSChiefAbstract(0x9eF05f7F6deB616fd37aC3c959a2dDD25A54E4F5);
    DSTokenAbstract gov    = DSTokenAbstract(0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2);

    Hevm hevm;
    // CHEAT_CODE = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D
    bytes20 constant CHEAT_CODE =
        bytes20(uint160(uint256(keccak256('hevm cheat code'))));

    function setUp() public {
        hevm = Hevm(address(CHEAT_CODE));
        registry = new IlkRegistry(address(DSS_END));
        spell = new Spell();
    }

    function vote() private {
        if (chief.hat() != address(spell)) {
            gov.approve(address(chief), uint256(-1));
            chief.lock(gov.balanceOf(address(this)) - 1 ether);

            assertTrue(!spell.done());

            address[] memory yays = new address[](1);
            yays[0] = address(spell);

            chief.vote(yays);
            chief.lift(address(spell));
        }
        assertEq(chief.hat(), address(spell));
    }

    function scheduleWaitAndCast() private {
        spell.schedule();
        hevm.warp(now + pause.delay());
        spell.cast();
    }

    function testAddIlk() public {
        assertEq(registry.count(), 0);
        registry.add(ETH_JOIN);
        registry.add(BAT_JOIN);
        assertEq(registry.count(), 2);
    }

    function testIlkData() public {
        registry.add(ETH_JOIN);
        registry.add(BAT_JOIN);
        (uint256 pos, address gem, address pip, address join,
        address flip, uint256 dec, string memory name,
        string memory symbol) = registry.ilkData(BAT_A);
        assertEq(pos, 1); // 0-indexed
        assertEq(gem, BAT_GEM);
        assertEq(pip, BAT_PIP);
        assertEq(join, BAT_JOIN);
        assertEq(flip, BAT_FLIP);
        assertEq(dec, BAT_DEC);
        assertEq(name, BAT_NAME);
        assertEq(symbol, BAT_SYMBOL);
    }

    function testWards() public {
        assertEq(registry.wards(TEST_ADDR), 1);
        assertEq(registry.wards(DSS_END), 0);
    }

    function testIlks() public {
        registry.add(ETH_JOIN);
        registry.add(BAT_JOIN);
        registry.add(WBTC_JOIN);
        registry.add(USDC_A_JOIN);
        registry.add(USDC_B_JOIN);
        bytes32[] memory ilks = registry.list();
        assertEq(ilks.length, 5);
        assertEq(ilks[0], ETH_A);
        assertEq(ilks[1], BAT_A);
        assertEq(ilks[2], WBTC_A);
        assertEq(ilks[3], USDC_A);
        assertEq(ilks[4], USDC_B);
    }

    function testIlksPos() public {
        registry.add(ETH_JOIN);
        registry.add(WBTC_JOIN);
        bytes32 ilk = registry.get(1);
        assertEq(ilk, WBTC_A);
    }

    function testListPartial() public {
        registry.add(ETH_JOIN);
        registry.add(BAT_JOIN);
        registry.add(WBTC_JOIN);
        registry.add(USDC_A_JOIN);
        registry.add(USDC_B_JOIN);
        registry.add(TUSD_JOIN);
        bytes32[] memory ilkSliceA = registry.list(2, 4);
        assertEq(ilkSliceA.length, 3);
        assertEq(ilkSliceA[0], WBTC_A);
        bytes32[] memory ilkSliceB = registry.list(0, 0);
        assertEq(ilkSliceB.length, 1);
        assertEq(ilkSliceB[0], ETH_A);
        bytes32[] memory ilkSliceC = registry.list(0, 5);
        assertEq(ilkSliceC.length, 6);
        assertEq(ilkSliceC[5], TUSD_A);
    }

    function testPos() public {
        registry.add(WBTC_JOIN);
        registry.add(USDC_A_JOIN);
        assertEq(registry.pos(USDC_A), 1);
    }

    function testGem() public {
        registry.add(WBTC_JOIN);
        registry.add(USDC_A_JOIN);
        assertEq(registry.gem(USDC_A), USDC_GEM);
    }

    function testPip() public {
        registry.add(WBTC_JOIN);
        registry.add(USDC_A_JOIN);
        assertEq(registry.pip(USDC_A), USDC_A_PIP);
    }

    function testJoin() public {
        registry.add(WBTC_JOIN);
        registry.add(USDC_A_JOIN);
        assertEq(registry.join(USDC_A), USDC_A_JOIN);
    }

    function testFlip() public {
        registry.add(WBTC_JOIN);
        registry.add(USDC_A_JOIN);
        assertEq(registry.flip(USDC_A), USDC_A_FLIP);
    }

    function testDec() public {
        registry.add(WBTC_JOIN);
        registry.add(USDC_A_JOIN);
        registry.add(ETH_JOIN);
        assertEq(registry.dec(USDC_A), 6);
        assertEq(registry.dec(ETH_A), 18);
    }

    function testFailRemoveLive() public {
        registry.add(WBTC_JOIN);
        registry.add(USDC_A_JOIN);
        registry.remove(WBTC_A);
    }

    function testRemoveCaged() public {
        registry.add(BAT_JOIN);
        registry.add(WBTC_JOIN);
        registry.add(USDC_A_JOIN);

        JoinLike batJoin = JoinLike(BAT_JOIN);

        assertEq(registry.count(), 3);
        assertEq(batJoin.live(), 1);

        // Cage the BAT adapter so we can test removing it
        vote();
        scheduleWaitAndCast();

        assertEq(batJoin.live(), 0);

        registry.remove(BAT_A);
        assertEq(registry.count(), 2);
    }

    function testAuthRemoveLive() public {
        registry.add(BAT_JOIN);
        registry.add(WBTC_JOIN);
        registry.add(USDC_A_JOIN);
        registry.removeAuth(WBTC_A);
        assertEq(registry.count(), 2);
        bytes32[] memory ilks = registry.list();
        assertEq(ilks[0], BAT_A);
        assertEq(ilks[1], USDC_A);
    }

    function testName() public {
        registry.add(WBTC_JOIN);
        assertEq(registry.name(WBTC_A), WBTC_NAME);
    }

    function testSymbol() public {
        registry.add(WBTC_JOIN);
        assertEq(registry.symbol(WBTC_A), WBTC_SYMBOL);
    }

    function testInfo() public {
        registry.add(BAT_JOIN);
        registry.add(WBTC_JOIN);
        registry.add(USDC_A_JOIN);
        (string memory name, string memory symbol, uint256 dec,
        address gem, address pip, address join, address flip) = registry.info(USDC_A);

        assertEq(name, USDC_NAME);
        assertEq(symbol, USDC_SYMBOL);
        assertEq(dec, USDC_A_DEC);
        assertEq(gem, USDC_GEM);
        assertEq(pip, USDC_A_PIP);
        assertEq(join, USDC_A_JOIN);
        assertEq(flip, USDC_A_FLIP);
    }

    function testFileAddress() public {
        registry.add(WBTC_JOIN);
        assertEq(registry.pip(WBTC_A), WBTC_PIP);
        registry.file(WBTC_A, bytes32("gem"), address(USDC_GEM));
        registry.file(WBTC_A, bytes32("pip"), address(USDC_GEM));
        registry.file(WBTC_A, bytes32("join"), address(USDC_GEM));
        registry.file(WBTC_A, bytes32("flip"), address(USDC_GEM));
        assertEq(registry.gem(WBTC_A), USDC_GEM);
        assertEq(registry.pip(WBTC_A), USDC_GEM);
        assertEq(registry.join(WBTC_A), USDC_GEM);
        assertEq(registry.flip(WBTC_A), USDC_GEM);
    }

    function testFailFileAddress() public {
        registry.add(WBTC_JOIN);
        registry.file(WBTC_A, bytes32("test"), address(USDC_GEM));
    }

    function testFileUint256() public {
        registry.add(WBTC_JOIN);
        assertEq(registry.dec(WBTC_A), WBTC_DEC);
        registry.file(WBTC_A, bytes32("dec"), BAT_DEC);
        assertEq(registry.dec(WBTC_A), BAT_DEC);
    }

    function testFailFileUint256() public {
        registry.add(WBTC_JOIN);
        registry.file(WBTC_A, bytes32("test"), BAT_DEC);
    }

    function testFileString() public {
        registry.add(BAT_JOIN);
        // name
        assertEq(registry.name(BAT_A), BAT_NAME);
        registry.file(BAT_A, bytes32("name"), "test");
        assertEq(registry.name(BAT_A), "test");
        // symbol
        assertEq(registry.symbol(BAT_A), BAT_SYMBOL);
        registry.file(BAT_A, bytes32("symbol"), "TES");
        assertEq(registry.symbol(BAT_A), "TES");
    }

    function testFailFileString() public {
        registry.add(BAT_JOIN);
        registry.file(BAT_A, bytes32("test"), BAT_NAME);
    }

    function testReset() public {
        registry.add(BAT_JOIN);
        assertEq(registry.pip(BAT_A), BAT_PIP);
        assertEq(registry.flip(BAT_A), BAT_FLIP);
        registry.reset(BAT_A);
        assertEq(registry.pip(BAT_A), BAT_PIP);
        assertEq(registry.flip(BAT_A), BAT_FLIP);
    }

    function testResetChanged() public {
        registry.add(BAT_JOIN);
        registry.file(BAT_A, bytes32("pip"), USDC_A_PIP);
        registry.file(BAT_A, bytes32("flip"), USDC_A_FLIP);
        assertEq(registry.pip(BAT_A), USDC_A_PIP);
        assertEq(registry.flip(BAT_A), USDC_A_FLIP);
        registry.reset(BAT_A);
        assertEq(registry.pip(BAT_A), BAT_PIP);
        assertEq(registry.flip(BAT_A), BAT_FLIP);
    }
}
