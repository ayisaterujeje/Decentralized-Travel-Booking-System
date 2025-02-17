;; Accommodation Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-booked (err u102))
(define-constant err-unauthorized (err u103))

;; Data Variables
(define-data-var listing-nonce uint u0)
(define-data-var booking-nonce uint u0)

;; Data Maps
(define-map listings
  { listing-id: uint }
  {
    owner: principal,
    name: (string-ascii 100),
    location: (string-ascii 100),
    price: uint,
    available: bool
  }
)

(define-map bookings
  { booking-id: uint }
  {
    listing-id: uint,
    guest: principal,
    check-in: uint,
    check-out: uint
  }
)

;; Public Functions

;; Create a new listing
(define-public (create-listing (name (string-ascii 100)) (location (string-ascii 100)) (price uint))
  (let
    (
      (listing-id (var-get listing-nonce))
    )
    (map-set listings
      { listing-id: listing-id }
      {
        owner: tx-sender,
        name: name,
        location: location,
        price: price,
        available: true
      }
    )
    (var-set listing-nonce (+ listing-id u1))
    (ok listing-id)
  )
)

;; Book an accommodation
(define-public (book-accommodation (listing-id uint) (check-in uint) (check-out uint))
  (let
    (
      (listing (unwrap! (map-get? listings { listing-id: listing-id }) err-not-found))
      (booking-id (var-get booking-nonce))
    )
    (asserts! (get available listing) err-already-booked)
    (try! (stx-transfer? (* (get price listing) (- check-out check-in)) tx-sender (get owner listing)))
    (map-set bookings
      { booking-id: booking-id }
      {
        listing-id: listing-id,
        guest: tx-sender,
        check-in: check-in,
        check-out: check-out
      }
    )
    (map-set listings
      { listing-id: listing-id }
      (merge listing { available: false })
    )
    (var-set booking-nonce (+ booking-id u1))
    (ok booking-id)
  )
)

;; Cancel a booking
(define-public (cancel-booking (booking-id uint))
  (let
    (
      (booking (unwrap! (map-get? bookings { booking-id: booking-id }) err-not-found))
      (listing (unwrap! (map-get? listings { listing-id: (get listing-id booking) }) err-not-found))
    )
    (asserts! (or (is-eq tx-sender (get guest booking)) (is-eq tx-sender (get owner listing))) err-unauthorized)
    (try! (as-contract (stx-transfer? (* (get price listing) (- (get check-out booking) (get check-in booking))) tx-sender (get guest booking))))
    (map-delete bookings { booking-id: booking-id })
    (map-set listings
      { listing-id: (get listing-id booking) }
      (merge listing { available: true })
    )
    (ok true)
  )
)

;; Read-only Functions

;; Get listing details
(define-read-only (get-listing (listing-id uint))
  (ok (unwrap! (map-get? listings { listing-id: listing-id }) err-not-found))
)

;; Get booking details
(define-read-only (get-booking (booking-id uint))
  (ok (unwrap! (map-get? bookings { booking-id: booking-id }) err-not-found))
)

;; Initialize contract
(begin
  (var-set listing-nonce u0)
  (var-set booking-nonce u0)
)

