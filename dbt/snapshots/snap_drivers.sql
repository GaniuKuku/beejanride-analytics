{% snapshot snap_drivers %}

{{
    config(
        target_schema='beejanride_snapshots',
        unique_key='driver_id',
        strategy='check',
        check_cols=[
            'driver_status',
            'vehicle_id',
            'rating'
        ]
    )
}}

select
    driver_id,
    city_id,
    vehicle_id,
    driver_status,
    rating,
    onboarding_date,
    created_at,
    updated_at,
    ingested_at

from {{ ref('stg_drivers') }}

{% endsnapshot %}
