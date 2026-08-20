with source as (

    select *
    from {{ source('beejanride_raw', 'riders_raw') }}

),

deduplicated as (

    select
        *
    from source
    where rider_id is not null

    qualify row_number() over (
        partition by rider_id
        order by created_at desc, _airbyte_extracted_at desc
    ) = 1

),

renamed as (

    select
        -- Primary key
        cast(rider_id as int64) as rider_id,

        -- Rider attributes
        lower(trim(cast(country as string))) as country,
        trim(cast(referral_code as string)) as referral_code,

        -- Rider lifecycle dates
        cast(signup_date as date) as signup_date,
        cast(created_at as timestamp) as created_at,

        -- Airbyte ingestion metadata
        cast(_airbyte_extracted_at as timestamp) as ingested_at

    from deduplicated

)

select *
from renamed
