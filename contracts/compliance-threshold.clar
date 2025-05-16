;; compliance-threshold.clar
;; Establishes regulatory limits for environmental metrics

(define-data-var admin principal tx-sender)

;; Threshold data structure
(define-map thresholds
  {
    metric-type: (string-ascii 32),
    facility-type: (string-ascii 32)
  }
  {
    max-value: uint,
    updated-at: uint,
    updated-by: principal
  }
)

;; Set a new threshold
(define-public (set-threshold (metric-type (string-ascii 32)) (facility-type (string-ascii 32)) (max-value uint))
  (let
    ((caller tx-sender))
    (if (is-eq caller (var-get admin))
        (begin
          (map-set thresholds
            {
              metric-type: metric-type,
              facility-type: facility-type
            }
            {
              max-value: max-value,
              updated-at: block-height,
              updated-by: caller
            }
          )
          (ok true)
        )
        (err u3) ;; Not authorized
    )
  )
)

;; Get threshold information
(define-read-only (get-threshold (metric-type (string-ascii 32)) (facility-type (string-ascii 32)))
  (map-get? thresholds { metric-type: metric-type, facility-type: facility-type })
)

;; Check if a value exceeds threshold
(define-read-only (exceeds-threshold (metric-type (string-ascii 32)) (facility-type (string-ascii 32)) (value uint))
  (match (map-get? thresholds { metric-type: metric-type, facility-type: facility-type })
    threshold (> value (get max-value threshold))
    false ;; No threshold set, assume compliance
  )
)

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (let
    ((caller tx-sender))
    (if (is-eq caller (var-get admin))
        (begin
          (var-set admin new-admin)
          (ok true)
        )
        (err u3) ;; Not authorized
    )
  )
)
