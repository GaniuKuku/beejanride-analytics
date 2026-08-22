with payments as (

    select *
    from {{ ref('stg_payments') }}

),

payment_summary as (

    select
        trip_id,

        count(*) as payment_count,

        countif(payment_status = 'success') as successful_payment_count,

        sum(
            case
                when payment_status = 'success'
                then coalesce(payment_amount, 0)
                else 0
            end
        ) as successful_payment_amount,

        sum(
            case
                when payment_status = 'success'
                then coalesce(payment_fee, 0)
                else 0
            end
        ) as successful_payment_fee,

        countif(payment_status = 'failed') as failed_payment_count,

        count(*) > 1
            as multiple_payment_attempts_flag,

        countif(payment_status = 'success') > 1
            as duplicate_successful_payment_flag

    from payments

    group by trip_id

)

select
    trip_id,
    payment_count,
    successful_payment_count,
    successful_payment_amount,
    successful_payment_fee,
    failed_payment_count,
    multiple_payment_attempts_flag,
    duplicate_successful_payment_flag

from payment_summary
