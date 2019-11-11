pragma solidity ^0.5.1;

import { Ownable } from "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import { Enum } from "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";
import { Executor } from "@gnosis.pm/safe-contracts/contracts/base/Executor.sol";

contract DelayedExecutor is Ownable, Executor {
    event TransactionAnnouncement(
        address to,
        uint256 value,
        bytes data,
        Enum.Operation operation,
        uint256 txGas,
        bytes32 hash
    );

    uint public delayPeriod;
    bytes32 public announcedTransactionHash;
    uint public announcementTime;

    constructor(uint _delayPeriod) public {
        delayPeriod = _delayPeriod;
    }

    function announceTransaction(address to, uint256 value, bytes calldata data, Enum.Operation operation, uint256 txGas)
        external
        onlyOwner

    {
        announcedTransactionHash = keccak256(abi.encode(to, value, data, operation, txGas));
        announcementTime = now;
        emit TransactionAnnouncement(to, value, data, operation, txGas, announcedTransactionHash);
    }

    function executeTransaction(address to, uint256 value, bytes calldata data, Enum.Operation operation, uint256 txGas)
        external
        onlyOwner
        returns (bool success)
    {
        bytes32 expectedHash = keccak256(abi.encode(to, value, data, operation, txGas));

        require(
            announcedTransactionHash == expectedHash,
            "DelayedExecutor: transaction unannounced"
        );

        require(
            now >= announcementTime + delayPeriod,
            "DelayedExecutor: not enough time has passed"
        );

        announcedTransactionHash = bytes32(0);
        announcementTime = 0;

        return execute(to, value, data, operation, txGas);
    }
}
