with source as (

    select 
        trip_id,
        rider_id,
        driver_id,
        city_id,
        vehicle_id,
        status,
        payment_method,
        actual_fare,
        estimated_fare,
        surge_multiplier,
        is_corporate,
        requested_at,
        pickup_at,
        dropoff_at,
        created_at,
        updated_at,
        _airbyte_extracted_at
    from {{ source('beejanride_raw', 'trips_raw') }}

),

deduplicated as (

    select
        trip_id,
        rider_id,
        driver_id,
        city_id,
        vehicle_id,
        status,
        payment_method,
        actual_fare,
        estimated_fare,
        surge_multiplier,
        is_corporate,
        requested_at,
        pickup_at,
        dropoff_at,
        created_at,
        updated_at,
        _airbyte_extracted_at
    from source
    where trip_id is not null

    qualify row_number() over (
        partition by trip_id
        order by updated_at desc, _airbyte_extracted_at desc
    ) = 1

),

renamed as (

    select
        -- Primary and foreign keys
        cast(trip_id as int64) as trip_id,
        cast(rider_id as int64) as rider_id,
        cast(driver_id as int64) as driver_id,
        cast(city_id as int64) as city_id,
        cast(vehicle_id as string) as vehicle_id,

        -- Trip status and payment method
        lower(trim(cast(status as string))) as trip_status,
        lower(trim(cast(payment_method as string))) as payment_method,

        -- Financial metrics
        cast(actual_fare as numeric) as actual_fare_amount,
        cast(estimated_fare as numeric) as estimated_fare_amount,
        cast(surge_multiplier as numeric) as surge_multiplier,

        -- Corporate trip flag
        cast(is_corporate as boolean) as is_corporate_trip,

        -- Standardized timestamps
        cast(requested_at as timestamp) as requested_at,
        cast(pickup_at as timestamp) as picked_up_at,
        cast(dropoff_at as timestamp) as dropped_off_at,
        cast(created_at as timestamp) as created_at,
        cast(updated_at as timestamp) as updated_at,

        -- Airbyte ingestion metadata
        cast(_airbyte_extracted_at as timestamp) as ingested_at

    from deduplicated

)

select trip_id,
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
from renamed

