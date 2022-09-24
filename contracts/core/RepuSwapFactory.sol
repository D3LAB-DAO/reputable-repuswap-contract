// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IRepuSwapPair.sol";

import "./RepuSwapPair.sol";

contract RepuSwapFactory is Ownable {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    address public feeTo;

    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    constructor() {}

    function allPairsLength() external view returns (uint256) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair)
    {
        require(tokenA != tokenB, "RepuSwap: IDENTICAL_ADDRESSES");
        (address token0, address token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "RepuSwap: ZERO_ADDRESS");
        require(getPair[token0][token1] == address(0), "RepuSwap: PAIR_EXISTS"); // single check is sufficient
        bytes memory bytecode = type(RepuSwapPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IRepuSwapPair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address feeTo_) external onlyOwner {
        feeTo = feeTo_;
    }
}
