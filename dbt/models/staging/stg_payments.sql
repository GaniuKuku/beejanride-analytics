with source as (

    select *
    from {{ source('beejanride_raw', 'payments_raw') }}

),

deduplicated as (

    select *
    from source
    where payment_id is not null

    qualify row_number() over (
        partition by payment_id
        order by created_at desc, _airbyte_extracted_at desc
    ) = 1

),

renamed as (

    select

        -- Primary and foreign keys
        cast(payment_id as int64) as payment_id,
        cast(trip_id as int64) as trip_id,

        -- Financial fields
        cast(amount as numeric) as payment_amount,
        cast(fee as numeric) as payment_fee,
        upper(trim(cast(currency as string))) as currency,

        -- Payment attributes
        lower(trim(cast(payment_status as string))) as payment_status,
        lower(trim(cast(payment_provider as string))) as payment_provider,

        -- Timestamp
        cast(created_at as timestamp) as created_at,

        -- Airbyte ingestion metadata
        cast(_airbyte_extracted_at as timestamp) as ingested_at

    from deduplicated

)

select *
from renamed
