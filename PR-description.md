# Add ERC-8888: Universal Named Contract Registry

## Summary

This PR introduces **ERC-8888**, a standard interface for registering deployed smart contracts with human-readable names, semantic versioning, ownership, metadata URIs, and lifecycle status.

## Problem

The Ethereum application layer lacks a standard for:
- **Naming** deployed contracts in a human-readable, tooling-queryable way
- **Versioning** contracts across upgrade cycles
- **Lifecycle signalling** (active, deprecated, paused, vulnerable, decommissioned)
- **Audit anchoring** — linking an on-chain entry to off-chain verification artefacts

Block explorers, developer tooling, wallets, and cross-protocol integrations all solve this ad hoc today. ERC-8888 defines a minimal, composable, permissionless interface that fills the gap.

## Relationship to Existing Standards

| Standard | Scope | ERC-8888 Relationship |
|---|---|---|
| ERC-165 | Interface introspection | Required by ERC-8888 |
| ERC-1820 | Interface ↔ implementer registry | Solves introspection, not naming/versioning |
| ERC-6224 | Intra-protocol dependency injection | Complementary; `bytes32` keys, private scope |
| ENS | Account name resolution | Resolves accounts; ERC-8888 resolves versioned contract deployments |

## Files Changed

```
ERCS/erc-8888.md                          ← EIP specification (this PR)
assets/erc-8888/IERC8888.sol              ← Solidity interface
assets/erc-8888/ERC8888Registry.sol       ← Reference implementation
```

## Checklist

- [x] Title follows the pattern `Add ERC: <title>`
- [x] `eip:` field set to `8888`
- [x] `status:` is `Draft`
- [x] `type:` is `Standards Track`, `category:` is `ERC`
- [x] `created:` date is today's date
- [x] `requires:` lists ERC-165 (EIP-165)
- [x] `discussions-to:` link present (Ethereum Magicians thread to be opened)
- [x] Abstract is ≤ 200 words
- [x] Reference implementation included in `assets/erc-8888/`
- [x] Copyright waived via CC0
- [x] Author GitHub handle included in `<>` brackets
- [x] No external submodules added
- [x] Markdown linted (no trailing whitespace, headings use `##`)

## Author

Edison Tan Khai Ping ([@EdisonTKPcom](https://github.com/EdisonTKPcom)) — <im@edisontkp.com>

---

> **Note to ERC editors**: The ERC-165 interface ID placeholder in the spec (`0x________`) will be updated with the computed XOR once editors confirm the final function signatures are acceptable. The `discussions-to` URL will be updated with the live Ethereum Magicians thread after this PR is opened.
