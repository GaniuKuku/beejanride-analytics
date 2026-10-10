with trips as (

    select 
        trip_id,
        rider_id,
        driver_id,
        city_id,
        vehicle_id,
        trip_status,
        payment_method,
        actual_fare_amount,
        estimated_fare_amount,
        surge_multiplier,
        is_corporate_trip,
        requested_at,
        picked_up_at,
        dropped_off_at,
        created_at,
        updated_at,

        ingested_at
    from {{ ref('stg_trips') }}

),

payments as (

    select 
        trip_id,
        successful_payment_amount,
        successful_payment_fee,
        failed_payment_count,
        multiple_payment_attempts_flag,
        duplicate_successful_payment_flag
        
    from {{ ref('int_payments') }}

),

trip_enriched as (

    select
        trips.trip_id,
        trips.rider_id,
        trips.driver_id,
        trips.city_id,
        trips.vehicle_id,
        trips.trip_status,
        trips.payment_method,
        trips.actual_fare_amount,
        trips.estimated_fare_amount,
        trips.surge_multiplier,
        trips.is_corporate_trip as corporate_trip_flag,
        trips.requested_at,
        trips.picked_up_at,
        trips.dropped_off_at,
        trips.created_at,
        trips.updated_at,
        trips.ingested_at,

        -- Trip duration
        case
            when trips.picked_up_at is not null
                and trips.dropped_off_at is not null
                and trips.dropped_off_at >= trips.picked_up_at
            then timestamp_diff(
                trips.dropped_off_at,
                trips.picked_up_at,
                minute
            )
            else null
        end as trip_duration_minutes,

        -- Successful payment metrics
        coalesce(payments.successful_payment_amount, 0)
            as successful_payment_amount,

        coalesce(payments.successful_payment_fee, 0)
            as successful_payment_fee,

        coalesce(payments.failed_payment_count, 0)
            as failed_payment_count,

        coalesce(payments.multiple_payment_attempts_flag, false)
            as multiple_payment_attempts_flag,

        coalesce(payments.duplicate_successful_payment_flag, false)
            as duplicate_successful_payment_flag

    from trips

    left join payments
        on trips.trip_id = payments.trip_id

)

select
    trip_id,
    rider_id,
    driver_id,
    city_id,
    vehicle_id,
    trip_status,
    payment_method,
    actual_fare_amount,
    estimated_fare_amount,
    surge_multiplier,
    corporate_trip_flag,
    requested_at,
    picked_up_at,
    dropped_off_at,
    created_at,
    updated_at,
    ingested_at,
    trip_duration_minutes,
    successful_payment_amount,
    successful_payment_fee,
    failed_payment_count,
    multiple_payment_attempts_flag,
    duplicate_successful_payment_flag,

    -- Net revenue from successfully cleared payments
    {{ calculate_net_revenue(
        'successful_payment_amount',
        'successful_payment_fee'
    ) }} as net_revenue,

    -- Completed trip with at least one failed payment attempt
    (
        trip_status = 'completed'
        and failed_payment_count > 0
    ) as failed_payment_on_completed_trip,

    -- Extreme surge indicator
    (
        surge_multiplier > 10
    ) as extreme_surge_flag

from trip_enriched
