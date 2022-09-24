// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./libraries/RepuSwapLibrary.sol";
import "../core/interfaces/IRepuSwapERC20.sol";

import "../core/RepuSwapPair.sol";

contract RepuSwapRouter {
    using SafeERC20 for IERC20;

    event AddLiquidityReturn(
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity
    );
    event RemoveLiquidityReturn(uint256 amountA, uint256 amountB);

    address public factory;

    bytes32 initcodehash = _initcodehash();

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "RepuSwapRouter: EXPIRED");
        _;
    }

    constructor(address _factory) {
        factory = _factory;
    }

    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) internal virtual returns (uint256 amountA, uint256 amountB) {
        (uint256 reserveA, uint256 reserveB) = RepuSwapLibrary.getReserves(
            factory,
            tokenA,
            tokenB
        );
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint256 amountBOptimal = RepuSwapLibrary.quote(
                amountADesired,
                reserveA,
                reserveB
            );
            if (amountBOptimal <= amountBDesired) {
                require(
                    amountBOptimal >= amountBMin,
                    "RepuSwapRouter: INSUFFICIENT_B_AMOUNT"
                );
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = RepuSwapLibrary.quote(
                    amountBDesired,
                    reserveB,
                    reserveA
                );
                assert(amountAOptimal <= amountADesired);
                require(
                    amountAOptimal >= amountAMin,
                    "RepuSwapRouter: INSUFFICIENT_A_AMOUNT"
                );
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        virtual
        ensure(deadline)
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        )
    {
        (amountA, amountB) = _addLiquidity(
            tokenA,
            tokenB,
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin
        );
        address pair = RepuSwapLibrary.pairFor(
            factory,
            initcodehash,
            tokenA,
            tokenB
        );
        // TODO: stack too deep error
        // IERC20(tokenA).safeTransferFrom(msg.sender, pair, amountA);
        // IERC20(tokenB).safeTransferFrom(msg.sender, pair, amountB);
        IERC20(tokenA).transferFrom(msg.sender, pair, amountA);
        IERC20(tokenB).transferFrom(msg.sender, pair, amountB);
        liquidity = IRepuSwapPair(pair).mint(to);

        emit AddLiquidityReturn(amountA, amountB, liquidity);
    }

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        public
        virtual
        ensure(deadline)
        returns (uint256 amountA, uint256 amountB)
    {
        address pair = RepuSwapLibrary.pairFor(
            factory,
            initcodehash,
            tokenA,
            tokenB
        );
        IRepuSwapERC20(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        (uint256 amount0, uint256 amount1) = IRepuSwapPair(pair).burn(to);
        (address token0, ) = RepuSwapLibrary.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0
            ? (amount0, amount1)
            : (amount1, amount0);
        require(amountA >= amountAMin, "RepuSwapRouter: INSUFFICIENT_A_AMOUNT");
        require(amountB >= amountBMin, "RepuSwapRouter: INSUFFICIENT_B_AMOUNT");

        emit RemoveLiquidityReturn(amountA, amountB);
    }

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual returns (uint256 amountA, uint256 amountB) {
        address pair = RepuSwapLibrary.pairFor(
            factory,
            initcodehash,
            tokenA,
            tokenB
        );
        uint256 value = liquidity;
        IRepuSwapERC20(pair).permit(
            msg.sender,
            address(this),
            value,
            deadline,
            v,
            r,
            s
        );
        (amountA, amountB) = removeLiquidity(
            tokenA,
            tokenB,
            liquidity,
            amountAMin,
            amountBMin,
            to,
            deadline
        );

        emit RemoveLiquidityReturn(amountA, amountB);
    }

    function _swap(
        uint256[] memory amounts,
        address[] memory path,
        address _to
    ) internal virtual {
        unchecked {
            for (uint256 i; i < path.length - 1; i++) {
                (address input, address output) = (path[i], path[i + 1]);
                (address token0, ) = RepuSwapLibrary.sortTokens(input, output);
                uint256 amountOut = amounts[i + 1];
                (uint256 amount0Out, uint256 amount1Out) = input == token0
                    ? (uint256(0), amountOut)
                    : (amountOut, uint256(0));
                address to = i < path.length - 2
                    ? RepuSwapLibrary.pairFor(
                        factory,
                        initcodehash,
                        output,
                        path[i + 2]
                    )
                    : _to;
                IRepuSwapPair(
                    RepuSwapLibrary.pairFor(
                        factory,
                        initcodehash,
                        input,
                        output
                    )
                ).swap(amount0Out, amount1Out, to, new bytes(0));
            }
        }
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual ensure(deadline) returns (uint256[] memory amounts) {
        amounts = RepuSwapLibrary.getAmountsOut(factory, amountIn, path);
        require(
            amounts[amounts.length - 1] >= amountOutMin,
            "RepuSwapRouter: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        IERC20(path[0]).safeTransferFrom(
            msg.sender,
            RepuSwapLibrary.pairFor(factory, initcodehash, path[0], path[1]),
            amounts[0]
        );
        _swap(amounts, path, to);
    }

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual ensure(deadline) returns (uint256[] memory amounts) {
        amounts = RepuSwapLibrary.getAmountsIn(factory, amountOut, path);
        require(
            amounts[0] <= amountInMax,
            "RepuSwapRouter: EXCESSIVE_INPUT_AMOUNT"
        );
        IERC20(path[0]).safeTransferFrom(
            msg.sender,
            RepuSwapLibrary.pairFor(factory, initcodehash, path[0], path[1]),
            amounts[0]
        );
        _swap(amounts, path, to);
    }

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) public pure virtual returns (uint256 amountB) {
        return RepuSwapLibrary.quote(amountA, reserveA, reserveB);
    }

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) public pure virtual returns (uint256 amountOut) {
        return RepuSwapLibrary.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) public pure virtual returns (uint256 amountIn) {
        return RepuSwapLibrary.getAmountIn(amountOut, reserveIn, reserveOut);
    }

    function getAmountsOut(uint256 amountIn, address[] memory path)
        public
        view
        virtual
        returns (uint256[] memory amounts)
    {
        return RepuSwapLibrary.getAmountsOut(factory, amountIn, path);
    }

    function getAmountsIn(uint256 amountOut, address[] memory path)
        public
        view
        virtual
        returns (uint256[] memory amounts)
    {
        return RepuSwapLibrary.getAmountsIn(factory, amountOut, path);
    }
}

function _initcodehash() pure returns (bytes32 bytecode) {
    bytecode = keccak256(type(RepuSwapPair).creationCode);
}
