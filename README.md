# uniform

> A wrapped ERC-20 that presents the same address across every chain, regardless of where the underlying token lives.

---

## Concept

The same token exists at different addresses on different networks. `uniform` solves this by wrapping the underlying token in a contract deployed at a deterministic address — the same address everywhere. The wrapper looks the same on every chain. What it wraps is resolved locally.

Deposit USDC on Arbitrum, get `uniform` USDC at a known address. Deposit USDC on Base, get the same token at the same address. The uniform doesn't change. The underlying is chain-native.

---

## How It Works

A `uniform` contract resolves its underlying token address from an immutable [`locale`](https://github.com/uniteum/locale) lookup at initialization. Once set, neither the underlying address nor the lookup can be changed. The contract is then deployed via `CREATE2` to a deterministic address that is identical across all supported networks.

Consumers interact with a single, stable address regardless of chain. The cross-chain complexity is handled at the seams, not the surface.

---

## Properties

- **Deterministic address** — same contract address on every supported network
- **Immutable underlying** — resolved once from a `locale` lookup, never changed
- **Standard ERC-20** — deposit underlying to mint; burn to withdraw
- **No admin surface** — no owner, no upgrade path, no special roles

---

## Deployment

Addresses are consistent across all supported networks. A full deployment manifest is maintained in [`deployments/`](./deployments/).

---

## License

MIT
