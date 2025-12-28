;; Stacks Credentials - NFT Contract
;; SIP-009 compliant credential NFTs with soul-bound option
;; 
;; Features:
;; - Issue credentials as NFTs
;; - Optional soul-bound (non-transferable)
;; - On-chain metadata storage
;; - Revocation support

;; ============================================
;; Traits
;; ============================================

(impl-trait 'SP2PABAF9FTAJYNFZH93XENAJ8FVY99RRM50D2JG9.nft-trait.nft-trait)

;; ============================================
;; Constants
;; ============================================

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u1))
(define-constant ERR_NOT_FOUND (err u2))
(define-constant ERR_ALREADY_EXISTS (err u3))
(define-constant ERR_NOT_OWNER (err u4))
(define-constant ERR_SOUL_BOUND (err u5))
(define-constant ERR_REVOKED (err u6))
(define-constant ERR_NOT_ISSUER (err u7))
(define-constant ERR_INVALID_RECIPIENT (err u8))

;; ============================================
;; NFT Definition
;; ============================================

(define-non-fungible-token credential uint)

;; ============================================
;; Data Variables
;; ============================================

(define-data-var token-counter uint u0)
(define-data-var contract-uri (string-ascii 256) "https://stacks-credentials.io/api/contract")

;; ============================================
;; Data Maps
;; ============================================

;; Credential metadata
(define-map credentials
  { token-id: uint }
  {
    issuer: principal,
    holder: principal,
    title: (string-ascii 100),
    metadata-uri: (string-ascii 256),
    issued-at: uint,
    soul-bound: bool,
    revoked: bool,
    revoked-at: uint,
    credential-type: (string-ascii 50)
  }
)

;; Registered issuers
(define-map issuers
  { issuer: principal }
  {
    name: (string-ascii 100),
    description: (string-ascii 256),
    website: (string-ascii 100),
    verified: bool,
    total-issued: uint,
    registered-at: uint
  }
)

;; Holder credentials index
(define-map holder-credentials
  { holder: principal }
  { token-ids: (list 100 uint) }
)

;; ============================================
;; SIP-009 Functions
;; ============================================

;; Get last token ID
(define-read-only (get-last-token-id)
  (ok (var-get token-counter))
)

;; Get token URI
(define-read-only (get-token-uri (token-id uint))
  (match (map-get? credentials { token-id: token-id })
    cred (ok (some (get metadata-uri cred)))
    (ok none)
  )
)

;; Get owner
(define-read-only (get-owner (token-id uint))
  (ok (nft-get-owner? credential token-id))
)

;; Transfer
(define-public (transfer (token-id uint) (sender principal) (recipient principal))
  (let (
    (cred (unwrap! (map-get? credentials { token-id: token-id }) ERR_NOT_FOUND))
  )
    ;; Check not soul-bound
    (asserts! (not (get soul-bound cred)) ERR_SOUL_BOUND)
    ;; Check not revoked
    (asserts! (not (get revoked cred)) ERR_REVOKED)
    ;; Check ownership
    (asserts! (is-eq tx-sender sender) ERR_NOT_OWNER)
    ;; Transfer NFT
    (try! (nft-transfer? credential token-id sender recipient))
    ;; Update holder in metadata
    (map-set credentials
      { token-id: token-id }
      (merge cred { holder: recipient })
    )
    (ok true)
  )
)

;; ============================================
;; Issuer Functions
;; ============================================

;; Register as issuer
(define-public (register-issuer 
  (name (string-ascii 100))
  (description (string-ascii 256))
  (website (string-ascii 100)))
  (let (
    (issuer tx-sender)
  )
    (asserts! (is-none (map-get? issuers { issuer: issuer })) ERR_ALREADY_EXISTS)
    (map-set issuers
      { issuer: issuer }
      {
        name: name,
        description: description,
        website: website,
        verified: false,
        total-issued: u0,
        registered-at: stacks-block-height
      }
    )
    (ok issuer)
  )
)

