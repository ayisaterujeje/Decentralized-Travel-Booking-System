;; Loyalty Program Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-insufficient-points (err u103))

;; Data Maps
(define-map user-points
  { user: principal }
  { points: uint }
)

(define-map rewards
  { reward-id: uint }
  {
    name: (string-ascii 100),
    description: (string-utf8 500),
    points-required: uint
  }
)

;; Data Variables
(define-data-var reward-nonce uint u0)

;; Public Functions

;; Add points to a user
(define-public (add-points (user principal) (points uint))
  (let
    (
      (current-points (default-to { points: u0 } (map-get? user-points { user: user })))
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set user-points
      { user: user }
      { points: (+ (get points current-points) points) }
    )
    (ok true)
  )
)

;; Redeem points for a reward
(define-public (redeem-reward (reward-id uint))
  (let
    (
      (reward (unwrap! (map-get? rewards { reward-id: reward-id }) err-not-found))
      (user-point-data (unwrap! (map-get? user-points { user: tx-sender }) err-not-found))
    )
    (asserts! (>= (get points user-point-data) (get points-required reward)) err-insufficient-points)
    (map-set user-points
      { user: tx-sender }
      { points: (- (get points user-point-data) (get points-required reward)) }
    )
    (ok true)
  )
)

;; Add a new reward
(define-public (add-reward (name (string-ascii 100)) (description (string-utf8 500)) (points-required uint))
  (let
    (
      (reward-id (var-get reward-nonce))
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set rewards
      { reward-id: reward-id }
      {
        name: name,
        description: description,
        points-required: points-required
      }
    )
    (var-set reward-nonce (+ reward-id u1))
    (ok reward-id)
  )
)

;; Read-only Functions

;; Get user points
(define-read-only (get-user-points (user principal))
  (ok (default-to { points: u0 } (map-get? user-points { user: user })))
)

;; Get reward details
(define-read-only (get-reward (reward-id uint))
  (ok (unwrap! (map-get? rewards { reward-id: reward-id }) err-not-found))
)

;; Initialize contract
(begin
  (var-set reward-nonce u0)
)

