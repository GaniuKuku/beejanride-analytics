with source as (

    select *
    from {{ source('beejanride_raw', 'cities_raw') }}

),

deduplicated as (

    select
        *
    from source
    where city_id is not null

    qualify row_number() over (
        partition by city_id
        order by _airbyte_extracted_at desc
    ) = 1

),

renamed as (

    select
        -- Primary key
        cast(city_id as int64) as city_id,

        -- City attributes
        lower(trim(cast(country as string))) as country,
        trim(cast(city_name as string)) as city_name,

        -- Business date
        cast(launch_date as date) as launch_date,

        -- Airbyte ingestion metadata
        cast(_airbyte_extracted_at as timestamp) as ingested_at

    from deduplicated

)

select *
from renamed
