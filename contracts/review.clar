;; Review Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-rating (err u103))

;; Data Variables
(define-data-var review-nonce uint u0)

;; Data Maps
(define-map reviews
  { review-id: uint }
  {
    reviewer: principal,
    service-id: uint,
    service-type: (string-ascii 20),
    rating: uint,
    comment: (string-utf8 500)
  }
)

(define-map service-ratings
  { service-id: uint, service-type: (string-ascii 20) }
  {
    total-rating: uint,
    review-count: uint
  }
)

;; Public Functions

;; Submit a review
(define-public (submit-review (service-id uint) (service-type (string-ascii 20)) (rating uint) (comment (string-utf8 500)))
  (let
    (
      (review-id (var-get review-nonce))
      (current-rating (default-to { total-rating: u0, review-count: u0 } (map-get? service-ratings { service-id: service-id, service-type: service-type })))
    )
    (asserts! (and (>= rating u1) (<= rating u5)) err-invalid-rating)
    (map-set reviews
      { review-id: review-id }
      {
        reviewer: tx-sender,
        service-id: service-id,
        service-type: service-type,
        rating: rating,
        comment: comment
      }
    )
    (map-set service-ratings
      { service-id: service-id, service-type: service-type }
      {
        total-rating: (+ (get total-rating current-rating) rating),
        review-count: (+ (get review-count current-rating) u1)
      }
    )
    (var-set review-nonce (+ review-id u1))
    (ok review-id)
  )
)

;; Read-only Functions

;; Get review details
(define-read-only (get-review (review-id uint))
  (ok (unwrap! (map-get? reviews { review-id: review-id }) err-not-found))
)

;; Get average rating for a service
(define-read-only (get-average-rating (service-id uint) (service-type (string-ascii 20)))
  (let
    (
      (rating-data (unwrap! (map-get? service-ratings { service-id: service-id, service-type: service-type }) err-not-found))
    )
    (ok (/ (get total-rating rating-data) (get review-count rating-data)))
  )
)

;; Initialize contract
(begin
  (var-set review-nonce u0)
)

