;; Product Registration Contract
;; Records item details and specifications

(define-map products uint
  {
    manufacturer: principal,
    name: (string-ascii 50),
    description: (string-utf8 500),
    sku: (string-ascii 20),
    batch-id: (string-ascii 20),
    manufacturing-date: uint,
    registration-time: uint
  }
)

(define-data-var product-count uint u0)

(define-non-fungible-token product-token uint)

;; Map to track entity types and verification status
(define-map entities principal
  {
    entity-type: uint,
    is-verified: bool
  }
)

;; Admin functions to manage entities
(define-data-var admin principal tx-sender)

(define-public (register-entity (entity-principal principal) (entity-type uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (map-set entities entity-principal {
      entity-type: entity-type,
      is-verified: true
    })
    (ok true)
  )
)

(define-read-only (get-product (product-id uint))
  (map-get? products product-id)
)

(define-public (register-product
                (name (string-ascii 50))
                (description (string-utf8 500))
                (sku (string-ascii 20))
                (batch-id (string-ascii 20))
                (manufacturing-date uint))
  (let
    (
      (entity (map-get? entities tx-sender))
      (product-id (+ (var-get product-count) u1))
    )
    ;; Check if entity is a verified manufacturer (type 1)
    (asserts! (is-some entity) (err u404))
    (asserts! (is-eq (get entity-type (unwrap-panic entity)) u1) (err u403))
    (asserts! (get is-verified (unwrap-panic entity)) (err u403))

    ;; Register the product
    (map-set products product-id {
      manufacturer: tx-sender,
      name: name,
      description: description,
      sku: sku,
      batch-id: batch-id,
      manufacturing-date: manufacturing-date,
      registration-time: block-height
    })

    ;; Mint NFT for the product
    (unwrap! (nft-mint? product-token product-id tx-sender) (err u500))

    ;; Update product count
    (var-set product-count product-id)
    (ok product-id)
  )
)

(define-read-only (get-product-owner (product-id uint))
  (nft-get-owner? product-token product-id)
)

(define-public (transfer-product (product-id uint) (recipient principal))
  (let
    (
      (recipient-entity (map-get? entities recipient))
    )
    (asserts! (is-eq (some tx-sender) (nft-get-owner? product-token product-id)) (err u403))
    (asserts! (is-some recipient-entity) (err u404))
    (asserts! (get is-verified (unwrap-panic recipient-entity)) (err u403))

    (unwrap! (nft-transfer? product-token product-id tx-sender recipient) (err u500))
    (ok true)
  )
)
