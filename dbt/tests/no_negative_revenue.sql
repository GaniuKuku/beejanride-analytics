select
    trip_id,
    net_revenue
from {{ ref('fct_trips') }}
where net_revenue < 0
