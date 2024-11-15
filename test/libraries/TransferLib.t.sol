//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "forge-std/Test.sol";

import "src/libraries/TransferLib.sol";

import "../utils/Utilities.sol";

contract TransferLibTest is Test {
    Utilities private utils;
    TestERC20 private token;

    function setUp() public {
        utils = new Utilities();
        token = new TestERC20();
    }

    function testTransferOutFromAddressToAddress(uint256 amount) public {
        // given
        address payer = utils.getNextUserAddress("payer");
        address to = utils.getNextUserAddress("to");

        deal(address(token), payer, amount);
        vm.prank(payer);
        token.approve(address(this), amount);

        // when
        TransferLib.transferOut(token, payer, to, amount);

        // then
        assertEq(token.balanceOf(payer), 0);
        assertEq(token.balanceOf(to), amount);
    }

    function testTransferOutFromThisToAddress(uint256 amount) public {
        // given
        address to = utils.getNextUserAddress("to");

        deal(address(token), address(this), amount);

        // when
        TransferLib.transferOut(token, address(this), to, amount);

        // then
        assertEq(token.balanceOf(address(this)), 0);
        assertEq(token.balanceOf(to), amount);
    }

    function testTransferOutPayerZeroAddressError(uint256 amount) public {
        // given
        address to = utils.getNextUserAddress("to");

        // expect
        vm.expectRevert(TransferLib.ZeroPayer.selector);

        // when
        TransferLib.transferOut(token, address(0), to, amount);
    }

    function testTransferOutToZeroAddressError(uint256 amount) public {
        // given
        address payer = utils.getNextUserAddress("payer");

        // expect
        vm.expectRevert(TransferLib.ZeroDestination.selector);

        // when
        TransferLib.transferOut(token, payer, address(0), amount);
    }
}

contract TestERC20 is ERC20 {
    // solhint-disable-next-line no-empty-blocks
    constructor() ERC20("Test", "TST", 18) {}
}
