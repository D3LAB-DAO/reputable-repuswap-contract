// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../RepuSwapPair.sol";

contract Utils {
    function initcodehash() external pure returns (bytes32 bytecode) {
        bytecode = keccak256(type(RepuSwapPair).creationCode);
    }
}
