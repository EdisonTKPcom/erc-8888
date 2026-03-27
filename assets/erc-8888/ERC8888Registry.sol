// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.20;

import { IERC8888 } from "./IERC8888.sol";
import { IERC165 }  from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title  ERC8888Registry
 * @notice Reference implementation of IERC8888 — Universal Named Contract Registry.
 *
 * @dev    Features:
 *           - Permissionless registration: any address may register any unregistered name.
 *           - Caller-as-owner: the registering address becomes the entry owner.
 *           - Owner-gated updates and ownership transfers.
 *           - ERC-165 introspection.
 *           - Reentrancy-free: storage-only, no external calls in write paths.
 *
 *         Intentional design omissions (left to higher-level governance layers):
 *           - No fee / bonding mechanism (anti-squatting left to deployer governance).
 *           - No forced `Vulnerable` override by a guardian (add AccessControl if needed).
 *           - No pagination for enumeration (add an off-chain indexer or subgraph).
 *
 * @author Edison Tan Khai Ping <im@edisontkp.com> — ERC-8888
 */
contract ERC8888Registry is IERC8888, IERC165 {

    // =========================================================================
    // Constants
    // =========================================================================

    /// @dev ERC-165 interfaceId for IERC8888.
    ///      Computed as XOR of all 7 function selectors in IERC8888.
    ///      register(string,address,string,string)           => 0xa4c0ed36
    ///      update(string,address,string,string,uint8)       => 0x8e1a55b5
    ///      transferEntryOwnership(string,address)           => 0xd2b4e8e0
    ///      getEntry(string)                                 => 0x5865c60d
    ///      resolve(string)                                  => 0xa5f15a7a
    ///      isRegistered(string)                             => 0x4b5e3a18
    ///      statusOf(string)                                 => 0x5a0f9e4b
    ///
    ///      NOTE: These selector values are illustrative pending final ABI lock.
    ///            Regenerate with: `cast sig "register(string,address,string,string)"` etc.
    bytes4 private constant _INTERFACE_ID_ERC8888 = type(IERC8888).interfaceId;

    // =========================================================================
    // Storage
    // =========================================================================

    /// @dev name → ContractEntry
    mapping(bytes32 => ContractEntry) private _entries;

    /// @dev Tracks which names are registered (separate bool for gas-efficient existence check)
    mapping(bytes32 => bool) private _exists;

    // =========================================================================
    // Errors
    // =========================================================================

    error ERC8888__NameEmpty();
    error ERC8888__AlreadyRegistered(string name);
    error ERC8888__NotRegistered(string name);
    error ERC8888__ZeroAddress();
    error ERC8888__NotOwner(string name, address caller);
    error ERC8888__NewOwnerZeroAddress();

    // =========================================================================
    // Constructor
    // =========================================================================

    constructor() {}

    // =========================================================================
    // ERC-165
    // =========================================================================

    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(bytes4 interfaceId)
        external
        pure
        override
        returns (bool)
    {
        return
            interfaceId == _INTERFACE_ID_ERC8888 ||
            interfaceId == type(IERC165).interfaceId;
    }

    // =========================================================================
    // Write Functions
    // =========================================================================

    /**
     * @inheritdoc IERC8888
     */
    function register(
        string  calldata name,
        address contractAddress,
        string  calldata version,
        string  calldata metadataURI
    ) external override {
        if (bytes(name).length == 0)       revert ERC8888__NameEmpty();
        if (contractAddress == address(0)) revert ERC8888__ZeroAddress();

        bytes32 key = _key(name);
        if (_exists[key])                  revert ERC8888__AlreadyRegistered(name);

        _entries[key] = ContractEntry({
            contractAddress : contractAddress,
            owner           : msg.sender,
            version         : version,
            metadataURI     : metadataURI,
            status          : ContractStatus.Active,
            registeredAt    : block.timestamp,
            updatedAt       : block.timestamp
        });
        _exists[key] = true;

        emit ContractRegistered(
            key,
            name,
            contractAddress,
            msg.sender,
            version
        );
    }

    /**
     * @inheritdoc IERC8888
     */
    function update(
        string  calldata name,
        address contractAddress,
        string  calldata version,
        string  calldata metadataURI,
        ContractStatus status
    ) external override {
        bytes32 key = _key(name);
        _requireRegistered(key, name);
        _requireOwner(key, name);
        if (contractAddress == address(0)) revert ERC8888__ZeroAddress();

        ContractEntry storage entry = _entries[key];
        entry.contractAddress = contractAddress;
        entry.version         = version;
        entry.metadataURI     = metadataURI;
        entry.status          = status;
        entry.updatedAt       = block.timestamp;

        emit ContractUpdated(key, name, contractAddress, status);
    }

    /**
     * @inheritdoc IERC8888
     */
    function transferEntryOwnership(
        string  calldata name,
        address newOwner
    ) external override {
        if (newOwner == address(0)) revert ERC8888__NewOwnerZeroAddress();

        bytes32 key = _key(name);
        _requireRegistered(key, name);
        _requireOwner(key, name);

        address previous = _entries[key].owner;
        _entries[key].owner    = newOwner;
        _entries[key].updatedAt = block.timestamp;

        emit OwnershipTransferred(key, name, previous, newOwner);
    }

    // =========================================================================
    // Read Functions
    // =========================================================================

    /**
     * @inheritdoc IERC8888
     */
    function getEntry(string calldata name)
        external
        view
        override
        returns (ContractEntry memory)
    {
        bytes32 key = _key(name);
        _requireRegistered(key, name);
        return _entries[key];
    }

    /**
     * @inheritdoc IERC8888
     */
    function resolve(string calldata name)
        external
        view
        override
        returns (address contractAddress)
    {
        bytes32 key = _key(name);
        _requireRegistered(key, name);
        return _entries[key].contractAddress;
    }

    /**
     * @inheritdoc IERC8888
     */
    function isRegistered(string calldata name)
        external
        view
        override
        returns (bool)
    {
        return _exists[_key(name)];
    }

    /**
     * @inheritdoc IERC8888
     */
    function statusOf(string calldata name)
        external
        view
        override
        returns (ContractStatus)
    {
        bytes32 key = _key(name);
        _requireRegistered(key, name);
        return _entries[key].status;
    }

    // =========================================================================
    // Internal Helpers
    // =========================================================================

    /**
     * @dev Compute a stable storage key from a name string.
     */
    function _key(string calldata name) internal pure returns (bytes32) {
        return keccak256(bytes(name));
    }

    /**
     * @dev Revert if the entry is not registered.
     */
    function _requireRegistered(bytes32 key, string calldata name) internal view {
        if (!_exists[key]) revert ERC8888__NotRegistered(name);
    }

    /**
     * @dev Revert if the caller is not the entry owner.
     */
    function _requireOwner(bytes32 key, string calldata name) internal view {
        if (_entries[key].owner != msg.sender)
            revert ERC8888__NotOwner(name, msg.sender);
    }
}
