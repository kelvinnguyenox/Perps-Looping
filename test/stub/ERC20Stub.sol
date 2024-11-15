//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "solmate/src/tokens/ERC20.sol";
import "solmate/src/utils/SafeTransferLib.sol";

contract ERC20Stub is ERC20 {
    using SafeTransferLib for address payable;

    // solhint-disable-next-line no-empty-blocks
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_, 18) {}

    function setBalance(address account, uint256 amount) public {
        _burn(account, balanceOf[account]);
        _mint(account, amount);
    }

    function addBalance(address account, int256 amount) public {
        if (amount > 0) {
            _mint(account, uint256(amount));
        } else {
            _burn(account, uint256(-amount));
        }
    }

    function deposit() external payable {
        setBalance(msg.sender, msg.value);
    }

    function withdraw(uint256 wad) external {
        if (wad > balanceOf[msg.sender]) {
            revert("Insufficient balance");
        }
        _burn(msg.sender, wad);
        payable(msg.sender).safeTransferETH(wad);
    }
}
