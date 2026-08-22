with date_spine as (

    select
        date_day
    from unnest(
        generate_date_array(
            date '2021-01-01',
            date '2030-12-31',
            interval 1 day
        )
    ) as date_day

)

select
    cast(format_date('%Y%m%d', date_day) as int64) as date_key,
    date_day as date,

    extract(year from date_day) as year,
    extract(quarter from date_day) as quarter,
    extract(month from date_day) as month,

    format_date('%B', date_day) as month_name,

    extract(isoweek from date_day) as week_of_year,

    extract(day from date_day) as day_of_month,

    extract(dayofweek from date_day) as day_of_week,

    format_date('%A', date_day) as day_name,

    extract(dayofweek from date_day) in (1, 7) as is_weekend

from date_spine
