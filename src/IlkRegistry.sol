// SPDX-License-Identifier: AGPL-3.0-or-later

/// IlkRegistry.sol -- Publicly updatable ilk registry

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

pragma solidity ^0.6.7;

abstract contract JoinLike {
  function vat()          public virtual view returns (address);
  function ilk()          public virtual view returns (bytes32);
  function gem()          public virtual view returns (address);
  function dec()          public virtual view returns (uint256);
  function live()         public virtual view returns (uint256);
}

abstract contract VatLike {
  function wards(address) public virtual view returns (uint256);
  function live()         public virtual view returns (uint256);
}

abstract contract CatLike {
  function vat()          public virtual view returns (address);
  function live()         public virtual view returns (uint256);
  function ilks(bytes32)  public virtual view returns (address, uint256, uint256);
}

abstract contract FlipLike {
  function vat()          public virtual view returns (address);
}

abstract contract SpotLike {
  function live()         public virtual view returns (uint256);
  function vat()          public virtual view returns (address);
  function ilks(bytes32)  public virtual view returns (address, uint256);
}

abstract contract EndLike {
    function vat()        public virtual view returns (address);
    function cat()        public virtual view returns (address);
    function spot()       public virtual view returns (address);
}

abstract contract OptionalTokenLike {
    function name()       public virtual view returns (string memory);
    function symbol()     public virtual view returns (string memory);
}

