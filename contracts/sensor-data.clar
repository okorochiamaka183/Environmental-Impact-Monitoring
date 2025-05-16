;; sensor-data.clar
;; Records emissions and environmental metrics from sensors

(define-data-var admin principal tx-sender)

;; Sensor data structure
(define-map sensors
  { sensor-id: (string-ascii 32) }
  {
    facility-id: (string-ascii 32),
    sensor-type: (string-ascii 32),
    active: bool,
    registration-date: uint
  }
)

;; Sensor readings storage
(define-map sensor-readings
  {
    sensor-id: (string-ascii 32),
    timestamp: uint
  }
  {
    metric-type: (string-ascii 32),
    value: uint,
    submitter: principal
  }
)

;; Register a new sensor
(define-public (register-sensor (sensor-id (string-ascii 32)) (facility-id (string-ascii 32)) (sensor-type (string-ascii 32)))
  (let
    ((caller tx-sender))
    (if (map-insert sensors { sensor-id: sensor-id }
                   {
                     facility-id: facility-id,
                     sensor-type: sensor-type,
                     active: true,
                     registration-date: block-height
                   })
        (ok true)
        (err u1) ;; Sensor ID already exists
    )
  )
)

;; Submit sensor data
(define-public (submit-sensor-data (sensor-id (string-ascii 32)) (metric-type (string-ascii 32)) (value uint))
  (let
    ((caller tx-sender)
     (timestamp block-height))
    (match (map-get? sensors { sensor-id: sensor-id })
      sensor (if (get active sensor)
                (begin
                  (map-set sensor-readings
                    {
                      sensor-id: sensor-id,
                      timestamp: timestamp
                    }
                    {
                      metric-type: metric-type,
                      value: value,
                      submitter: caller
                    }
                  )
                  (ok true)
                )
                (err u4) ;; Sensor not active
      )
      (err u2) ;; Sensor not found
    )
  )
)

;; Get sensor information
(define-read-only (get-sensor (sensor-id (string-ascii 32)))
  (map-get? sensors { sensor-id: sensor-id })
)

;; Get sensor reading
(define-read-only (get-sensor-reading (sensor-id (string-ascii 32)) (timestamp uint))
  (map-get? sensor-readings { sensor-id: sensor-id, timestamp: timestamp })
)

;; Deactivate a sensor (admin only)
(define-public (deactivate-sensor (sensor-id (string-ascii 32)))
  (let
    ((caller tx-sender))
    (if (is-eq caller (var-get admin))
        (match (map-get? sensors { sensor-id: sensor-id })
          sensor (begin
            (map-set sensors
              { sensor-id: sensor-id }
              (merge sensor { active: false })
            )
            (ok true)
          )
          (err u2) ;; Sensor not found
        )
        (err u3) ;; Not authorized
    )
  )
)

;; Reactivate a sensor (admin only)
(define-public (reactivate-sensor (sensor-id (string-ascii 32)))
  (let
    ((caller tx-sender))
    (if (is-eq caller (var-get admin))
        (match (map-get? sensors { sensor-id: sensor-id })
          sensor (begin
            (map-set sensors
              { sensor-id: sensor-id }
              (merge sensor { active: true })
            )
            (ok true)
          )
          (err u2) ;; Sensor not found
        )
        (err u3) ;; Not authorized
    )
  )
)
