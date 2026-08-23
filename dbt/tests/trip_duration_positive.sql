select
    trip_id,
    trip_duration_minutes
from {{ ref('fct_trips') }}
where trip_duration_minutes is null
   or trip_duration_minutes <= 0
