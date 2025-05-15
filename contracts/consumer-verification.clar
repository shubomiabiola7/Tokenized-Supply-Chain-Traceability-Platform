;; Consumer Verification Contract
;; Enables product history confirmation

;; Map to track products
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

;; Map to track product owners
(define-map product-owners uint principal)

;; Map to track event counts
(define-map event-counts uint uint)

;; Map to track certification counts
(define-map certification-counts uint uint)

;; Admin functions to manage data
(define-data-var admin principal tx-sender)

(define-public (register-product-data
                (product-id uint)
                (manufacturer principal)
                (name (string-ascii 50))
                (description (string-utf8 500))
                (sku (string-ascii 20))
                (batch-id (string-ascii 20))
                (manufacturing-date uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (map-set products product-id {
      manufacturer: manufacturer,
      name: name,
      description: description,
      sku: sku,
      batch-id: batch-id,
      manufacturing-date: manufacturing-date,
      registration-time: block-height
    })
    (ok true)
  )
)

(define-public (register-product-owner (product-id uint) (owner principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (map-set product-owners product-id owner)
    (ok true)
  )
)

(define-public (register-event-count (product-id uint) (count uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (map-set event-counts product-id count)
    (ok true)
  )
)

(define-public (register-certification-count (product-id uint) (count uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (map-set certification-counts product-id count)
    (ok true)
  )
)

(define-read-only (verify-product-authenticity (product-id uint))
  (let
    (
      (product (map-get? products product-id))
      (owner (map-get? product-owners product-id))
    )
    ;; Check if product exists
    (asserts! (is-some product) (err u404))

    ;; Return product information and current owner
    (ok {
      product-info: (unwrap-panic product),
      current-owner: owner
    })
  )
)

(define-read-only (get-product-history (product-id uint))
  (let
    (
      (product (map-get? products product-id))
      (event-count (default-to u0 (map-get? event-counts product-id)))
      (certification-count (default-to u0 (map-get? certification-counts product-id)))
    )
    ;; Check if product exists
    (asserts! (is-some product) (err u404))

    (ok {
      product-id: product-id,
      event-count: event-count,
      certification-count: certification-count
    })
  )
)

(define-read-only (get-product-events (product-id uint) (limit uint) (offset uint))
  (let
    (
      (product (map-get? products product-id))
      (event-count (default-to u0 (map-get? event-counts product-id)))
    )
    ;; Check if product exists
    (asserts! (is-some product) (err u404))

    ;; Return a list of events (simplified for clarity)
    ;; In a real implementation, you would iterate through events
    (ok {
      product-id: product-id,
      total-events: event-count,
      limit: limit,
      offset: offset
    })
  )
)

(define-read-only (get-product-certifications (product-id uint) (limit uint) (offset uint))
  (let
    (
      (product (map-get? products product-id))
      (certification-count (default-to u0 (map-get? certification-counts product-id)))
    )
    ;; Check if product exists
    (asserts! (is-some product) (err u404))

    ;; Return a list of certifications (simplified for clarity)
    ;; In a real implementation, you would iterate through certifications
    (ok {
      product-id: product-id,
      total-certifications: certification-count,
      limit: limit,
      offset: offset
    })
  )
)