;; Issue a credential
(define-public (issue-credential
  (recipient principal)
  (title (string-ascii 100))
  (metadata-uri (string-ascii 256))
  (credential-type (string-ascii 50))
  (soul-bound bool))
  (let (
    (issuer tx-sender)
    (issuer-data (unwrap! (map-get? issuers { issuer: issuer }) ERR_NOT_ISSUER))
    (token-id (+ (var-get token-counter) u1))
  )
    ;; Validate recipient
    (asserts! (not (is-eq issuer recipient)) ERR_INVALID_RECIPIENT)
    
    ;; Mint NFT
    (try! (nft-mint? credential token-id recipient))
    
    ;; Store metadata
    (map-set credentials
      { token-id: token-id }
      {
        issuer: issuer,
        holder: recipient,
        title: title,
        metadata-uri: metadata-uri,
        issued-at: stacks-block-height,
        soul-bound: soul-bound,
        revoked: false,
        revoked-at: u0,
        credential-type: credential-type
      }
    )
    
    ;; Update issuer stats
    (map-set issuers
      { issuer: issuer }
      (merge issuer-data {
        total-issued: (+ (get total-issued issuer-data) u1)
      })
    )
    
    ;; Update token counter
    (var-set token-counter token-id)
    
    (ok { token-id: token-id, recipient: recipient, issuer: issuer })
  )
)

;; Revoke a credential
(define-public (revoke-credential (token-id uint))
  (let (
    (cred (unwrap! (map-get? credentials { token-id: token-id }) ERR_NOT_FOUND))
    (issuer (get issuer cred))
  )
    ;; Only issuer can revoke
    (asserts! (is-eq tx-sender issuer) ERR_NOT_AUTHORIZED)
    ;; Check not already revoked
    (asserts! (not (get revoked cred)) ERR_REVOKED)
    
    ;; Mark as revoked
    (map-set credentials
      { token-id: token-id }
      (merge cred {
        revoked: true,
        revoked-at: stacks-block-height
      })
    )
    
    (ok token-id)
  )
)

;; ============================================
;; Read-Only Functions
;; ============================================

;; Get credential details
(define-read-only (get-credential (token-id uint))
  (map-get? credentials { token-id: token-id })
)

;; Verify credential (main verification function)
(define-read-only (verify-credential (token-id uint))
  (match (map-get? credentials { token-id: token-id })
    cred
    (ok {
      valid: (not (get revoked cred)),
      issuer: (get issuer cred),
      holder: (get holder cred),
      title: (get title cred),
      issued-at: (get issued-at cred),
      revoked: (get revoked cred),
      soul-bound: (get soul-bound cred)
    })
    ERR_NOT_FOUND
  )
)

;; Check if credential is valid (not revoked)
(define-read-only (is-valid-credential (token-id uint))
  (match (map-get? credentials { token-id: token-id })
    cred (not (get revoked cred))
    false
  )
)

;; Get issuer info
(define-read-only (get-issuer (issuer principal))
  (map-get? issuers { issuer: issuer })
)

;; Check if address is registered issuer
(define-read-only (is-issuer (address principal))
  (is-some (map-get? issuers { issuer: address }))
)

;; Get total credentials issued
(define-read-only (get-total-credentials)
  (var-get token-counter)
)

;; Check if credential is soul-bound
(define-read-only (is-soul-bound (token-id uint))
  (match (map-get? credentials { token-id: token-id })
    cred (get soul-bound cred)
    false
  )
)

;; ============================================
;; Admin Functions
;; ============================================

;; Verify an issuer (admin only)
(define-public (verify-issuer (issuer principal))
  (let (
    (issuer-data (unwrap! (map-get? issuers { issuer: issuer }) ERR_NOT_FOUND))
  )
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (map-set issuers
      { issuer: issuer }
      (merge issuer-data { verified: true })
    )
    (ok issuer)
  )
)

;; Update contract URI
(define-public (set-contract-uri (new-uri (string-ascii 256)))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (var-set contract-uri new-uri)
    (ok new-uri)
  )
)