contract IlkRegistry {

    event Rely(address usr);
    event Deny(address usr);
    event AddIlk(bytes32 ilk);
    event RemoveIlk(bytes32 ilk);

    // --- Auth ---
    mapping (address => uint) public wards;
    function rely(address usr) external auth { wards[usr] = 1; emit Rely(usr); }
    function deny(address usr) external auth { wards[usr] = 0; emit Deny(usr); }
    modifier auth {
        require(wards[msg.sender] == 1, "IlkRegistry/not-authorized");
        _;
    }

    VatLike  public vat;
    CatLike  public cat;
    SpotLike public spot;

    struct Ilk {
        uint256 pos;   // Index in ilks array
        address gem;   // The token contract
        address pip;   // Token price
        address join;  // DSS GemJoin adapter
        address flip;  // Auction contract
        uint256 dec;   // Token decimals
        string name;   // Token name
        string symbol; // Token symbol
    }

    mapping (bytes32 => Ilk) public ilkData;
    bytes32[] ilks;

    // Pass a dss End contract to the registry to initialize
    constructor(address end) public {

        vat = VatLike(EndLike(end).vat());
        cat = CatLike(EndLike(end).cat());
        spot = SpotLike(EndLike(end).spot());

        require(cat.vat() == address(vat), "IlkRegistry/invalid-cat-vat");
        require(spot.vat() == address(vat), "IlkRegistry/invalid-spotter-vat");
        require(vat.wards(address(cat)) == 1, "IlkRegistry/cat-not-authorized");
        require(vat.wards(address(spot)) == 1, "IlkRegistry/spot-not-authorized");
        require(vat.live() == 1, "IlkRegistry/vat-not-live");
        require(cat.live() == 1, "IlkRegistry/cat-not-live");
        require(spot.live() == 1, "IlkRegistry/spot-not-live");
        wards[msg.sender] = 1;
    }

    // Pass an active join adapter to the registry to add it to the set
    function add(address adapter) external {
        JoinLike join = JoinLike(adapter);

        // Validate adapter
        require(join.vat() == address(vat), "IlkRegistry/invalid-join-adapter-vat");
        require(vat.wards(address(join)) == 1, "IlkRegistry/adapter-not-authorized");

        // Validate ilk
        bytes32 _ilk = join.ilk();
        require(_ilk != 0, "IlkRegistry/ilk-adapter-invalid");
        require(ilkData[_ilk].join == address(0), "IlkRegistry/ilk-already-exists");

        (address _pip,) = spot.ilks(_ilk);
        require(_pip != address(0), "IlkRegistry/pip-invalid");

        (address _flip,,) = cat.ilks(_ilk);
        require(_flip != address(0), "IlkRegistry/flip-invalid");
        require(FlipLike(_flip).vat() == address(vat), "IlkRegistry/flip-wrong-vat");

        string memory name;
        try OptionalTokenLike(join.gem()).name() returns (string memory _name) {
            name = _name;
        } catch {}

        string memory symbol;
        try OptionalTokenLike(join.gem()).symbol() returns (string memory _symbol) {
            symbol = _symbol;
        } catch {}

        ilks.push(_ilk);
        ilkData[ilks[ilks.length - 1]] = Ilk(
            ilks.length - 1,
            join.gem(),
            _pip,
            address(join),
            _flip,
            join.dec(),
            name,
            symbol
        );

        emit AddIlk(_ilk);
    }

    // Anyone can remove an ilk if the adapter has been caged
    function remove(bytes32 ilk) external {
        JoinLike join = JoinLike(ilkData[ilk].join);
        require(address(join) != address(0), "IlkRegistry/invalid-ilk");
        require(join.live() == 0, "IlkRegistry/ilk-live");
        _remove(ilk);
        emit RemoveIlk(ilk);
    }

    // Admin can remove an ilk without any precheck
    function removeAuth(bytes32 ilk) external auth {
        _remove(ilk);
        emit RemoveIlk(ilk);
    }

    // Authed edit function
    function file(bytes32 ilk, bytes32 what, address data) external auth {
        if (what == "gem")       ilkData[ilk].gem  = data;
        else if (what == "pip")  ilkData[ilk].pip  = data;
        else if (what == "join") ilkData[ilk].join = data;
        else if (what == "flip") ilkData[ilk].flip = data;
        else revert("IlkRegistry/file-unrecognized-param-address");
    }

    // Authed edit function
    function file(bytes32 ilk, bytes32 what, uint256 data) external auth {
        if (what == "dec")       ilkData[ilk].dec  = data;
        else revert("IlkRegistry/file-unrecognized-param-uint256");
    }

    // Authed edit function
    function file(bytes32 ilk, bytes32 what, string calldata data) external auth {
        if (what == "name")        ilkData[ilk].name   = data;
        else if (what == "symbol") ilkData[ilk].symbol = data;
        else revert("IlkRegistry/file-unrecognized-param-string");
    }

    // Remove ilk from the ilks array by replacing the ilk with the
    //  last in the array and then trimming the end.
    function _remove(bytes32 ilk) internal {
        // Get the position in the array
        uint256 _index = ilkData[ilk].pos;
        // Get the last ilk in the array
        bytes32 _moveIlk = ilks[ilks.length - 1];
        // Replace the ilk we are removing
        ilks[_index] = _moveIlk;
        // Update the array position for the moved ilk
        ilkData[_moveIlk].pos = _index;
        // Trim off the end of the ilks array
        ilks.pop();
        // Delete struct data
        delete ilkData[ilk];
    }

    // The number of active ilks
    function count() external view returns (uint256) {
        return ilks.length;
    }

    // Return an array of the available ilks
    function list() external view returns (bytes32[] memory) {
        return ilks;
    }

    // Get a splice of the available ilks, useful when ilks array is large.
    function list(uint256 start, uint256 end) external view returns (bytes32[] memory) {
        require(start <= end && end < ilks.length, "IlkRegistry/invalid-input");
        bytes32[] memory _ilks = new bytes32[]((end - start) + 1);
        uint256 _count = 0;
        for (uint256 i = start; i <= end; i++) {
            _ilks[_count] = ilks[i];
            _count++;
        }
        return _ilks;
    }

    // Get the ilk at a specific position in the array
    function get(uint256 pos) external view returns (bytes32) {
        require(pos < ilks.length);
        return ilks[pos];
    }

    // Get information about an ilk, including name and symbol
    function info(bytes32 ilk) external view returns (
        string memory name,
        string memory symbol,
        uint256 dec,
        address gem,
        address pip,
        address join,
        address flip
    ) {

        return (this.name(ilk), this.symbol(ilk), this.dec(ilk),
        this.gem(ilk), this.pip(ilk), this.join(ilk), this.flip(ilk));
    }

    // The location of the ilk in the ilks array
    function pos(bytes32 ilk) external view returns (uint256) {
        return ilkData[ilk].pos;
    }

    // The token address
    function gem(bytes32 ilk) external view returns (address) {
        return ilkData[ilk].gem;
    }

    // The ilk's price feed
    function pip(bytes32 ilk) external view returns (address) {
        return ilkData[ilk].pip;
    }

    // The ilk's join adapter
    function join(bytes32 ilk) external view returns (address) {
        return ilkData[ilk].join;
    }

    // The flipper for the ilk
    function flip(bytes32 ilk) external view returns (address) {
        return ilkData[ilk].flip;
    }

    // The number of decimals on the ilk
    function dec(bytes32 ilk) external view returns (uint256) {
        return ilkData[ilk].dec;
    }

    // Return the symbol of the token, if available
    function symbol(bytes32 ilk) external view returns (string memory) {
        return ilkData[ilk].symbol;
    }

    // Return the name of the token, if available
    function name(bytes32 ilk) external view returns (string memory) {
        return ilkData[ilk].name;
    }
}
