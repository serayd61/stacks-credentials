;; Credential Types Registry
;; Define and manage credential types/templates
;; 
;; Features:
;; - Standard credential types
;; - Custom type creation
;; - Validation rules

;; ============================================
;; Constants
;; ============================================

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u1))
(define-constant ERR_TYPE_EXISTS (err u2))
(define-constant ERR_TYPE_NOT_FOUND (err u3))
(define-constant ERR_INVALID_NAME (err u4))

;; Standard credential types
(define-constant TYPE_ACADEMIC "academic")
(define-constant TYPE_PROFESSIONAL "professional")
(define-constant TYPE_ACHIEVEMENT "achievement")
(define-constant TYPE_MEMBERSHIP "membership")
(define-constant TYPE_CERTIFICATION "certification")

;; ============================================
;; Data Variables
;; ============================================

(define-data-var type-counter uint u0)

;; ============================================
;; Data Maps
;; ============================================

;; Credential type definitions
(define-map credential-types
  { type-id: (string-ascii 50) }
  {
    name: (string-ascii 100),
    description: (string-ascii 256),
    category: (string-ascii 50),
    requires-expiry: bool,
    default-validity-blocks: uint,
    icon-uri: (string-ascii 200),
    schema-uri: (string-ascii 200),
    created-by: principal,
    verified: bool,
    active: bool
  }
)

;; Required fields per type
(define-map type-required-fields
  { type-id: (string-ascii 50) }
  { fields: (list 10 (string-ascii 50)) }
)

;; Issuers authorized for specific types
(define-map type-authorized-issuers
  { type-id: (string-ascii 50), issuer: principal }
  { authorized: bool, authorized-at: uint }
)

;; ============================================
;; Read-Only Functions
;; ============================================

(define-read-only (get-credential-type (type-id (string-ascii 50)))
  (map-get? credential-types { type-id: type-id })
)

(define-read-only (is-valid-type (type-id (string-ascii 50)))
  (match (map-get? credential-types { type-id: type-id })
    type-data (get active type-data)
    false
  )
)

(define-read-only (get-required-fields (type-id (string-ascii 50)))
  (map-get? type-required-fields { type-id: type-id })
)

(define-read-only (is-authorized-for-type (type-id (string-ascii 50)) (issuer principal))
  (match (map-get? type-authorized-issuers { type-id: type-id, issuer: issuer })
    auth (get authorized auth)
    false
  )
)

;; ============================================
;; Public Functions
;; ============================================

;; Register a new credential type
(define-public (register-type
  (type-id (string-ascii 50))
  (name (string-ascii 100))
  (description (string-ascii 256))
  (category (string-ascii 50))
  (requires-expiry bool)
  (default-validity-blocks uint)
  (schema-uri (string-ascii 200)))
  (begin
    ;; Check doesn't exist
    (asserts! (is-none (map-get? credential-types { type-id: type-id })) ERR_TYPE_EXISTS)
    
    (map-set credential-types
      { type-id: type-id }
      {
        name: name,
        description: description,
        category: category,
        requires-expiry: requires-expiry,
        default-validity-blocks: default-validity-blocks,
        icon-uri: "",
        schema-uri: schema-uri,
        created-by: tx-sender,
        verified: false,
        active: true
      }
    )
    
    (var-set type-counter (+ (var-get type-counter) u1))
    (ok type-id)
  )
)

;; Set required fields for type
(define-public (set-required-fields
  (type-id (string-ascii 50))
  (fields (list 10 (string-ascii 50))))
  (let (
    (type-data (unwrap! (map-get? credential-types { type-id: type-id }) ERR_TYPE_NOT_FOUND))
  )
    ;; Only creator can modify
    (asserts! (is-eq tx-sender (get created-by type-data)) ERR_NOT_AUTHORIZED)
    
    (map-set type-required-fields
      { type-id: type-id }
      { fields: fields }
    )
    
    (ok type-id)
  )
)

;; Authorize issuer for type
(define-public (authorize-issuer-for-type
  (type-id (string-ascii 50))
  (issuer principal))
  (let (
    (type-data (unwrap! (map-get? credential-types { type-id: type-id }) ERR_TYPE_NOT_FOUND))
  )
    ;; Only creator can authorize
    (asserts! (is-eq tx-sender (get created-by type-data)) ERR_NOT_AUTHORIZED)
    
    (map-set type-authorized-issuers
      { type-id: type-id, issuer: issuer }
      { authorized: true, authorized-at: stacks-block-height }
    )
    
    (ok issuer)
  )
)

;; Deactivate type
(define-public (deactivate-type (type-id (string-ascii 50)))
  (let (
    (type-data (unwrap! (map-get? credential-types { type-id: type-id }) ERR_TYPE_NOT_FOUND))
  )
    (asserts! (is-eq tx-sender (get created-by type-data)) ERR_NOT_AUTHORIZED)
    
    (map-set credential-types
      { type-id: type-id }
      (merge type-data { active: false })
    )
    
    (ok type-id)
  )
)

;; ============================================
;; Admin Functions
;; ============================================

;; Verify a type (admin only)
(define-public (verify-type (type-id (string-ascii 50)))
  (let (
    (type-data (unwrap! (map-get? credential-types { type-id: type-id }) ERR_TYPE_NOT_FOUND))
  )
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    
    (map-set credential-types
      { type-id: type-id }
      (merge type-data { verified: true })
    )
    
    (ok type-id)
  )
)

;; ============================================
;; Initialize Standard Types
;; ============================================

;; Academic credentials
(map-set credential-types
  { type-id: TYPE_ACADEMIC }
  {
    name: "Academic Credential",
    description: "University degrees, diplomas, and academic certificates",
    category: "education",
    requires-expiry: false,
    default-validity-blocks: u0,
    icon-uri: "",
    schema-uri: "",
    created-by: CONTRACT_OWNER,
    verified: true,
    active: true
  }
)

;; Professional licenses
(map-set credential-types
  { type-id: TYPE_PROFESSIONAL }
  {
    name: "Professional License",
    description: "Professional certifications and licenses",
    category: "professional",
    requires-expiry: true,
    default-validity-blocks: u525600, ;; ~1 year
    icon-uri: "",
    schema-uri: "",
    created-by: CONTRACT_OWNER,
    verified: true,
    active: true
  }
)

;; Achievement badges
(map-set credential-types
  { type-id: TYPE_ACHIEVEMENT }
  {
    name: "Achievement Badge",
    description: "Recognition for accomplishments and milestones",
    category: "achievement",
    requires-expiry: false,
    default-validity-blocks: u0,
    icon-uri: "",
    schema-uri: "",
    created-by: CONTRACT_OWNER,
    verified: true,
    active: true
  }
)

;; Memberships
(map-set credential-types
  { type-id: TYPE_MEMBERSHIP }
  {
    name: "Membership Card",
    description: "Organization and community memberships",
    category: "membership",
    requires-expiry: true,
    default-validity-blocks: u525600,
    icon-uri: "",
    schema-uri: "",
    created-by: CONTRACT_OWNER,
    verified: true,
    active: true
  }
)

