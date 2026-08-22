with riders as (

    select *
    from {{ ref('stg_riders') }}

),

rider_value as (

    select
        rider_id,
        sum(net_revenue) as rider_lifetime_value

    from {{ ref('int_trips') }}

    where trip_status = 'completed'
      and rider_id is not null

    group by rider_id

)

select
    riders.rider_id,
    riders.referral_code,
    riders.signup_date,

    coalesce(
        rider_value.rider_lifetime_value,
        0
    ) as rider_lifetime_value

from riders

left join rider_value
    on riders.rider_id = rider_value.rider_id
