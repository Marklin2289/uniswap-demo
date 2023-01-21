// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma abicoder v2;

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

contract SwapExamples {
    ISwapRouter public immutable swapRouter;
    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant WETH9 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    // For this example, we will set the pool fee to 0.3%.
    uint24 public constant poolFee = 3000;

    constructor(ISwapRouter _swapRouter) {
        swapRouter = _swapRouter;
    }

    //     Input Parameters
    // path: The path is a sequence of (tokenAddress - fee - tokenAddress),
    // which are the variables needed to compute each pool contract address in our sequence of swaps.
    // The multihop swap router code will automatically find the correct pool with these variables,
    // and execute the swap needed within each pool in our sequence.
    // recipient: the destination address of the outbound asset.
    // deadline: the unix time after which a transaction will be reverted, to protect against long delays
    // and the increased chance of large price swings therein.
    // amountIn: the amount of the inbound asset
    // amountOutMin: the minimum amount of the outbound asset, less than which will cause the transaction
    // to revert. For the sake of this example we will set it to 0, in production one will need to use
    // the SDK to quote an expected price, or an on chain price oracle for more advanced manipulation
    // resistant systems.

    function swapExactInputMultihop(
        uint256 amountIn
    ) external returns (uint256 amountOut) {
        TransferHelper.safeTransferFrom(
            DAI,
            msg.sender,
            address(this),
            amountIn
        );
        TransferHelper.safeApprove(DAI, address(swapRouter), amountIn);
        ISwapRouter.ExactInputParams memory params = ISwapRouter
            .ExactInputParams({
                path: abi.encodePacked(DAI, poolFee, USDC, poolFee, WETH9),
                recipient: msg.sender,
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0
            });
        amountOut = swapRouter.exactInput(params);
    }

    function swapExactOutputMultihop(
        uint256 amountOut,
        uint256 amountInMaximum
    ) external returns (uint256 amountIn) {
        TransferHelper.safeTransferFrom(
            DAI,
            msg.sender,
            address(this),
            amountInMaximum
        );
        TransferHelper.safeApprove(DAI, address(swapRouter), amountInMaximum);
        ISwapRouter.ExactOutputParams memory params = ISwapRouter
            .ExactOutputParams({
                path: abi.encodePacked(DAI, poolFee, USDC, poolFee, WETH9),
                recipient: msg.sender,
                deadline: block.timestamp,
                amountOut: amountOut,
                amountInMaximum: amountInMaximum
            });
        amountIn = swapRouter.exactOutput(params);
        if (amountIn < amountInMaximum) {
            TransferHelper.safeApprove(DAI, address(swapRouter), 0);
            TransferHelper.safeTransferFrom(
                DAI,
                address(this),
                msg.sender,
                amountInMaximum - amountIn
            );
        }
    }
}
