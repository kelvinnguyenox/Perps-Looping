//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./ContangoTestBase.sol";

abstract contract WithArbitrum is ContangoTestBase {
    constructor() {
        DAI = ERC20(0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1);
        USDC = ERC20(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8);
        USDT = ERC20(0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9);
        WETH9 = WETH(payable(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1));

        // https://docs.chain.link/data-feeds/price-feeds/addresses?network=arbitrum
        chainlinkUsdOracles[DAI] = 0xc5C8E77B397E531B8EC06BFb0048328B30E9eCfB;
        chainlinkUsdOracles[USDC] = 0x50834F3163758fcC1Df9973b6e91f0F0F0434aD3;
        chainlinkUsdOracles[USDT] = 0x3f3f5dF88dC9F13eac63DF89EC16ef6e7E25DdE7;
        chainlinkUsdOracles[WETH9] = 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612;

        positionNFT = ContangoPositionNFT(0x497931c260a6f76294465f7BBB5071802e97E109);
        treasury = 0x643178CF8AEc063962654CAc256FD1f7fe06ac28;
        contangoTimelock = 0xe213C68563EE4c519183AE6c8Fc15d60bEaD95bb;
        contangoMultisig = 0xE865379A78d65D4cc58472BC16514e39bDEB2759;
        feeModel = IFeeModel(0xAb6E556046Bf9647f3E1ECB15FC7dB256b0b5188);
        chain = "arbitrum";
        chainId = 42161;
    }

    function setUp() public virtual override {
        super.setUp();

        vm.label(address(DAI), "DAI");
        vm.label(address(USDC), "USDC");
        vm.label(address(WETH9), "WETH");

        vm.label(chainlinkUsdOracles[DAI], "DAI / USD Oracle");
        vm.label(chainlinkUsdOracles[USDC], "USDC / USD Oracle");
        vm.label(chainlinkUsdOracles[WETH9], "ETH / USD Oracle");

        vm.label(address(positionNFT), "ContangoPositionNFT");
        vm.label(treasury, "Treasury");

        _clean(treasury); // Clean treasury
        _clean(address(contango)); // Clean proxy
    }

    function _deal(address token, address to, uint256 amount) internal override {
        if (token == address(WETH9)) {
            hoax(to, amount);
            WETH9.deposit{value: amount}();
        } else if (token == address(USDC)) {
            vm.prank(0x096760F208390250649E3e8763348E783AEF5562);
            IUSDC(address(USDC)).bridgeMint(to, amount);
        } else {
            deal(token, to, amount);
        }
        assertGe(ERC20(token).balanceOf(to), amount);
    }

    function _clean(address who) internal {
        deal(address(USDC), who, 0);
        deal(address(WETH9), who, 0);
        deal(address(DAI), who, 0);
    }
}

interface IUSDC {
    function bridgeMint(address account, uint256 amount) external;
}
