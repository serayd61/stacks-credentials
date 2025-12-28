# Stacks Credentials 🎓

Blockchain-powered credential verification system. Issue, verify, and manage academic certificates, professional licenses, and achievement badges as NFTs.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Built on Stacks](https://img.shields.io/badge/Built%20on-Stacks-5546FF)](https://stacks.co)

## Overview

Stacks Credentials transforms how credentials are issued and verified. By storing certificates as NFTs on the blockchain, we enable instant verification, eliminate fraud, and give individuals ownership of their achievements.

## Problem

- 📜 **Paper credentials are easy to forge**
- ⏰ **Verification takes days or weeks**
- 💰 **Background checks are expensive**
- 🔒 **Credentials locked in institutional silos**

## Solution

- ✅ **Tamper-proof** - Cryptographically secured on blockchain
- ⚡ **Instant verification** - Anyone can verify in seconds
- 🆓 **Free verification** - Read-only, no cost to verify
- 👤 **Self-sovereign** - You own your credentials as NFTs

## Use Cases

### 🎓 Academic Credentials
- University degrees
- Course certificates
- Academic transcripts
- Professional certifications

### 💼 Professional Licenses
- Medical licenses
- Legal bar admission
- Engineering certifications
- Financial advisor credentials

### 🏆 Achievements & Badges
- Hackathon winners
- Community contributions
- Skill assessments
- DAO participation

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    ISSUER PORTAL                            │
│  (Universities, Companies, DAOs)                            │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                 CREDENTIAL REGISTRY                         │
│  - Issue credentials                                        │
│  - Revoke if needed                                        │
│  - Update metadata                                          │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                  CREDENTIAL NFT                             │
│  - SIP-009 compliant                                        │
│  - Soul-bound option                                        │
│  - On-chain metadata                                        │
└────────────────────────┬────────────────────────────────────┘
                         │
         ┌───────────────┼───────────────┐
         ▼               ▼               ▼
┌─────────────┐  ┌─────────────┐  ┌─────────────┐
│   HOLDER    │  │  VERIFIER   │  │  EMPLOYER   │
│  (Student)  │  │  (Anyone)   │  │  (Company)  │
└─────────────┘  └─────────────┘  └─────────────┘
```

## Smart Contracts

### credential-nft.clar
SIP-009 compliant NFT contract for credentials.

### issuer-registry.clar
Registry of trusted credential issuers.

### verification.clar
Verification logic and revocation handling.

## Features

### For Issuers
- Register as trusted issuer
- Issue credentials to recipients
- Revoke credentials if needed
- Batch issuance for graduations

### For Holders
- View all credentials in wallet
- Share verification links
- Transfer non-soul-bound credentials
- Export credential proofs

### For Verifiers
- Instant verification
- Check issuer authenticity
- Verify revocation status
- API for integrations

## Quick Start

### Issue a Credential

```clarity
;; Register as issuer first
(contract-call? .issuer-registry register-issuer
  "MIT" ;; issuer name
  "Massachusetts Institute of Technology"
  "https://mit.edu"
)

;; Issue credential to graduate
(contract-call? .credential-nft issue-credential
  'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7 ;; recipient
  "Bachelor of Science in Computer Science"
  "https://ipfs.io/ipfs/Qm.../metadata.json"
  true ;; soul-bound (non-transferable)
)
```

### Verify a Credential

```clarity
;; Anyone can verify for free
(contract-call? .credential-nft verify-credential u1)
;; Returns: { valid: true, issuer: "MIT", holder: 'SP2J6...', issued-at: 12345 }
```

## Metadata Standard

```json
{
  "name": "Bachelor of Science - Computer Science",
  "description": "Awarded to John Doe for completing...",
  "image": "ipfs://Qm.../diploma.png",
  "external_url": "https://mit.edu/verify/12345",
  "attributes": [
    { "trait_type": "Institution", "value": "MIT" },
    { "trait_type": "Degree Type", "value": "Bachelor" },
    { "trait_type": "Major", "value": "Computer Science" },
    { "trait_type": "GPA", "value": "3.8" },
    { "trait_type": "Graduation Date", "value": "2024-05-15" },
    { "trait_type": "Honors", "value": "Magna Cum Laude" }
  ],
  "credential": {
    "type": "AcademicCredential",
    "issuer_did": "did:stacks:SP...",
    "issuance_date": "2024-05-15T00:00:00Z",
    "expiration_date": null
  }
}
```

## Installation

```bash
# Clone the repository
git clone https://github.com/serayd61/stacks-credentials.git
cd stacks-credentials

# Install dependencies
npm install

# Run tests
clarinet test

# Deploy to testnet
clarinet deployments apply -p testnet
```

## API Endpoints

### Verify Credential
```
GET /api/verify/:token-id
```

### Get Holder Credentials
```
GET /api/credentials/:address
```

### Get Issuer Info
```
GET /api/issuer/:address
```

## Security

- **Soul-bound Option** - Non-transferable credentials
- **Issuer Verification** - Only registered issuers can mint
- **Revocation** - Issuers can revoke if needed
- **On-chain Proofs** - All data verifiable on-chain

## Roadmap

- [x] Core NFT contract
- [x] Issuer registry
- [x] Verification logic
- [x] Soul-bound support
- [ ] Batch issuance
- [ ] Expiration handling
- [ ] DID integration
- [ ] Mobile app
- [ ] Employer dashboard

## Contributing

Contributions welcome! See CONTRIBUTING.md for guidelines.

## License

MIT © [serayd61](https://github.com/serayd61)

## Related Projects

- [Blockcerts](https://www.blockcerts.org/) - Open standard for blockchain credentials
- [Verifiable Credentials](https://www.w3.org/TR/vc-data-model/) - W3C standard

