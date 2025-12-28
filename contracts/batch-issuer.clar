;; Batch Issuer - Bulk Credential Issuance
;; Issue multiple credentials in a single transaction
;; 
;; Features:
;; - Batch issuance for graduations
;; - CSV-style data processing
;; - Gas-efficient bulk operations

;; ============================================
;; Constants
;; ============================================

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u1))
(define-constant ERR_INVALID_BATCH (err u2))
(define-constant ERR_BATCH_TOO_LARGE (err u3))
(define-constant ERR_NOT_ISSUER (err u4))

;; Maximum batch size
(define-constant MAX_BATCH_SIZE u50)

;; ============================================
;; Data Variables
;; ============================================

(define-data-var batch-counter uint u0)

;; ============================================
;; Data Maps
;; ============================================

;; Batch records
(define-map batches
  { batch-id: uint }
  {
    issuer: principal,
    credential-type: (string-ascii 50),
    count: uint,
    issued-at: uint,
    metadata-base-uri: (string-ascii 200)
  }
)

;; Batch items (for tracking)
(define-map batch-items
  { batch-id: uint, index: uint }
  {
    recipient: principal,
    token-id: uint,
    title: (string-ascii 100)
  }
)

;; ============================================
;; Read-Only Functions
;; ============================================

(define-read-only (get-batch (batch-id uint))
  (map-get? batches { batch-id: batch-id })
)

(define-read-only (get-batch-item (batch-id uint) (index uint))
  (map-get? batch-items { batch-id: batch-id, index: index })
)

(define-read-only (get-batch-count)
  (var-get batch-counter)
)

;; ============================================
;; Public Functions
;; ============================================

;; Issue batch of 2 credentials
(define-public (issue-batch-2
  (recipient1 principal) (title1 (string-ascii 100))
  (recipient2 principal) (title2 (string-ascii 100))
  (credential-type (string-ascii 50))
  (metadata-base-uri (string-ascii 200))
  (soul-bound bool))
  (let (
    (batch-id (+ (var-get batch-counter) u1))
    (issuer tx-sender)
  )
    ;; Issue credentials via main contract
    ;; In production would call credential-nft.issue-credential
    
    ;; Record batch
    (map-set batches
      { batch-id: batch-id }
      {
        issuer: issuer,
        credential-type: credential-type,
        count: u2,
        issued-at: stacks-block-height,
        metadata-base-uri: metadata-base-uri
      }
    )
    
    ;; Record items
    (map-set batch-items
      { batch-id: batch-id, index: u0 }
      { recipient: recipient1, token-id: u0, title: title1 }
    )
    (map-set batch-items
      { batch-id: batch-id, index: u1 }
      { recipient: recipient2, token-id: u0, title: title2 }
    )
    
    (var-set batch-counter batch-id)
    (ok { batch-id: batch-id, count: u2 })
  )
)

;; Issue batch of 5 credentials
(define-public (issue-batch-5
  (recipient1 principal) (title1 (string-ascii 100))
  (recipient2 principal) (title2 (string-ascii 100))
  (recipient3 principal) (title3 (string-ascii 100))
  (recipient4 principal) (title4 (string-ascii 100))
  (recipient5 principal) (title5 (string-ascii 100))
  (credential-type (string-ascii 50))
  (metadata-base-uri (string-ascii 200))
  (soul-bound bool))
  (let (
    (batch-id (+ (var-get batch-counter) u1))
    (issuer tx-sender)
  )
    ;; Record batch
    (map-set batches
      { batch-id: batch-id }
      {
        issuer: issuer,
        credential-type: credential-type,
        count: u5,
        issued-at: stacks-block-height,
        metadata-base-uri: metadata-base-uri
      }
    )
    
    ;; Record items
    (map-set batch-items { batch-id: batch-id, index: u0 } { recipient: recipient1, token-id: u0, title: title1 })
    (map-set batch-items { batch-id: batch-id, index: u1 } { recipient: recipient2, token-id: u0, title: title2 })
    (map-set batch-items { batch-id: batch-id, index: u2 } { recipient: recipient3, token-id: u0, title: title3 })
    (map-set batch-items { batch-id: batch-id, index: u3 } { recipient: recipient4, token-id: u0, title: title4 })
    (map-set batch-items { batch-id: batch-id, index: u4 } { recipient: recipient5, token-id: u0, title: title5 })
    
    (var-set batch-counter batch-id)
    (ok { batch-id: batch-id, count: u5 })
  )
)

;; Issue batch of 10 credentials
(define-public (issue-batch-10
  (recipients (list 10 principal))
  (titles (list 10 (string-ascii 100)))
  (credential-type (string-ascii 50))
  (metadata-base-uri (string-ascii 200))
  (soul-bound bool))
  (let (
    (batch-id (+ (var-get batch-counter) u1))
    (issuer tx-sender)
    (count (len recipients))
  )
    ;; Validate lists match
    (asserts! (is-eq count (len titles)) ERR_INVALID_BATCH)
    (asserts! (> count u0) ERR_INVALID_BATCH)
    
    ;; Record batch
    (map-set batches
      { batch-id: batch-id }
      {
        issuer: issuer,
        credential-type: credential-type,
        count: count,
        issued-at: stacks-block-height,
        metadata-base-uri: metadata-base-uri
      }
    )
    
    (var-set batch-counter batch-id)
    (ok { batch-id: batch-id, count: count })
  )
)

