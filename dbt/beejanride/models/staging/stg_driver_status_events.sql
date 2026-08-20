with source as (

    select *
    from {{ source('beejanride_raw', 'driver_status_events_raw') }}

),

deduplicated as (

    select
        *
    from source
    where event_id is not null

    qualify row_number() over (
        partition by event_id
        order by _airbyte_extracted_at desc
    ) = 1

),

renamed as (

    select
        -- Primary and foreign keys
        cast(event_id as int64) as event_id,
        cast(driver_id as int64) as driver_id,

        -- Driver status
        lower(trim(cast(status as string))) as driver_status,

        -- Event timestamp
        cast(event_timestamp as timestamp) as event_timestamp,

        -- Airbyte ingestion metadata
        cast(_airbyte_extracted_at as timestamp) as ingested_at

    from deduplicated

)

select *
from renamed
