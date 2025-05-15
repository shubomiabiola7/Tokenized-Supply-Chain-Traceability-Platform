;; Event Tracking Contract
;; Monitors supply chain milestones

(define-map events
  { product-id: uint, event-id: uint }
  {
    entity: principal,
    event-type: uint, ;; 1=Production, 2=Shipping, 3=Receiving, 4=Quality Check, 5=Retail
    timestamp: uint,
    location: (string-ascii 50),
    notes: (string-utf8 200)
  }
)

(define-map product-event-counts uint uint)

;; Map to track entity types and verification status
(define-map entities principal
  {
    entity-type: uint,
    is-verified: bool
  }
)

;; Map to track product ownership
(define-map product-owners uint principal)

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

(define-public (register-product-owner (product-id uint) (owner principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (map-set product-owners product-id owner)
    (ok true)
  )
)

(define-read-only (get-event (product-id uint) (event-id uint))
  (map-get? events { product-id: product-id, event-id: event-id })
)

(define-read-only (get-event-count (product-id uint))
  (default-to u0 (map-get? product-event-counts product-id))
)

(define-public (record-event
                (product-id uint)
                (event-type uint)
                (location (string-ascii 50))
                (notes (string-utf8 200)))
  (let
    (
      (entity (map-get? entities tx-sender))
      (product-owner (map-get? product-owners product-id))
      (event-count (+ (default-to u0 (map-get? product-event-counts product-id)) u1))
    )
    ;; Check if entity is verified
    (asserts! (is-some entity) (err u404))
    (asserts! (get is-verified (unwrap-panic entity)) (err u403))

    ;; Check if event type is valid
    (asserts! (and (>= event-type u1) (<= event-type u5)) (err u400))

    ;; Check if product exists and entity is authorized
    (asserts! (is-some product-owner) (err u404))
    (asserts! (or
               (is-eq tx-sender (unwrap-panic product-owner))
               (is-eq (get entity-type (unwrap-panic entity)) u4)) ;; Certifiers can add events
              (err u403))

    ;; Record the event
    (map-set events
      { product-id: product-id, event-id: event-count }
      {
        entity: tx-sender,
        event-type: event-type,
        timestamp: block-height,
        location: location,
        notes: notes
      }
    )

    ;; Update event count for product
    (map-set product-event-counts product-id event-count)

    (ok event-count)
  )
)
