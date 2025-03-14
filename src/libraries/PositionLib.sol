//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./CodecLib.sol";
import "./DataTypes.sol";
import "./Errors.sol";
import "./ConfigStorageLib.sol";
import "./StorageLib.sol";

library PositionLib {
    using CodecLib for uint256;

    function lookupPositionOwner(PositionId positionId) internal view returns (address trader) {
        trader = ConfigStorageLib.getPositionNFT().positionOwner(positionId);
        if (msg.sender != trader) {
            revert NotPositionOwner(positionId, msg.sender, trader);
        }
    }

    function validatePosition(PositionId positionId) internal view returns (uint256 openQuantity) {
        (openQuantity,) = StorageLib.getPositionNotionals()[positionId].decodeU128();

        // Position was fully liquidated
        if (openQuantity == 0) {
            (int256 collateral,) = StorageLib.getPositionBalances()[positionId].decodeI128();
            // Negative collateral means there's nothing left for the trader to get
            if (0 > collateral) {
                revert InvalidPosition(positionId);
            }
        }
    }

    function validateExpiredPosition(PositionId positionId)
        internal
        view
        returns (uint256 openQuantity, Symbol symbol, InstrumentStorage memory instrument)
    {
        openQuantity = validatePosition(positionId);
        (symbol, instrument) = StorageLib.getInstrument(positionId);

        // solhint-disable-next-line not-rely-on-time
        uint256 timestamp = block.timestamp;
        if (instrument.maturity > timestamp) {
            revert PositionActive(positionId, instrument.maturity, timestamp);
        }
    }

    function validateActivePosition(PositionId positionId)
        internal
        view
        returns (uint256 openQuantity, Symbol symbol, InstrumentStorage memory instrument)
    {
        openQuantity = validatePosition(positionId);
        (symbol, instrument) = StorageLib.getInstrument(positionId);

        // solhint-disable-next-line not-rely-on-time
        uint256 timestamp = block.timestamp;
        if (instrument.maturity <= timestamp) {
            revert PositionExpired(positionId, instrument.maturity, timestamp);
        }
    }

    function loadActivePosition(PositionId positionId)
        internal
        view
        returns (uint256 openQuantity, address owner, Symbol symbol, InstrumentStorage memory instrument)
    {
        owner = lookupPositionOwner(positionId);
        (openQuantity, symbol, instrument) = validateActivePosition(positionId);
    }

    function validatePayer(PositionId positionId, address payer, address trader) internal view {
        if (payer != trader && payer != address(this) && payer != msg.sender) {
            revert InvalidPayer(positionId, payer);
        }
    }

    function deletePosition(PositionId positionId) internal {
        StorageLib.getPositionInstrument()[positionId] = Symbol.wrap("");
        ConfigStorageLib.getPositionNFT().burn(positionId);
    }
}
