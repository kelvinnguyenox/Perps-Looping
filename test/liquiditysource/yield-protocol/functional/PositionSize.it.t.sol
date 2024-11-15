//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "./WithYieldFixtures.sol";
import {IOraclePoolStub} from "../../../stub/IOraclePoolStub.sol";

contract YieldPositionSizeTest is
    WithYieldFixtures(constants.yETHUSDC2306, constants.FYETH2306, constants.FYUSDC2306)
{
    using SignedMath for int256;
    using SafeCast for int256;

    error PositionIsTooSmall(uint256 openCost, uint256 minCost);

    function setUp() public override {
        super.setUp();

        stubPrice({
            _base: WETH9,
            _quote: USDC,
            baseUsdPrice: 1400e6,
            quoteUsdPrice: 1e6,
            spread: 1e6,
            uniswapFee: uniswapFee
        });

        vm.etch(address(instrument.basePool), address(new IPoolStub(instrument.basePool)).code);
        vm.etch(address(instrument.quotePool), address(new IPoolStub(instrument.quotePool)).code);

        IPoolStub(address(instrument.basePool)).setBidAsk(0.945e18, 0.955e18);
        IPoolStub(address(instrument.quotePool)).setBidAsk(0.895e6, 0.905e6);

        symbol = Symbol.wrap("yETHUSDC2306-2");
        vm.prank(contangoTimelock);
        instrument = contangoYield.createYieldInstrumentV2(symbol, constants.FYETH2306, constants.FYUSDC2306, feeModel);

        vm.startPrank(yieldTimelock);
        compositeOracle.setSource(
            constants.FYETH2306,
            constants.ETH_ID,
            new IOraclePoolStub(IPoolStub(address(instrument.basePool)), constants.FYETH2306)
        );
        vm.stopPrank();

        _setPoolStubLiquidity(instrument.basePool, 1_000 ether);
        _setPoolStubLiquidity(instrument.quotePool, 1_000_000e6);
    }

    function testCanNotOpenSmallPosition() public {
        OpeningCostParams memory params = OpeningCostParams({
            symbol: symbol,
            quantity: 0.1 ether,
            collateralSlippage: collateralSlippage,
            uniswapFee: uniswapFee
        });
        ModifyCostResult memory result = contangoQuoter.openingCostForPositionWithCollateral(params, 0);

        assertEqDecimal(result.spotCost, -140.1e6, 6);
        assertEqDecimal(result.cost, -145.604115e6, 6);

        dealAndApprove(address(USDC), trader, result.collateralUsed.toUint256(), address(contango));

        vm.expectRevert(
            abi.encodeWithSelector(PositionIsTooSmall.selector, result.cost.abs() + Yield.BORROWING_BUFFER + 1, 200e6)
        );
        vm.prank(trader);
        contango.createPosition(
            symbol,
            trader,
            params.quantity,
            result.cost.abs() + Yield.BORROWING_BUFFER + 1,
            result.collateralUsed.toUint256(),
            trader,
            HIGH_LIQUIDITY,
            uniswapFee
        );
    }

    function testCanNotReducePositionSizeIfItWouldEndUpTooSmall() public {
        (PositionId positionId,) = _openPosition(0.2 ether);

        // Reduce position
        ModifyCostResult memory result = contangoQuoter.modifyCostForPositionWithCollateral(
            ModifyCostParams(positionId, -0.08 ether, collateralSlippage, uniswapFee), 0
        );

        vm.expectRevert(
            abi.encodeWithSelector(PositionIsTooSmall.selector, 171.932398e6 + Yield.BORROWING_BUFFER, 200e6)
        );
        vm.prank(trader);
        contango.modifyPosition(
            positionId, -0.08 ether, result.cost.abs(), 0, trader, result.quoteLendingLiquidity, uniswapFee
        );
    }
}

contract YieldDebtLimitsTest is WithYieldFixtures(constants.yETHUSDC2306, constants.FYETH2306, constants.FYUSDC2306) {
    function setUp() public override {
        super.setUp();

        DataTypes.Debt memory debt = cauldron.debt({baseId: constants.USDC_ID, ilkId: constants.FYETH2306});
        vm.prank(yieldTimelock);
        ICauldronExt(address(cauldron)).setDebtLimits({
            baseId: constants.USDC_ID,
            ilkId: constants.FYETH2306,
            max: uint96(debt.sum / 1e6) + 10_000, // Set max debt to 10.000 USDC over the current debt, so the available debt is always 10k
            min: debt.min, // Set min debt to 100 USDC
            dec: debt.dec
        });
    }

    function testDebtLimit() public {
        // positions borrow USDC
        DataTypes.Series memory series = cauldron.series(instrument.quoteId);

        // open position
        (PositionId positionId,) = _openPosition(9 ether);

        // initial debt state
        DataTypes.Debt memory debt = cauldron.debt(series.baseId, instrument.baseId);

        // checks increase would fail
        dealAndApprove(address(USDC), trader, 6000e6, address(contango));
        vm.expectRevert("Max debt exceeded");
        vm.prank(trader);
        contango.modifyPosition(positionId, 10 ether, type(uint256).max, 6000e6, trader, 0, uniswapFee);

        // assert unchanged debt limits
        DataTypes.Debt memory debtAfter = cauldron.debt(series.baseId, instrument.baseId);
        assertEq(debt.sum, debtAfter.sum);
    }

    function testCanNotRemoveCollateral_openPositionOnDebtLimit() public {
        // positions borrow USDC
        DataTypes.Series memory series = cauldron.series(instrument.quoteId);

        // open position
        (PositionId positionId,) = _openPosition(9.2 ether);

        // initial debt state
        DataTypes.Debt memory debt = cauldron.debt(series.baseId, instrument.baseId);
        uint256 remainingDebt = uint256(debt.max) * 10 ** debt.dec - debt.sum;

        // checks realise profit would fail
        vm.expectRevert("Max debt exceeded");
        vm.prank(trader);
        contango.modifyCollateral(positionId, -int256(remainingDebt + 1), type(uint256).max, trader, 0);
    }
}
