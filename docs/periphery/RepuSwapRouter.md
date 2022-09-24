## `RepuSwapRouter`





### `ensure(uint256 deadline)`






### `constructor(address _factory)` (public)





### `_addLiquidity(address tokenA, address tokenB, uint256 amountADesired, uint256 amountBDesired, uint256 amountAMin, uint256 amountBMin) → uint256 amountA, uint256 amountB` (internal)





### `addLiquidity(address tokenA, address tokenB, uint256 amountADesired, uint256 amountBDesired, uint256 amountAMin, uint256 amountBMin, address to, uint256 deadline) → uint256 amountA, uint256 amountB, uint256 liquidity` (external)





### `removeLiquidity(address tokenA, address tokenB, uint256 liquidity, uint256 amountAMin, uint256 amountBMin, address to, uint256 deadline) → uint256 amountA, uint256 amountB` (public)





### `removeLiquidityWithPermit(address tokenA, address tokenB, uint256 liquidity, uint256 amountAMin, uint256 amountBMin, address to, uint256 deadline, uint8 v, bytes32 r, bytes32 s) → uint256 amountA, uint256 amountB` (external)





### `_swap(uint256[] amounts, address[] path, address _to)` (internal)





### `swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] path, address to, uint256 deadline) → uint256[] amounts` (external)





### `swapTokensForExactTokens(uint256 amountOut, uint256 amountInMax, address[] path, address to, uint256 deadline) → uint256[] amounts` (external)





### `quote(uint256 amountA, uint256 reserveA, uint256 reserveB) → uint256 amountB` (public)





### `getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) → uint256 amountOut` (public)





### `getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut) → uint256 amountIn` (public)





### `getAmountsOut(uint256 amountIn, address[] path) → uint256[] amounts` (public)





### `getAmountsIn(uint256 amountOut, address[] path) → uint256[] amounts` (public)






### `AddLiquidityReturn(uint256 amountA, uint256 amountB, uint256 liquidity)`





### `RemoveLiquidityReturn(uint256 amountA, uint256 amountB)`





