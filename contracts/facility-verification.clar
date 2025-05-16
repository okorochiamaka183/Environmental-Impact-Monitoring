;; facility-verification.clar
;; Validates industrial sites and maintains their verification status

(define-data-var admin principal tx-sender)

;; Facility data structure
(define-map facilities
  { facility-id: (string-ascii 32) }
  {
    owner: principal,
    name: (string-ascii 100),
    location: (string-ascii 100),
    verified: bool,
    registration-date: uint
  }
)

;; Register a new facility
(define-public (register-facility (facility-id (string-ascii 32)) (name (string-ascii 100)) (location (string-ascii 100)))
  (let
    ((caller tx-sender))
    (if (map-insert facilities { facility-id: facility-id }
                   {
                     owner: caller,
                     name: name,
                     location: location,
                     verified: false,
                     registration-date: block-height
                   })
        (ok true)
        (err u1) ;; Facility ID already exists
    )
  )
)

;; Verify a facility (admin only)
(define-public (verify-facility (facility-id (string-ascii 32)))
  (let
    ((caller tx-sender))
    (if (is-eq caller (var-get admin))
        (match (map-get? facilities { facility-id: facility-id })
          facility (begin
            (map-set facilities
              { facility-id: facility-id }
              (merge facility { verified: true })
            )
            (ok true)
          )
          (err u2) ;; Facility not found
        )
        (err u3) ;; Not authorized
    )
  )
)

;; Update facility information (owner only)
(define-public (update-facility-info (facility-id (string-ascii 32)) (name (string-ascii 100)) (location (string-ascii 100)))
  (let
    ((caller tx-sender))
    (match (map-get? facilities { facility-id: facility-id })
      facility (if (is-eq caller (get owner facility))
                  (begin
                    (map-set facilities
                      { facility-id: facility-id }
                      (merge facility { name: name, location: location })
                    )
                    (ok true)
                  )
                  (err u3) ;; Not authorized
      )
      (err u2) ;; Facility not found
    )
  )
)

;; Get facility information
(define-read-only (get-facility (facility-id (string-ascii 32)))
  (map-get? facilities { facility-id: facility-id })
)

;; Check if a facility is verified
(define-read-only (is-facility-verified (facility-id (string-ascii 32)))
  (match (map-get? facilities { facility-id: facility-id })
    facility (get verified facility)
    false
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
