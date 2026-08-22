select
    rider_id,
    referral_code,
    signup_date,
    rider_lifetime_value
from {{ ref('int_riders') }}
