# Gold Hero Section — Vault Tiers & KYC Flow

## Single Source of Truth: Portfolio API

The **portfolio endpoint** is always called first and is the **sole source of truth** for both KYC status and holdings. There is no separate KYC status check endpoint.

## Flow

```
1. User lands on Gold screen
2. Call live price API (existing)
3. Call portfolio API (existing)
4. Check KYC status from portfolio response:

   → KYC NOT done:
       - Show hero: "Own 99.9% pure 24k gold" (fresh user design)
       - But CTA button = "Complete KYC and unlock" (Figma 29168:5784)
         instead of "Buy digital gold"
       - On tap → call KYC invoke endpoint (TBD — Developer to share)
       - That endpoint triggers KYC on backend, returns response
         with status (done/not done)
       - Once KYC status = done in response → call portfolio again
       - Portfolio now reflects KYC complete → show existing user hero

   → KYC done + 0gm (no gold purchased yet):
       - Show existing user hero: "Your gold" / "0gm" / "AED 0"
       - Vault = 0gm image (empty locker)
       - Show "Buy gold" button (no Sell — nothing to sell)

   → KYC done + has gold:
       - Show existing user hero: "Your gold" / weight / AED value / gains badge
       - Vault image based on weight tier:
           0 < w ≤ 1g  → vault_0_1g
           1 < w ≤ 5g  → vault_1_5g
           5 < w ≤ 10g → vault_5_10g
           w > 10g     → vault_10plus
       - Show "Sell gold" (secondary) + "Buy more" (primary) buttons
```

## 5 Vault Tiers (Figma node 29391:4229)

| Tier | Weight Range | Vault Image | Description |
|------|-------------|-------------|-------------|
| **0gm** | Exactly 0 | Empty locker, no coins | KYC done but no gold yet |
| **0-1g** | 0 < w ≤ 1 | Locker with 1-2 small coins | Starter holdings |
| **1-5g** | 1 < w ≤ 5 | Locker with small stack | Growing holdings |
| **5-10g** | 5 < w ≤ 10 | Locker with larger pile | Significant holdings |
| **10+** | w > 10 | Locker overflowing with coins | Large holdings |

Each vault is a distinct asset — 5 separate images to export from Figma.

## Figma References

| Screen | Node ID | Description |
|--------|---------|-------------|
| Fresh user landing | 28998:3145 | "Own 99.9% pure 24k gold" + "Buy digital gold" |
| KYC not done | 29168:5784 | Same hero but CTA = "Complete KYC and unlock" |
| Existing user 0gm | 30328:14385 | "Your gold" / 0gm / empty vault / Buy gold |
| Existing user ~5gm | 29179:12194 | "Your gold" / 5gm / vault with coins / Sell + Buy more |
| Existing user 10+gm | 29179:13007 | "Your gold" / 10.78g / full vault / Sell + Buy more + gains badge |
| Vault tier assets | 29391:4229 | All 5 locker variants side by side |

## Pending — Need From Backend Team

1. **Portfolio response shape** — what is the KYC status field name? (e.g. `kycStatus: "APPROVED" | "PENDING" | "NOT_STARTED"` or a boolean `isKycDone`?)
2. **KYC invoke endpoint** — URL, method, request body, response shape (what status values can it return?)
3. **0gm hero buttons** — Figma (30328:14385) shows both "Sell gold" + "Buy gold" for 0gm. Should Sell be hidden when weight = 0? Or keep both as Figma shows?

## Implementation Notes

- Applies to both **iOS** and **Android**
- Vault assets need to be exported from Figma and added to both platforms
- Current hero section already handles fresh vs existing user — this adds KYC gate + vault tier logic
- No code changes until backend confirms the above questions
