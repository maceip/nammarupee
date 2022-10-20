// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.17;

import '../vat.sol';

contract MockVat is Vat {
    function mint(address, uint wad) public {
//        joy[usr] += wad;
        debt += wad;
    }
}
