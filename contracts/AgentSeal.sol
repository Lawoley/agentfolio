// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice Minimal read interface for the SPACE ID Agent ID registry
///         (HandleRegistry, BNB Chain mainnet 0x60b9262456de011f7d15a54cdd8c48baaa8b022f).
///         The registry is an ERC-721 where each name's tokenId is
///         uint256(keccak256(bytes(bareHandle))) — verified on mainnet.
interface IAgentIDRegistrySeal {
    /// @notice Number of Agent ID name NFTs held by `account`. > 0 means Agent ID holder.
    function balanceOf(address account) external view returns (uint256);
    /// @notice Owner of the name NFT with the given tokenId. Reverts if the name is unregistered.
    function ownerOf(uint256 tokenId) external view returns (address);
}

/// @title AgentSeal
/// @notice Sign it with your Agent ID.
///
///         An Agent ID (name.ai) is a non-transferable, one-per-person name.
///         AgentSeal lets a holder stand behind a public statement with that
///         name — in a way anyone can check and nobody can fake:
///
///         - SEAL: a holder writes a short public statement off-chain (a post,
///           an offer, a commitment, an authorship claim). The app hashes the
///           exact statement text (keccak256 of its UTF-8 bytes) in the
///           browser and the holder anchors that fingerprint here, under
///           their own name, in one transaction they confirm in their own
///           wallet. Only Agent ID holders can seal, and only under a name
///           they actually own — both facts are enforced on-chain against
///           the official registry.
///         - VERIFY: anyone can take a statement, recompute its fingerprint,
///           and ask this contract who sealed it, under which name, and when.
///           Verification only ever covers statements their authors chose to
///           publish — this contract resolves no one's name or wallet that
///           has not sealed.
///         - REVOKE: the original sealer — and only the sealer — can revoke
///           a seal on-chain. A revoked seal stays visible, marked revoked,
///           so a verification never silently changes its answer.
///
/// @dev Permissions disclosure (hackathon red-line requirement): this contract
///      has NO owner, NO admin functions, NO payable functions and NO way to
///      move user funds or tokens. Nothing can be paused, minted, taxed or
///      withdrawn. The only writes are a holder sealing a statement hash
///      under their own name, and that same holder revoking their own seal.
contract AgentSeal {
    IAgentIDRegistrySeal public immutable registry;

    struct Seal {
        address sealer;   // wallet that anchored the seal
        string name;      // bare Agent ID handle the seal stands under, e.g. "giuseppino"
        uint64 sealedAt;  // unix time the seal was anchored
        bool revoked;     // true once the sealer revokes it
        bool exists;      // true once sealed (distinguishes "never sealed")
    }

    mapping(bytes32 => Seal) private _seals;         // statementHash => seal
    mapping(address => bytes32[]) private _bySealer; // sealer => their statement hashes, in order

    uint256 public totalSeals; // number of seals ever anchored (revoked ones included)

    event Sealed(address indexed sealer, string name, bytes32 indexed statementHash, uint64 timestamp);
    event SealRevoked(address indexed sealer, bytes32 indexed statementHash, uint64 timestamp);

    error NotAnAgentIDHolder();
    error NameNotOwnedByCaller();
    error AlreadySealed();
    error SealNotFound();
    error NotTheSealer();
    error AlreadyRevoked();

    constructor(address registryAddress) {
        registry = IAgentIDRegistrySeal(registryAddress);
    }

    // ------------------------------------------------------------------ views

    /// @notice The registry tokenId for a bare handle: uint256(keccak256(bytes(name))).
    /// @param name The bare handle, lowercase, without the ".ai" suffix (e.g. "giuseppino").
    function nameTokenId(string memory name) public pure returns (uint256) {
        return uint256(keccak256(bytes(name)));
    }

    /// @notice True if `account` holds an Agent ID in the official registry.
    function isHolder(address account) external view returns (bool) {
        return registry.balanceOf(account) > 0;
    }

    /// @notice Look up a seal by statement hash.
    /// @param statementHash keccak256 of the exact statement text (UTF-8 bytes).
    /// @return sealer  Wallet that anchored the seal (address(0) if never sealed).
    /// @return name    Bare Agent ID handle the seal stands under ("" if never sealed).
    /// @return sealedAt Unix time the seal was anchored (0 if never sealed).
    /// @return revoked True if the sealer has revoked this seal.
    /// @return exists  True if this statement hash has ever been sealed.
    function verifySeal(bytes32 statementHash)
        external
        view
        returns (address sealer, string memory name, uint64 sealedAt, bool revoked, bool exists)
    {
        Seal storage s = _seals[statementHash];
        return (s.sealer, s.name, s.sealedAt, s.revoked, s.exists);
    }

    /// @notice All statement hashes `sealer` has ever sealed, in the order they were sealed.
    function sealsOf(address sealer) external view returns (bytes32[] memory) {
        return _bySealer[sealer];
    }

    /// @notice How many seals `sealer` has ever anchored (revoked ones included).
    function sealCountOf(address sealer) external view returns (uint256) {
        return _bySealer[sealer].length;
    }

    // ------------------------------------------------------------------ writes

    /// @notice Anchor a statement fingerprint under your own Agent ID name.
    /// @dev The caller must (1) hold an Agent ID and (2) own the exact name
    ///      passed — the name is checked against the registry, never trusted.
    ///      A statement hash can be sealed only once, by the first sealer;
    ///      the same text sealed by anyone else afterwards reverts, so a
    ///      fingerprint always points at exactly one sealer and one name.
    /// @param statementHash keccak256 of the exact statement text (UTF-8 bytes),
    ///        computed off-chain by the app before calling.
    /// @param name The caller's bare Agent ID handle, lowercase, without ".ai".
    function seal(bytes32 statementHash, string calldata name) external {
        if (registry.balanceOf(msg.sender) == 0) revert NotAnAgentIDHolder();

        address owner;
        try registry.ownerOf(nameTokenId(name)) returns (address o) {
            owner = o;
        } catch {
            revert NameNotOwnedByCaller();
        }
        if (owner != msg.sender) revert NameNotOwnedByCaller();

        Seal storage s = _seals[statementHash];
        if (s.exists) revert AlreadySealed();

        s.sealer = msg.sender;
        s.name = name;
        s.sealedAt = uint64(block.timestamp);
        s.exists = true;
        _bySealer[msg.sender].push(statementHash);
        totalSeals += 1;

        emit Sealed(msg.sender, name, statementHash, uint64(block.timestamp));
    }

    /// @notice Revoke one of your own seals. The seal stays on record, marked
    ///         revoked, so past verifications remain explainable.
    /// @param statementHash A statement hash previously sealed by the caller.
    function revoke(bytes32 statementHash) external {
        Seal storage s = _seals[statementHash];
        if (!s.exists) revert SealNotFound();
        if (s.sealer != msg.sender) revert NotTheSealer();
        if (s.revoked) revert AlreadyRevoked();

        s.revoked = true;
        emit SealRevoked(msg.sender, statementHash, uint64(block.timestamp));
    }
}
