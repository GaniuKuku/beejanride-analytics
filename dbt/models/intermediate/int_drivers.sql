with drivers as (

    select *
    from {{ ref('stg_drivers') }}

),

completed_trips as (

    select
        driver_id,
        count(*) as driver_lifetime_trips

    from {{ ref('int_trips') }}

    where trip_status = 'completed'
      and driver_id is not null

    group by driver_id

)

select
    drivers.driver_id,
    drivers.city_id,
    drivers.vehicle_id,
    drivers.driver_status,
    drivers.rating,
    drivers.onboarding_date,
    drivers.created_at,
    drivers.updated_at,
    drivers.ingested_at,

    coalesce(
        completed_trips.driver_lifetime_trips,
        0
    ) as driver_lifetime_trips

from drivers

left join completed_trips
    on drivers.driver_id = completed_trips.driver_id
