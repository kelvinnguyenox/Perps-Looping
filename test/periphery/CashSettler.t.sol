// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import "forge-std/Test.sol";

import "src/periphery/CashSettler.sol";

contract CashSettlerTest is Test {
    WETH constant WETH9 = WETH(payable(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1));
    ERC20 constant USDC = ERC20(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8);
    ContangoPositionNFT constant positionNFT = ContangoPositionNFT(0x497931c260a6f76294465f7BBB5071802e97E109);
    IContango constant contango = IContango(0x30E7348163016B3b6E1621A3Cb40e8CF33CE97db);
    IContangoQuoter constant contangoQuoter = IContangoQuoter(0x807073F955439fa0eF808a9B50007696b5dCE971);

    function testSettleETHUSDCParaswap() public {
        vm.createSelectFork("arbitrum", 50667869);

        CashSettler sut = new CashSettler(positionNFT,contango,contangoQuoter,WETH9);

        PositionId positionId = PositionId.wrap(261);
        address owner = positionNFT.positionOwner(positionId);
        Position memory position = contango.position(positionId);

        // Clear owner balance to simplify assertions
        deal(address(USDC), owner, 0);

        vm.prank(owner);
        positionNFT.safeTransferFrom(
            owner,
            address(sut),
            PositionId.unwrap(positionId),
            abi.encode(
                CashSettler.NFTCallback({
                    symbol: position.symbol,
                    base: WETH9,
                    quote: USDC,
                    openQuantity: position.openQuantity,
                    spender: address(0x216B4B4Ba9F3e719726886d34a177484278Bfcae),
                    dex: address(0xDEF171Fe48CF0115B1d80b88dc8eAB59176FEe57),
                    swapBytes: hex"54e3f31b000000000000000000000000000000000000000000000000000000000000002000000000000000000000000082af49447d8a07e3bd95bd0d56f35241523fbab1000000000000000000000000ff970a61a04b1ca14834a43f5de4533ebddb5cc800000000000000000000000000000000000000000000000002c68af0bb140000000000000000000000000000000000000000000000000000000000000e801810000000000000000000000000000000000000000000000000000000000e85aba500000000000000000000000000000000000000000000000000000000000001e00000000000000000000000000000000000000000000000000000000000000220000000000000000000000000000000000000000000000000000000000000038000000000000000000000000000000000000000000000000000000000000003e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e4d12a78a24f63f856b7192beaacc9875d387fec010000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000004200000000000000000000000000000000000000000000000000000000063b5280cd254d444505f4e4d9d5b9f376ee9596f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000e592427a0aece92de3edee1f18e0157c058615640000000000000000000000000000000000000000000000000000000000000124c04b8d59000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000def171fe48cf0115b1d80b88dc8eab59176fee570000000000000000000000000000000000000000000000000000000063b4e1bc00000000000000000000000000000000000000000000000002c68af0bb1400000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002b82af49447d8a07e3bd95bd0d56f35241523fbab10001f4ff970a61a04b1ca14834a43f5de4533ebddb5cc800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000124000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
                    to: owner
                })
            )
        );

        assertEqDecimal(USDC.balanceOf(owner), 203.474114e6, 6);
        assertEq(USDC.balanceOf(address(sut)), 0);
        assertEq(USDC.balanceOf(address(sut)), 0);
        assertEq(address(sut).balance, 0);
    }

    function testSettleUSDCETH1Inch() public {
        vm.createSelectFork("arbitrum", 50774715);

        CashSettler sut = new CashSettler(positionNFT,contango,contangoQuoter,WETH9);

        PositionId positionId = PositionId.wrap(352);
        address owner = positionNFT.positionOwner(positionId);
        Position memory position = contango.position(positionId);

        // Clear owner balance to simplify assertions
        vm.deal(owner, 0);
        deal(address(WETH9), owner, 0);

        vm.prank(owner);
        positionNFT.safeTransferFrom(
            owner,
            address(sut),
            PositionId.unwrap(positionId),
            abi.encode(
                CashSettler.NFTCallback({
                    symbol: position.symbol,
                    base: USDC,
                    quote: WETH9,
                    openQuantity: position.openQuantity,
                    spender: address(0x1111111254EEB25477B68fb85Ed929f73A960582),
                    dex: address(0x1111111254EEB25477B68fb85Ed929f73A960582),
                    swapBytes: hex"12aa3caf000000000000000000000000521709b3cd7f07e29722be0ba28a8ce0e806dbc3000000000000000000000000ff970a61a04b1ca14834a43f5de4533ebddb5cc800000000000000000000000082af49447d8a07e3bd95bd0d56f35241523fbab1000000000000000000000000521709b3cd7f07e29722be0ba28a8ce0e806dbc3000000000000000000000000ce71065d4017f316ec606fe4422e11eb2c47c2460000000000000000000000000000000000000000000000000000000006422c400000000000000000000000000000000000000000000000000127a66819ea4d210000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000014000000000000000000000000000000000000000000000000000000000000001600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000013a00000000000000000000000000000000000000000000000000000000011c433026333db71b82e2df33d1c11158470b73e3d270720000000000000000000000000000000000000000000000000127a66819ea4d21002424b31a0c0000000000000000000000001111111254eeb25477b68fb85ed929f73a96058200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000fffd8963efd1fc6a506488495d951d5263988d2500000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000020000000000000000000000000ff970a61a04b1ca14834a43f5de4533ebddb5cc8000000000000cfee7c08",
                    to: owner
                })
            )
        );

        assertEqDecimal(owner.balance, 0.034820244421333404 ether, 18);
        assertEq(WETH9.balanceOf(address(owner)), 0);
        assertEq(WETH9.balanceOf(address(sut)), 0);
        assertEq(USDC.balanceOf(address(sut)), 0);
        assertEq(address(sut).balance, 0);
    }
}
