// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.20;

/**
 * @title  IERC8888 — Universal Named Contract Registry Interface
 * @notice Standard interface for registering deployed smart contracts with
 *         human-readable names, semantic versioning, ownership, metadata
 *         URIs, and lifecycle status.
 * @dev    See https://eips.ethereum.org/EIPS/eip-8888
 *         ERC-165 interfaceId: computed from XOR of all function selectors.
 *         Requires ERC-165 support (EIP-165).
 */
interface IERC8888 {

    // =========================================================================
    // Enums & Structs
    // =========================================================================

    /**
     * @notice Lifecycle status of a registered contract.
     * @dev    Active       — deployed and operational.
     *         Deprecated   — superseded; a newer version exists.
     *         Paused       — temporarily halted by the owner.
     *         Vulnerable   — known security issue; do not interact.
     *         Decommissioned — permanently retired.
     */
    enum ContractStatus {
        Active,
        Deprecated,
        Paused,
        Vulnerable,
        Decommissioned
    }

    /**
     * @notice Full registry entry for a named contract.
     * @param contractAddress  Address of the deployed contract.
     * @param owner            Address authorised to update this entry.
     * @param version          Semantic version string (e.g. "2.1.0").
     * @param metadataURI      URI resolving to an ERC-8888 metadata document.
     * @param status           Current lifecycle status.
     * @param registeredAt     block.timestamp at first registration.
     * @param updatedAt        block.timestamp of the most recent update.
     */
    struct ContractEntry {
        address contractAddress;
        address owner;
        string  version;
        string  metadataURI;
        ContractStatus status;
        uint256 registeredAt;
        uint256 updatedAt;
    }

    // =========================================================================
    // Events
    // =========================================================================

    /**
     * @notice Emitted when a new entry is registered.
     * @param nameHash        keccak256 of `name` (for indexed log filtering).
     * @param name            Full human-readable name.
     * @param contractAddress The registered contract address.
     * @param owner           The registering address (becomes entry owner).
     * @param version         Semantic version at registration.
     */
    event ContractRegistered(
        bytes32 indexed nameHash,
        string  name,
        address indexed contractAddress,
        address indexed owner,
        string  version
    );

    /**
     * @notice Emitted when an existing entry is updated.
     * @param nameHash        keccak256 of `name`.
     * @param name            Full human-readable name.
     * @param contractAddress The new (or unchanged) contract address.
     * @param status          The new lifecycle status.
     */
    event ContractUpdated(
        bytes32 indexed nameHash,
        string  name,
        address indexed contractAddress,
        ContractStatus status
    );

    /**
     * @notice Emitted when entry ownership is transferred.
     * @param nameHash        keccak256 of `name`.
     * @param name            Full human-readable name.
     * @param previousOwner   The previous entry owner.
     * @param newOwner        The new entry owner.
     */
    event OwnershipTransferred(
        bytes32 indexed nameHash,
        string  name,
        address indexed previousOwner,
        address indexed newOwner
    );

    // =========================================================================
    // Write Functions
    // =========================================================================

    /**
     * @notice Register a new named contract entry.
     * @dev    MUST revert if `name` is already registered.
     *         MUST revert if `contractAddress` is the zero address.
     *         MUST revert if `name` is an empty string.
     *         Caller becomes the entry owner.
     *         MUST emit {ContractRegistered}.
     * @param name            Unique human-readable identifier.
     * @param contractAddress Address of the deployed contract.
     * @param version         Semantic version string.
     * @param metadataURI     URI resolving to a JSON metadata document.
     */
    function register(
        string  calldata name,
        address contractAddress,
        string  calldata version,
        string  calldata metadataURI
    ) external;

    /**
     * @notice Update an existing entry.
     * @dev    MUST revert if caller is not the entry owner.
     *         MUST revert if `name` is not registered.
     *         MUST revert if `contractAddress` is the zero address.
     *         MUST emit {ContractUpdated}.
     * @param name            Registered name to update.
     * @param contractAddress New (or current) contract address.
     * @param version         New semantic version string.
     * @param metadataURI     New metadata URI.
     * @param status          New lifecycle status.
     */
    function update(
        string  calldata name,
        address contractAddress,
        string  calldata version,
        string  calldata metadataURI,
        ContractStatus status
    ) external;

    /**
     * @notice Transfer ownership of a registry entry.
     * @dev    MUST revert if caller is not the current entry owner.
     *         MUST revert if `newOwner` is the zero address.
     *         MUST emit {OwnershipTransferred}.
     * @param name     Registered name whose ownership is being transferred.
     * @param newOwner Address of the new entry owner.
     */
    function transferEntryOwnership(
        string  calldata name,
        address newOwner
    ) external;

    // =========================================================================
    // Read Functions
    // =========================================================================

    /**
     * @notice Retrieve the full entry for a registered name.
     * @dev    MUST revert if `name` is not registered.
     * @param name The registered name to look up.
     * @return     The full {ContractEntry} struct.
     */
    function getEntry(string calldata name)
        external
        view
        returns (ContractEntry memory);

    /**
     * @notice Resolve a name directly to its current contract address.
     * @dev    MUST revert if `name` is not registered.
     *         Convenience shorthand for `getEntry(name).contractAddress`.
     * @param name The registered name to resolve.
     * @return contractAddress The resolved contract address.
     */
    function resolve(string calldata name)
        external
        view
        returns (address contractAddress);

    /**
     * @notice Check whether a name is currently registered.
     * @param name The name to check.
     * @return     True if registered, false otherwise.
     */
    function isRegistered(string calldata name)
        external
        view
        returns (bool);

    /**
     * @notice Return the lifecycle status of a registered contract.
     * @dev    MUST revert if `name` is not registered.
     * @param name The registered name to query.
     * @return     The current {ContractStatus}.
     */
    function statusOf(string calldata name)
        external
        view
        returns (ContractStatus);
}
