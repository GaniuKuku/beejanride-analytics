select
    trips.trip_id,
    trips.trip_status,
    coalesce(payments.successful_payment_count, 0) as successful_payment_count
from {{ ref('stg_trips') }} as trips
left join {{ ref('int_payments') }} as payments
    on trips.trip_id = payments.trip_id
where trips.trip_status = 'completed'
  and coalesce(payments.successful_payment_count, 0) = 0
