// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.6.12;

import "ds-test/test.sol";
import "ds-token/token.sol";
import "ds-value/value.sol";

import {Vat}     from 'dss/vat.sol';
import {End}     from 'dss/end.sol';
import {Vow}     from 'dss/vow.sol';
import {Cat}     from 'dss/cat.sol';
import {Dog}     from 'dss/dog.sol';
import {Dai}     from 'dss/dai.sol';
import {Spotter} from 'dss/spot.sol';
import {PipLike} from 'dss/spot.sol';
import {Flipper} from 'dss/flip.sol';
import {Clipper} from 'dss/clip.sol';
import {Flapper} from 'dss/flap.sol';
import {Flopper} from 'dss/flop.sol';
import {GemJoin} from 'dss/join.sol';

import "./test/fixtures/UnDai.sol";
import "./test/fixtures/UnRWAUrn.sol";
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
    Dog dog;
    Spotter spot;

    IlkRegistry public registry;

    struct Ilk {
        bytes32 ilk;
        uint256 class;
        address pip;
        address gem;
        address join;
        address flip;
        address clip;
        uint256 dec;
        string  name;
        string  symbol;
    }

    mapping (bytes32 => Ilk) ilks;

    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;

    event Debug(uint256, address);
    event Debug(uint256, uint256);
    event Debug(uint256, bytes32);

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

        Flipper flip = new Flipper(address(vat), address(cat), name);
        vat.hope(address(flip));
        flip.rely(address(cat));
        cat.file(name, "flip", address(flip));

        ilks[name].ilk    = name;
        ilks[name].class  = 2;
        ilks[name].pip    = address(pip);
        ilks[name].gem    = address(coin);
        ilks[name].join   = address(join);
        ilks[name].flip   = address(flip);
        ilks[name].dec    = join.dec();
        ilks[name].name   = bytes32ToStr(name);
        ilks[name].symbol = bytes32ToStr(name);
    }

    function initClippableCollateral(bytes32 name) internal returns (Ilk memory) {
        DSToken coin = new DSToken(name);
        coin.setName(name);
        coin.mint(20 ether);

        vat.init(name);
        GemJoin join = new GemJoin(address(vat), name, address(coin));
        vat.rely(address(join));

        DSValue pip = new DSValue();
        spot.file(name, "pip", address(pip));

        Clipper clip = new Clipper(address(vat), address(spot), address(dog), name);
        vat.hope(address(clip));
        clip.rely(address(dog));
        dog.file(name, "clip", address(clip));

        ilks[name].ilk    = name;
        ilks[name].class  = 1;
        ilks[name].pip    = address(pip);
        ilks[name].gem    = address(coin);
        ilks[name].join   = address(join);
        ilks[name].flip   = address(clip);
        ilks[name].dec    = join.dec();
        ilks[name].name   = bytes32ToStr(name);
        ilks[name].symbol = bytes32ToStr(name);
    }

    function initStandardCollateral(bytes32 name) internal returns (Ilk memory) {
        Dai coin = new Dai(1);
        coin.mint(address(this), 20 ether);

        vat.init(name);
        GemJoin join = new GemJoin(address(vat), name, address(coin));
        vat.rely(address(join));

        DSValue pip = new DSValue();
        spot.file(name, "pip", address(pip));

        Flipper flip = new Flipper(address(vat), address(cat), name);
        vat.hope(address(flip));
        flip.rely(address(cat));
        cat.file(name, "flip", address(flip));

        ilks[name].ilk    = name;
        ilks[name].class  = 2;
        ilks[name].pip    = address(pip);
        ilks[name].gem    = address(coin);
        ilks[name].join   = address(join);
        ilks[name].flip   = address(flip);
        ilks[name].dec    = join.dec();
        ilks[name].name   = coin.name();
        ilks[name].symbol = coin.symbol();
    }

    function initMissingCollateral(bytes32 name) internal returns (Ilk memory) {
        UnDai coin = new UnDai(1);
        coin.mint(address(this), 20 ether);

        vat.init(name);
        GemJoin join = new GemJoin(address(vat), name, address(coin));
        vat.rely(address(join));

        DSValue pip = new DSValue();
        spot.file(name, "pip", address(pip));

        Flipper flip = new Flipper(address(vat), address(cat), name);
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

    function initRWACollateral(bytes32 name) internal returns (Ilk memory) {
        Dai coin = new Dai(1);
        coin.mint(address(this), 20 ether);

        vat.init(name);
        GemJoin gjoin = new GemJoin(address(vat), name, address(coin));
        vat.rely(address(gjoin));
        DaiJoin djoin = new DaiJoin(address(vat), address(coin));
        vat.rely(address(djoin));

        DSValue pip = new DSValue();
        spot.file(name, "pip", address(pip));

        address _outputConduit = address(1);

        UnRWAUrn _urn = new UnRWAUrn(
            address(vat),   // vat
            address(0),     // jug
            address(gjoin), // gemJoin
            address(djoin), // daiJoin
            _outputConduit  // outputConduit
        );
        gjoin.rely(address(_urn));

        ilks[name].ilk    = name;
        ilks[name].class  = 3;
        ilks[name].pip    = address(pip);
        ilks[name].gem    = address(coin);
        ilks[name].join   = address(gjoin);
        ilks[name].flip   = _outputConduit;
        ilks[name].dec    = gjoin.dec();
        ilks[name].name   = coin.name();
        ilks[name].symbol = coin.symbol();
    }

    function setUp() public {
        vat  = new Vat();
        cat  = new Cat(address(vat));
        dog  = new Dog(address(vat));
        spot = new Spotter(address(vat));

        vat.rely(address(cat));
        vat.rely(address(dog));
        vat.rely(address(vat));
        vat.rely(address(spot));

        end = new End();
        end.file("vat",  address(vat));
        end.file("cat",  address(cat));
        end.file("dog",  address(dog));
        end.file("spot", address(spot));

        initCollateral("ETH-A");
        initCollateral("BAT-A");
        initCollateral("WBTC-A");
        initCollateral("USDC-A");
        initCollateral("USDC-B");
        initClippableCollateral("CLIP-A");
        initClippableCollateral("LINK-A");
        initStandardCollateral("DAI-A");
        initMissingCollateral("UNDAI-A");
        initRWACollateral("RWA001");
        initRWACollateral("RWA002");
        registry = new IlkRegistry(address(vat), address(dog), address(cat), address(spot));
    }

    function isIlkInReg(bytes32 _ilk) public returns (bool) {
        bytes32[] memory _list = registry.list();
        for (uint256 i = 0; i < _list.length; i++) {
            if (_list[i] == _ilk) { return true; }
        }
    }

    function testAddIlk_dss() public {
        assertEq(registry.count(), 0);
        registry.add(ilks["ETH-A"].join);
        registry.add(ilks["BAT-A"].join);
        registry.add(ilks["DAI-A"].join);
        registry.add(ilks["LINK-A"].join);
        assertEq(registry.count(), 4);
    }

    function testAddRWAViaUpdateAuth() public {
        bytes32 _ilk = "RWA001";

        assertEq(registry.count(), 0);

        registry.put(
            _ilk,
            ilks[_ilk].join,
            ilks[_ilk].gem,
            ilks[_ilk].dec,
            ilks[_ilk].class,
            ilks[_ilk].pip,
            ilks[_ilk].flip,
            ilks[_ilk].name,
            ilks[_ilk].symbol
        );

        assertEq(registry.count(), 1);
    }

    function testFailUpdateAuthClass() public {
        bytes32 _ilk = "RWA001";

        assertEq(registry.count(), 0);

        registry.put(
            _ilk,
            ilks[_ilk].join,
            ilks[_ilk].gem,
            ilks[_ilk].dec,
            0,                      // Fail on class 0
            ilks[_ilk].pip,
            ilks[_ilk].flip,
            ilks[_ilk].name,
            ilks[_ilk].symbol
        );
    }

    function testUpdateRWAViaUpdateAuth() public {
        bytes32 _ilk = "RWA001";
        registry.put(ilks[_ilk].ilk, ilks[_ilk].join, ilks[_ilk].gem, ilks[_ilk].dec, ilks[_ilk].class, ilks[_ilk].pip, ilks[_ilk].flip, ilks[_ilk].name, ilks[_ilk].symbol);

        registry.put(
            _ilk,        // _ilk
            address(1),  // _join
            address(2),  // _gem
            3,           // _dec
            4,           // _class
            address(5),  // _pip
            address(6),  // _xlip
            "7",         // _name
            "8"          // _symbol
        );

        assertEq(registry.count(), 1);
        assertEq(registry.join(_ilk), address(1));
        assertEq(registry.gem(_ilk), address(2));
        assertEq(registry.dec(_ilk), 3);
        assertEq(registry.class(_ilk), 4);
        assertEq(registry.pip(_ilk), address(5));
        assertEq(registry.xlip(_ilk), address(6));
        assertEq(registry.name(_ilk), "7");
        assertEq(registry.symbol(_ilk), "8");
    }

    function testIlkData_dss() public {
        registry.add(ilks["ETH-A"].join);
        registry.add(ilks["BAT-A"].join);

        (uint96 pos, address join, address gem, uint8 dec, uint96 class, address pip, address xlip,
         string memory name, string memory symbol) = registry.ilkData(ilks["BAT-A"].ilk);
        assertEq(uint256(pos), 1); // 0-indexed
        assertEq(class,  ilks["BAT-A"].class);
        assertEq(gem,    ilks["BAT-A"].gem);
        assertEq(pip,    ilks["BAT-A"].pip);
        assertEq(join,   ilks["BAT-A"].join);
        assertEq(xlip,   ilks["BAT-A"].flip);
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
        registry.add(ilks["DAI-A"].join);
        registry.add(ilks["CLIP-A"].join);
        bytes32[] memory regIlks = registry.list();
        assertEq(regIlks.length, 7);
        assertEq(regIlks[0], ilks["ETH-A"].ilk);
        assertEq(regIlks[1], ilks["BAT-A"].ilk);
        assertEq(regIlks[2], ilks["WBTC-A"].ilk);
        assertEq(regIlks[3], ilks["USDC-A"].ilk);
        assertEq(regIlks[4], ilks["USDC-B"].ilk);
        assertEq(regIlks[5], ilks["DAI-A"].ilk);
        assertEq(regIlks[6], ilks["CLIP-A"].ilk);
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

    function testXlip_dss() public {
        registry.add(ilks["WBTC-A"].join);
        registry.add(ilks["USDC-A"].join);
        assertEq(registry.xlip(ilks["USDC-A"].ilk), ilks["USDC-A"].flip);
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

    function testRemoveCagedClippable_dss() public {
        registry.add(ilks["CLIP-A"].join);
        registry.add(ilks["WBTC-A"].join);
        registry.add(ilks["LINK-A"].join);

        GemJoin linkJoin = GemJoin(ilks["LINK-A"].join);

        assertEq(registry.count(), 3);
        assertTrue(isIlkInReg("LINK-A"));
        assertEq(linkJoin.live(), 1);

        // Cage the LINK adapter so we can test removing it
        linkJoin.cage();

        assertEq(linkJoin.live(), 0);

        registry.remove(ilks["LINK-A"].ilk);
        assertEq(registry.count(), 2);
        assertTrue(!isIlkInReg("LINK-A"));
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
        registry.add(ilks["DAI-A"].join);
        registry.add(ilks["UNDAI-A"].join);
        assertEq(registry.name(ilks["WBTC-A"].ilk), ilks["WBTC-A"].name);
        assertEq(registry.name(ilks["DAI-A"].ilk), ilks["DAI-A"].name);
        assertEq(registry.name(ilks["UNDAI-A"].ilk), ilks["UNDAI-A"].name);
    }

    function testSymbol_dss() public {
        registry.add(ilks["WBTC-A"].join);
        registry.add(ilks["DAI-A"].join);
        registry.add(ilks["UNDAI-A"].join);
        assertEq(registry.symbol(ilks["WBTC-A"].ilk), ilks["WBTC-A"].symbol);
        assertEq(registry.symbol(ilks["DAI-A"].ilk), ilks["DAI-A"].symbol);
        assertEq(registry.symbol(ilks["UNDAI-A"].ilk), ilks["UNDAI-A"].symbol);
    }

    function testInfo_dss() public {
        registry.add(ilks["BAT-A"].join);
        registry.add(ilks["WBTC-A"].join);
        registry.add(ilks["USDC-A"].join);
        (string memory name, string memory symbol, uint256 class, uint256 dec,
        address gem, address pip, address join, address flip) = registry.info(ilks["USDC-A"].ilk);

        assertEq(name,   ilks["USDC-A"].name);
        assertEq(symbol, ilks["USDC-A"].symbol);
        assertEq(class,  ilks["USDC-A"].class);
        assertEq(dec,    ilks["USDC-A"].dec);
        assertEq(gem,    ilks["USDC-A"].gem);
        assertEq(pip,    ilks["USDC-A"].pip);
        assertEq(join,   ilks["USDC-A"].join);
        assertEq(flip,   ilks["USDC-A"].flip);
    }

    function testUpdate_dss() public {
        registry.add(ilks["BAT-A"].join);
        assertEq(registry.pip("BAT-A"), ilks["BAT-A"].pip);
        registry.update("BAT-A");
        assertEq(registry.pip("BAT-A"), ilks["BAT-A"].pip);
    }

    function testUpdateChanged_dss() public {
        registry.add(ilks["USDC-A"].join);
        assertEq(registry.pip("USDC-A"), ilks["USDC-A"].pip);
        assertEq(registry.xlip("USDC-A"), ilks["USDC-A"].flip);

        // Test spell updates to USDC pip and flip to match BAT
        spot.file("USDC-A", "pip", ilks["BAT-A"].pip);

        registry.update("USDC-A");
        assertEq(registry.pip("USDC-A"), ilks["BAT-A"].pip);
    }

    function testFileCat_dss() public {
        registry.add(ilks["WBTC-A"].join);
        assertEq(registry.pip(ilks["WBTC-A"].ilk), ilks["WBTC-A"].pip);

        cat  = new Cat(address(vat));
        vat.rely(address(cat));
        end.file("cat",  address(cat));
        Flipper flip = new Flipper(address(vat), address(cat), "WBTC-A");
        vat.hope(address(flip));
        flip.rely(address(cat));
        cat.file("WBTC-A", "flip", address(flip));

        registry.file(bytes32("cat"), address(cat));
        assertEq(address(cat), address(registry.cat()));
        registry.removeAuth("WBTC-A");
        registry.add(ilks["WBTC-A"].join);

        assertEq(address(flip), address(registry.xlip("WBTC-A")));
    }

    function testFileDog_dss() public {
        registry.add(ilks["CLIP-A"].join);
        assertEq(registry.pip(ilks["CLIP-A"].ilk), ilks["CLIP-A"].pip);

        dog  = new Dog(address(vat));
        vat.rely(address(dog));
        end.file("dog",  address(dog));
        Clipper clip = new Clipper(address(vat), address(spot), address(dog), "CLIP-A");
        vat.hope(address(clip));
        clip.rely(address(dog));
        dog.file("CLIP-A", "clip", address(clip));

        registry.file(bytes32("dog"), address(dog));
        assertEq(address(dog), address(registry.dog()));
        registry.removeAuth("CLIP-A");
        registry.add(ilks["CLIP-A"].join);

        assertEq(address(clip), address(registry.xlip("CLIP-A")));
    }

    function testFileSpot_dss() public {
        registry.add(ilks["DAI-A"].join);
        assertEq(registry.pip(ilks["DAI-A"].ilk), ilks["DAI-A"].pip);

        spot  = new Spotter(address(vat));
        vat.rely(address(spot));
        end.file("spot",  address(spot));
        DSValue pip = new DSValue();
        spot.file("DAI-A", "pip", address(pip));

        registry.file(bytes32("spot"), address(spot));
        assertEq(address(spot), address(registry.spot()));

        assertEq(ilks["DAI-A"].pip, address(registry.pip("DAI-A")));
        registry.update("DAI-A");
        assertEq(address(pip), address(registry.pip("DAI-A")));
    }

    function testFileAddress_dss() public {
        registry.add(ilks["WBTC-A"].join);
        assertEq(registry.pip(ilks["WBTC-A"].ilk), ilks["WBTC-A"].pip);

        registry.file(ilks["WBTC-A"].ilk, bytes32("gem"),  address(ilks["USDC-A"].gem));
        registry.file(ilks["WBTC-A"].ilk, bytes32("join"), address(ilks["USDC-A"].gem));
        registry.file(ilks["WBTC-A"].ilk, bytes32("pip"),  address(ilks["USDC-A"].gem));
        registry.file(ilks["WBTC-A"].ilk, bytes32("xlip"), address(ilks["USDC-A"].gem));

        assertEq(registry.gem(ilks["WBTC-A"].ilk),  ilks["USDC-A"].gem);
        assertEq(registry.join(ilks["WBTC-A"].ilk), ilks["USDC-A"].gem);
        assertEq(registry.pip(ilks["WBTC-A"].ilk),  ilks["USDC-A"].gem);
        assertEq(registry.xlip(ilks["WBTC-A"].ilk), ilks["USDC-A"].gem);
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
        registry.file(ilks["WBTC-A"].ilk, bytes32("class"), 500);
        assertEq(registry.class(ilks["WBTC-A"].ilk), 500);
    }

    function testFailFileUint256_dss() public {
        registry.add(ilks["WBTC-A"].join);
        registry.file(ilks["WBTC-A"].ilk, bytes32("test"), ilks["BAT-A"].dec);
    }

    function testFailFileClassTooBig_dss() public {
        registry.add(ilks["WBTC-A"].join);
        registry.file(ilks["WBTC-A"].ilk, bytes32("class"), uint96(-1) + 1);
    }

    function testFailFileClassZero_dss() public {
        registry.add(ilks["WBTC-A"].join);
        registry.file(ilks["WBTC-A"].ilk, bytes32("class"), 0);
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
