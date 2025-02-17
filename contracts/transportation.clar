;; Transportation Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-booked (err u102))
(define-constant err-unauthorized (err u103))

;; Data Variables
(define-data-var transport-nonce uint u0)
(define-data-var booking-nonce uint u0)

;; Data Maps
(define-map transports
  { transport-id: uint }
  {
    provider: principal,
    type: (string-ascii 20),
    origin: (string-ascii 100),
    destination: (string-ascii 100),
    departure-time: uint,
    price: uint,
    available-seats: uint
  }
)

(define-map bookings
  { booking-id: uint }
  {
    transport-id: uint,
    passenger: principal,
    seats: uint
  }
)

;; Public Functions

;; Create a new transport
(define-public (create-transport (type (string-ascii 20)) (origin (string-ascii 100)) (destination (string-ascii 100)) (departure-time uint) (price uint) (seats uint))
  (let
    (
      (transport-id (var-get transport-nonce))
    )
    (map-set transports
      { transport-id: transport-id }
      {
        provider: tx-sender,
        type: type,
        origin: origin,
        destination: destination,
        departure-time: departure-time,
        price: price,
        available-seats: seats
      }
    )
    (var-set transport-nonce (+ transport-id u1))
    (ok transport-id)
  )
)

;; Book a transport
(define-public (book-transport (transport-id uint) (seats uint))
  (let
    (
      (transport (unwrap! (map-get? transports { transport-id: transport-id }) err-not-found))
      (booking-id (var-get booking-nonce))
    )
    (asserts! (>= (get available-seats transport) seats) err-already-booked)
    (try! (stx-transfer? (* (get price transport) seats) tx-sender (get provider transport)))
    (map-set bookings
      { booking-id: booking-id }
      {
        transport-id: transport-id,
        passenger: tx-sender,
        seats: seats
      }
    )
    (map-set transports
      { transport-id: transport-id }
      (merge transport { available-seats: (- (get available-seats transport) seats) })
    )
    (var-set booking-nonce (+ booking-id u1))
    (ok booking-id)
  )
)

;; Cancel a transport booking
(define-public (cancel-transport-booking (booking-id uint))
  (let
    (
      (booking (unwrap! (map-get? bookings { booking-id: booking-id }) err-not-found))
      (transport (unwrap! (map-get? transports { transport-id: (get transport-id booking) }) err-not-found))
    )
    (asserts! (is-eq tx-sender (get passenger booking)) err-unauthorized)
    (try! (as-contract (stx-transfer? (* (get price transport) (get seats booking)) tx-sender (get passenger booking))))
    (map-delete bookings { booking-id: booking-id })
    (map-set transports
      { transport-id: (get transport-id booking) }
      (merge transport { available-seats: (+ (get available-seats transport) (get seats booking)) })
    )
    (ok true)
  )
)

;; Read-only Functions

;; Get transport details
(define-read-only (get-transport (transport-id uint))
  (ok (unwrap! (map-get? transports { transport-id: transport-id }) err-not-found))
)

;; Get booking details
(define-read-only (get-transport-booking (booking-id uint))
  (ok (unwrap! (map-get? bookings { booking-id: booking-id }) err-not-found))
)

;; Initialize contract
(begin
  (var-set transport-nonce u0)
  (var-set booking-nonce u0)
)

