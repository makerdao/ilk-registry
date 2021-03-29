/// UnRWAUrn.sol -- Test fixture mocking RWAUrn

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity >=0.5.12;

import {Vat}              from 'dss/vat.sol';
import {Jug}              from 'dss/jug.sol';
import {Dai}              from 'dss/dai.sol';
import {DaiJoin, GemJoin} from 'dss/join.sol';

contract UnRWAUrn {
    // --- auth ---
    mapping (address => uint256) public wards;
    mapping (address => uint256) public can;
    function rely(address usr) external auth {
        wards[usr] = 1;
        emit Rely(usr);
    }
    function deny(address usr) external auth {
        wards[usr] = 0;
        emit Deny(usr);
    }
    modifier auth {
        require(wards[msg.sender] == 1, "RwaUrn/not-authorized");
        _;
    }
    function hope(address usr) external auth {
        can[usr] = 1;
        emit Hope(usr);
    }
    function nope(address usr) external auth {
        can[usr] = 0;
        emit Nope(usr);
    }
    modifier operator {
        require(can[msg.sender] == 1, "RwaUrn/not-operator");
        _;
    }

    Vat  public vat;
    Jug  public jug;
    GemJoin public gemJoin;
    DaiJoin public daiJoin;
    address public outputConduit;

    // Events
    event Rely(address indexed usr);
    event Deny(address indexed usr);
    event Hope(address indexed usr);
    event Nope(address indexed usr);
    event File(bytes32 indexed what, address data);
    event Lock(address indexed usr, uint256 wad);
    event Free(address indexed usr, uint256 wad);
    event Draw(address indexed usr, uint256 wad);
    event Wipe(address indexed usr, uint256 wad);
    event Quit(address indexed usr, uint256 wad);

    // --- math ---
    uint256 constant RAY = 10 ** 27;
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x);
    }
    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x);
    }
    function divup(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(x, sub(y, 1)) / y;
    }

    // --- init ---
    constructor(
        address vat_, address jug_, address gemJoin_, address daiJoin_, address outputConduit_
    ) public {
        // requires in urn that outputConduit isn't address(0)
        vat = Vat(vat_);
        jug = Jug(jug_);
        gemJoin = GemJoin(gemJoin_);
        daiJoin = DaiJoin(daiJoin_);
        outputConduit = outputConduit_;
        wards[msg.sender] = 1;
        Dai(address(gemJoin.gem())).approve(address(gemJoin), uint256(-1));
        Dai(address(daiJoin.dai())).approve(address(daiJoin), uint256(-1));
        Vat(vat_).hope(address(daiJoin));
        emit Rely(msg.sender);
        emit File("outputConduit", outputConduit_);
        emit File("jug", jug_);
    }

    // --- administration ---
    function file(bytes32 what, address data) external auth {
        if (what == "outputConduit") { outputConduit = data; }
        else if (what == "jug") { jug = Jug(data); }
        else revert("RwaUrn/unrecognised-param");
        emit File(what, data);
    }

    // --- cdp operation ---
    // n.b. that the operator must bring the gem
    function lock(uint256 wad) external operator {
        require(wad <= 2**255 - 1, "RwaUrn/overflow");
        Dai(address(gemJoin.gem())).transferFrom(msg.sender, address(this), wad);
        // join with address this
        gemJoin.join(address(this), wad);
        vat.frob(gemJoin.ilk(), address(this), address(this), address(this), int(wad), 0);
        emit Lock(msg.sender, wad);
    }
    // n.b. that the operator takes the gem
    // and might not be the same operator who brought the gem
    function free(uint256 wad) external operator {
        require(wad <= 2**255, "RwaUrn/overflow");
        vat.frob(gemJoin.ilk(), address(this), address(this), address(this), -int(wad), 0);
        gemJoin.exit(msg.sender, wad);
        emit Free(msg.sender, wad);
    }
    // n.b. DAI can only go to the output conduit
    function draw(uint256 wad) external operator {
        require(outputConduit != address(0));
        bytes32 ilk = gemJoin.ilk();
        jug.drip(ilk);
        (,uint256 rate,,,) = vat.ilks(ilk);
        uint256 dart = divup(mul(RAY, wad), rate);
        require(dart <= 2**255 - 1, "RwaUrn/overflow");
        vat.frob(ilk, address(this), address(this), address(this), 0, int(dart));
        daiJoin.exit(outputConduit, wad);
        emit Draw(msg.sender, wad);
    }
    // n.b. anyone can wipe
    function wipe(uint256 wad) external {
        daiJoin.join(address(this), wad);
        bytes32 ilk = gemJoin.ilk();
        jug.drip(ilk);
        (,uint256 rate,,,) = vat.ilks(ilk);
        uint256 dart = mul(RAY, wad) / rate;
        require(dart <= 2 ** 255, "RwaUrn/overflow");
        vat.frob(ilk, address(this), address(this), address(this), 0, -int(dart));
        emit Wipe(msg.sender, wad);
    }

    // If Dai is sitting here after ES that should be sent back
    function quit() external {
        require(outputConduit != address(0));
        require(vat.live() == 0, "RwaUrn/vat-still-live");
        Dai dai = Dai(address(daiJoin.dai()));
        uint256 wad = dai.balanceOf(address(this));
        dai.transfer(outputConduit, wad);
        emit Quit(msg.sender, wad);
    }
}
