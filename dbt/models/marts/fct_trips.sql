-- depends_on: {{ ref('stg_payments') }}

{{ config(
    materialized='incremental',
    unique_key='trip_id',
    incremental_strategy='merge'
) }}

with trips as (

    select *
    from {{ ref('int_trips') }}

    {% if is_incremental() %}

    where trip_id in (

        -- Trips updated recently
        select trip_id
        from {{ ref('int_trips') }}
        where updated_at >= timestamp_sub(
            (select max(updated_at) from {{ this }}),
            interval 24 hour
        )

        union distinct

        -- Trips affected by recent payment activity
        select trip_id
        from {{ ref('stg_payments') }}
        where created_at >= timestamp_sub(
            (select max(updated_at) from {{ this }}),
            interval 24 hour
        )

    )

    {% endif %}

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
