pragma solidity ^0.6.7;

import "ds-test/test.sol";
import "ds-token/token.sol";
import "ds-value/value.sol";

import {Vat}     from 'dss/vat.sol';
import {End}     from 'dss/end.sol';
import {Vow}     from 'dss/vow.sol';
import {Cat}     from 'dss/cat.sol';
import {Spotter} from 'dss/spot.sol';
import {PipLike} from 'dss/spot.sol';
import {Flipper} from 'dss/flip.sol';
import {Flapper} from 'dss/flap.sol';
import {Flopper} from 'dss/flop.sol';
import {GemJoin} from 'dss/join.sol';

import "./IlkRegistry.sol";

interface Hevm {
    function warp(uint256) external;
    function store(address,bytes32,bytes32) external;
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

interface CatAbstract {
    function file(bytes32, bytes32, address) external;
}

interface SpotAbstract {
    function file(bytes32, bytes32, address) external;
}

contract DssIlkRegistryTest is DSTest {
    Hevm hevm;

    Vat vat;
    End end;
    Vow vow;
    Cat cat;
    Spotter spot;

    IlkRegistry public registry;

    struct Ilk {
        bytes32 ilk;
        address pip;
        address gem;
        address join;
        address flip;
        uint256 dec;
        string  name;
        string  symbol;
    }

    struct NonStandardIlk {
        bytes32 ilk;
        address pip;
        address gem;
        address join;
        address flip;
        uint256 dec;
        bytes32 name;
        bytes32 symbol;
    }

    struct IncompleteIlk {
        bytes32 ilk;
        address pip;
        address gem;
        address join;
        address flip;
        uint256 dec;
    }

    mapping (bytes32 => Ilk) ilks;
    NonStandardIlk nsIlk;
    IncompleteIlk iIlk;

    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;

    function ray(uint wad) internal pure returns (uint) {
        return wad * 10 ** 9;
    }
    function rad(uint wad) internal pure returns (uint) {
        return wad * RAY;
    }

    function bytes32ToStr(bytes32 _bytes32) internal pure returns (string memory) {
        bytes memory bytesArray = new bytes(32);
        for (uint256 i; i < 32; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }

    function initCollateral(bytes32 name) internal returns (Ilk memory) {
        DSToken coin = new DSToken(name);
        coin.setName(name);
        coin.mint(20 ether);

        vat.init(name);
        GemJoin join = new GemJoin(address(vat), name, address(coin));
        vat.rely(address(join));

        DSValue pip = new DSValue();
        spot.file(name, "pip", address(pip));

        Flipper flip = new Flipper(address(vat), name);
        vat.hope(address(flip));
        flip.rely(address(cat));
        cat.file(name, "flip", address(flip));

        ilks[name].ilk    = name;
        ilks[name].pip    = address(pip);
        ilks[name].gem    = address(coin);
        ilks[name].join   = address(join);
        ilks[name].flip   = address(flip);
        ilks[name].dec    = join.dec();
        ilks[name].name   = bytes32ToStr(name);
        ilks[name].symbol = bytes32ToStr(name);
    }

    function initNonStandardCollateral(bytes32 name) internal returns (NonStandardIlk memory) {
        DSToken coin = new DSToken(name);
        coin.setName(name);
        coin.mint(20 ether);

        vat.init(name);
        GemJoin join = new GemJoin(address(vat), name, address(coin));
        vat.rely(address(join));

        DSValue pip = new DSValue();
        spot.file(name, "pip", address(pip));

        Flipper flip = new Flipper(address(vat), name);
        vat.hope(address(flip));
        flip.rely(address(cat));
        cat.file(name, "flip", address(flip));

        nsIlk.ilk    = name;
        nsIlk.pip    = address(pip);
        nsIlk.gem    = address(coin);
        nsIlk.join   = address(join);
        nsIlk.flip   = address(flip);
        nsIlk.dec    = join.dec();
        nsIlk.name   = name;
        nsIlk.symbol = name;
    }

    function initNonStandardCollateral(bytes32 name) internal returns (IncompleteIlk memory) {
        DSToken coin = new DSToken(name);
        coin.setName(name);
        coin.mint(20 ether);

        vat.init(name);
        GemJoin join = new GemJoin(address(vat), name, address(coin));
        vat.rely(address(join));

        DSValue pip = new DSValue();
        spot.file(name, "pip", address(pip));

        Flipper flip = new Flipper(address(vat), name);
        vat.hope(address(flip));
        flip.rely(address(cat));
        cat.file(name, "flip", address(flip));

        nsIlk.ilk    = name;
        nsIlk.pip    = address(pip);
        nsIlk.gem    = address(coin);
        nsIlk.join   = address(join);
        nsIlk.flip   = address(flip);
        nsIlk.dec    = join.dec();
    }

    function setUp() public {
        vat  = new Vat();
        cat  = new Cat(address(vat));
        spot = new Spotter(address(vat));

        vat.rely(address(cat));
        vat.rely(address(spot));

        end = new End();
        end.file("vat",  address(vat));
        end.file("cat",  address(cat));
        end.file("spot", address(spot));

        initCollateral("ETH-A");
        initCollateral("BAT-A");
        initCollateral("WBTC-A");
        initCollateral("USDC-A");
        initCollateral("USDC-B");

        registry = new IlkRegistry(address(end));
    }

    function testAddIlk_dss() public {
        assertEq(registry.count(), 0);
        registry.add(ilks["ETH-A"].join);
        registry.add(ilks["BAT-A"].join);
        assertEq(registry.count(), 2);
    }

    function testIlkData_dss() public {
        registry.add(ilks["ETH-A"].join);
        registry.add(ilks["BAT-A"].join);
        (uint256 pos, address gem, address pip, address join,
        address flip, uint256 dec, string memory name,
        string memory symbol) = registry.ilkData(ilks["BAT-A"].ilk);
        assertEq(pos, 1); // 0-indexed
        assertEq(gem,    ilks["BAT-A"].gem);
        assertEq(pip,    ilks["BAT-A"].pip);
        assertEq(join,   ilks["BAT-A"].join);
        assertEq(flip,   ilks["BAT-A"].flip);
        assertEq(dec,    ilks["BAT-A"].dec);
        assertEq(name,   ilks["BAT-A"].name);
        assertEq(symbol, ilks["BAT-A"].symbol);
    }

    function testWards_dss() public {
        assertEq(registry.wards(address(this)), 1);
        assertEq(registry.wards(address(end)), 0);
    }

    function testIlks_dss() public {
        registry.add(ilks["ETH-A"].join);
        registry.add(ilks["BAT-A"].join);
        registry.add(ilks["WBTC-A"].join);
        registry.add(ilks["USDC-A"].join);
        registry.add(ilks["USDC-B"].join);
        bytes32[] memory regIlks = registry.list();
        assertEq(regIlks.length, 5);
        assertEq(regIlks[0], ilks["ETH-A"].ilk);
        assertEq(regIlks[1], ilks["BAT-A"].ilk);
        assertEq(regIlks[2], ilks["WBTC-A"].ilk);
        assertEq(regIlks[3], ilks["USDC-A"].ilk);
        assertEq(regIlks[4], ilks["USDC-B"].ilk);
    }

    function testIlksPos_dss() public {
        registry.add(ilks["ETH-A"].join);
        registry.add(ilks["WBTC-A"].join);
        bytes32 ilk = registry.get(1);
        assertEq(ilk, ilks["WBTC-A"].ilk);
    }

    function testListPartial_dss() public {
        registry.add(ilks["ETH-A"].join);
        registry.add(ilks["BAT-A"].join);
        registry.add(ilks["WBTC-A"].join);
        registry.add(ilks["USDC-A"].join);
        registry.add(ilks["USDC-B"].join);

        bytes32[] memory ilkSliceA = registry.list(1, 3);
        assertEq(ilkSliceA.length, 3);
        assertEq(ilkSliceA[0], ilks["BAT-A"].ilk);
        assertEq(ilkSliceA[1], ilks["WBTC-A"].ilk);
        assertEq(ilkSliceA[2], ilks["USDC-A"].ilk);

        bytes32[] memory ilkSliceB = registry.list(0, 0);
        assertEq(ilkSliceB.length, 1);
        assertEq(ilkSliceB[0], ilks["ETH-A"].ilk);

        bytes32[] memory ilkSliceC = registry.list(4, 4);
        assertEq(ilkSliceC.length, 1);
        assertEq(ilkSliceC[0], ilks["USDC-B"].ilk);
    }

    function testPos_dss() public {
        registry.add(ilks["WBTC-A"].join);
        registry.add(ilks["USDC-A"].join);
        assertEq(registry.pos(ilks["USDC-A"].ilk), 1);
    }

    function testGem_dss() public {
        registry.add(ilks["WBTC-A"].join);
        registry.add(ilks["USDC-A"].join);
        assertEq(registry.gem(ilks["USDC-A"].ilk), ilks["USDC-A"].gem);
    }

    function testPip_dss() public {
        registry.add(ilks["WBTC-A"].join);
        registry.add(ilks["USDC-A"].join);
        assertEq(registry.pip(ilks["USDC-A"].ilk), ilks["USDC-A"].pip);
    }

    function testJoin_dss() public {
        registry.add(ilks["WBTC-A"].join);
        registry.add(ilks["USDC-A"].join);
        assertEq(registry.join(ilks["USDC-A"].ilk), ilks["USDC-A"].join);
    }

    function testFlip_dss() public {
        registry.add(ilks["WBTC-A"].join);
        registry.add(ilks["USDC-A"].join);
        assertEq(registry.flip(ilks["USDC-A"].ilk), ilks["USDC-A"].flip);
    }

    function testDec_dss() public {
        registry.add(ilks["WBTC-A"].join);
        registry.add(ilks["USDC-A"].join);
        registry.add(ilks["ETH-A"].join);
        assertEq(registry.dec(ilks["USDC-A"].ilk), ilks["USDC-A"].dec);
        assertEq(registry.dec(ilks["ETH-A"].ilk),  ilks["ETH-A"].dec);
    }

    function testFailRemoveLive_dss() public {
        registry.add(ilks["WBTC-A"].join);
        registry.add(ilks["USDC-A"].join);
        registry.remove(ilks["WBTC-A"].ilk);
    }

    function testRemoveCaged_dss() public {
        registry.add(ilks["BAT-A"].join);
        registry.add(ilks["WBTC-A"].join);
        registry.add(ilks["USDC-A"].join);

        GemJoin batJoin = GemJoin(ilks["BAT-A"].join);

        assertEq(registry.count(), 3);
        assertEq(batJoin.live(), 1);

        // Cage the BAT adapter so we can test removing it
        batJoin.cage();

        assertEq(batJoin.live(), 0);

        registry.remove(ilks["BAT-A"].ilk);
        assertEq(registry.count(), 2);
    }

    function testAuthRemoveLive_dss() public {
        registry.add(ilks["BAT-A"].join);
        registry.add(ilks["WBTC-A"].join);
        registry.add(ilks["USDC-A"].join);
        assertEq(registry.count(), 3);

        registry.removeAuth(ilks["WBTC-A"].ilk);

        assertEq(registry.count(), 2);
        bytes32[] memory regIlks = registry.list();
        assertEq(regIlks.length, 2);
        assertEq(regIlks[0], ilks["BAT-A"].ilk);
        assertEq(regIlks[1], ilks["USDC-A"].ilk);
    }

    function testName_dss() public {
        registry.add(ilks["WBTC-A"].join);
        assertEq(registry.name(ilks["WBTC-A"].ilk), ilks["WBTC-A"].name);
    }

    function testSymbol_dss() public {
        registry.add(ilks["WBTC-A"].join);
        assertEq(registry.symbol(ilks["WBTC-A"].ilk), ilks["WBTC-A"].symbol);
    }

    function testInfo_dss() public {
        registry.add(ilks["BAT-A"].join);
        registry.add(ilks["WBTC-A"].join);
        registry.add(ilks["USDC-A"].join);
        (string memory name, string memory symbol, uint256 dec,
        address gem, address pip, address join, address flip) = registry.info(ilks["USDC-A"].ilk);

        assertEq(name,   ilks["USDC-A"].name);
        assertEq(symbol, ilks["USDC-A"].symbol);
        assertEq(dec,    ilks["USDC-A"].dec);
        assertEq(gem,    ilks["USDC-A"].gem);
        assertEq(pip,    ilks["USDC-A"].pip);
        assertEq(join,   ilks["USDC-A"].join);
        assertEq(flip,   ilks["USDC-A"].flip);
    }

    function testUpdate_dss() public {
        registry.add(ilks["BAT-A"].join);
        assertEq(registry.pip("BAT-A"), ilks["BAT-A"].pip);
        assertEq(registry.flip("BAT-A"), ilks["BAT-A"].flip);
        registry.update("BAT-A");
        assertEq(registry.pip("BAT-A"), ilks["BAT-A"].pip);
        assertEq(registry.flip("BAT-A"), ilks["BAT-A"].flip);
    }

    function testUpdateChanged_dss() public {
        registry.add(ilks["USDC-A"].join);
        assertEq(registry.pip("USDC-A"), ilks["USDC-A"].pip);
        assertEq(registry.flip("USDC-A"), ilks["USDC-A"].flip);

        // Test spell updates to USDC pip and flip to match BAT
        cat.file("USDC-A", "flip", ilks["BAT-A"].flip);
        spot.file("USDC-A", "pip", ilks["BAT-A"].pip);

        registry.update("USDC-A");
        assertEq(registry.pip("USDC-A"), ilks["BAT-A"].pip);
        assertEq(registry.flip("USDC-A"), ilks["BAT-A"].flip);
    }

    function testFileAddress_dss() public {
        registry.add(ilks["WBTC-A"].join);
        assertEq(registry.pip(ilks["WBTC-A"].ilk), ilks["WBTC-A"].pip);

        registry.file(ilks["WBTC-A"].ilk, bytes32("gem"),  address(ilks["USDC-A"].gem));
        registry.file(ilks["WBTC-A"].ilk, bytes32("join"), address(ilks["USDC-A"].gem));

        assertEq(registry.gem(ilks["WBTC-A"].ilk),  ilks["USDC-A"].gem);
        assertEq(registry.join(ilks["WBTC-A"].ilk), ilks["USDC-A"].gem);
    }

    function testFailFileAddress_dss() public {
        registry.add(ilks["WBTC-A"].join);
        registry.file(ilks["WBTC-A"].ilk, bytes32("test"), address(ilks["USDC-A"].gem));
    }

    function testFileUint256_dss() public {
        registry.add(ilks["WBTC-A"].join);
        assertEq(registry.dec(ilks["WBTC-A"].ilk), ilks["WBTC-A"].dec);
        registry.file(ilks["WBTC-A"].ilk, bytes32("dec"), 1);
        assertEq(registry.dec(ilks["WBTC-A"].ilk), 1);
    }

    function testFailFileUint256_dss() public {
        registry.add(ilks["WBTC-A"].join);
        registry.file(ilks["WBTC-A"].ilk, bytes32("test"), ilks["BAT-A"].dec);
    }

    function testFileString_dss() public {
        registry.add(ilks["BAT-A"].join);
        // name
        assertEq(registry.name(ilks["BAT-A"].ilk), ilks["BAT-A"].name);
        registry.file(ilks["BAT-A"].ilk, bytes32("name"), "test");
        assertEq(registry.name(ilks["BAT-A"].ilk), "test");
        // symbol
        assertEq(registry.symbol(ilks["BAT-A"].ilk), ilks["BAT-A"].symbol);
        registry.file(ilks["BAT-A"].ilk, bytes32("symbol"), "test2");
        assertEq(registry.symbol(ilks["BAT-A"].ilk), "test2");
    }

    function testFailFileString_dss() public {
        registry.add(ilks["BAT-A"].join);
        registry.file(ilks["BAT-A"].ilk, bytes32("test"), ilks["BAT-A"].name);
    }
}
