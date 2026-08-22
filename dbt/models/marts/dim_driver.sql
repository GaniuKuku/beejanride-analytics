select
    driver_id,
    city_id,
    vehicle_id,
    driver_status,
    rating,
    onboarding_date,
    driver_lifetime_trips
from {{ ref('int_drivers') }}
