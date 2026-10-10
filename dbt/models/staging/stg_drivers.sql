with source as (

    select 
        driver_id,
        city_id,
        vehicle_id,
        driver_status,
        rating,
        onboarding_date,
        created_at,
        updated_at,
        _airbyte_extracted_at
    from {{ source('beejanride_raw', 'drivers_raw') }}

),

deduplicated as (

    select
        driver_id,
        city_id,
        vehicle_id,
        driver_status,
        rating,
        onboarding_date,
        created_at,
        updated_at,
        _airbyte_extracted_at
    from source
    where driver_id is not null

    qualify row_number() over (
        partition by driver_id
        order by updated_at desc, _airbyte_extracted_at desc
    ) = 1

),

renamed as (

    select
        -- Primary and foreign keys
        cast(driver_id as int64) as driver_id,
        cast(city_id as int64) as city_id,

        -- Driver attributes
        trim(cast(vehicle_id as string)) as vehicle_id,
        lower(trim(cast(driver_status as string))) as driver_status,

        -- Driver performance
        cast(rating as numeric) as rating,

        -- Driver lifecycle dates
        cast(onboarding_date as date) as onboarding_date,
        cast(created_at as timestamp) as created_at,
        cast(updated_at as timestamp) as updated_at,

        -- Airbyte ingestion metadata
        cast(_airbyte_extracted_at as timestamp) as ingested_at

    from deduplicated

)

select driver_id,
       city_id,
       vehicle_id,
       driver_status,
       rating,
       onboarding_date,
       created_at,
       updated_at,
       ingested_at
from renamed
