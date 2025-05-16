;; reporting.clar
;; Generates authenticated environmental disclosures

(define-data-var admin principal tx-sender)
(define-data-var report-counter uint u0)

;; Report data structure
(define-map reports
  { report-id: uint }
  {
    facility-id: (string-ascii 32),
    period-start: uint,
    period-end: uint,
    metrics-hash: (buff 32), ;; Hash of all metrics included in report
    timestamp: uint,
    generated-by: principal,
    verified: bool,
    verified-by: (optional principal),
    verification-timestamp: (optional uint)
  }
)

;; Generate a new report
(define-public (generate-report (facility-id (string-ascii 32)) (period-start uint) (period-end uint) (metrics-hash (buff 32)))
  (let
    ((caller tx-sender)
     (report-id (var-get report-counter)))
    (var-set report-counter (+ report-id u1))
    (map-set reports
      { report-id: report-id }
      {
        facility-id: facility-id,
        period-start: period-start,
        period-end: period-end,
        metrics-hash: metrics-hash,
        timestamp: block-height,
        generated-by: caller,
        verified: false,
        verified-by: none,
        verification-timestamp: none
      }
    )
    (ok report-id)
  )
)

;; Verify a report (admin only)
(define-public (verify-report (report-id uint))
  (let
    ((caller tx-sender))
    (if (is-eq caller (var-get admin))
        (match (map-get? reports { report-id: report-id })
          report (begin
            (map-set reports
              { report-id: report-id }
              (merge report {
                verified: true,
                verified-by: (some caller),
                verification-timestamp: (some block-height)
              })
            )
            (ok true)
          )
          (err u2) ;; Report not found
        )
        (err u3) ;; Not authorized
    )
  )
)

;; Get report information
(define-read-only (get-report (report-id uint))
  (map-get? reports { report-id: report-id })
)

;; Check if report is verified
(define-read-only (is-report-verified (report-id uint))
  (match (map-get? reports { report-id: report-id })
    report (get verified report)
    false
  )
)

;; Get total reports count
(define-read-only (get-reports-count)
  (var-get report-counter)
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
