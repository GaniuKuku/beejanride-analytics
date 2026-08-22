with trips as (

    select *
    from {{ ref('int_trips') }}

)

select
    -- Trip identifier
    trip_id,

    -- Dimension keys
    rider_id,
    driver_id,
    city_id,

    cast(
        format_date('%Y%m%d', date(requested_at))
        as int64
    ) as date_key,

    -- Operational identifiers / attributes
    vehicle_id,
    trip_status,
    payment_method,

    -- Financial measures
    actual_fare_amount,
    estimated_fare_amount,
    successful_payment_amount,
    successful_payment_fee,
    net_revenue,

    -- Operational measures
    surge_multiplier,
    trip_duration_minutes,

    -- Business segmentation
    corporate_trip_flag,

    -- Payment / fraud indicators
    failed_payment_count,
    multiple_payment_attempts_flag,
    duplicate_successful_payment_flag,
    failed_payment_on_completed_trip,
    extreme_surge_flag,

    -- Event timestamps
    requested_at,
    picked_up_at,
    dropped_off_at,
    created_at,
    updated_at

from trips
