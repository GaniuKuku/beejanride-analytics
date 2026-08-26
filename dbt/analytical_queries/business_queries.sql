-- 1. Daily revenue per city

SELECT
    d.date AS trip_date,
    c.city_name,
    COUNT(t.trip_id) AS trip_count,
    SUM(t.successful_payment_amount) AS gross_revenue,
    SUM(t.net_revenue) AS net_revenue
FROM `beejanride-analytics-505416.beejanride_marts.fct_trips` AS t
JOIN `beejanride-analytics-505416.beejanride_marts.dim_city` AS c
    ON t.city_id = c.city_id
JOIN `beejanride-analytics-505416.beejanride_marts.dim_date` AS d
    ON t.date_key = d.date_key
WHERE t.trip_status = 'completed'
GROUP BY
    trip_date,
    c.city_name
ORDER BY
    trip_date,
    c.city_name;


-- 2. Gross vs net revenue

SELECT
    SUM(successful_payment_amount) AS gross_revenue,
    SUM(successful_payment_fee) AS payment_fees,
    SUM(net_revenue) AS net_revenue
FROM `beejanride-analytics-505416.beejanride_marts.fct_trips`
WHERE trip_status = 'completed';


-- 3. Corporate vs personal revenue split

SELECT
    CASE
        WHEN corporate_trip_flag THEN 'Corporate'
        ELSE 'Personal'
    END AS trip_segment,
    COUNT(trip_id) AS trip_count,
    SUM(successful_payment_amount) AS gross_revenue,
    SUM(net_revenue) AS net_revenue
FROM `beejanride-analytics-505416.beejanride_marts.fct_trips`
WHERE trip_status = 'completed'
GROUP BY trip_segment
ORDER BY net_revenue DESC;


-- 4. Top drivers by revenue

SELECT
    t.driver_id,
    COUNT(t.trip_id) AS completed_trips,
    SUM(t.net_revenue) AS total_net_revenue,
    AVG(t.net_revenue) AS average_net_revenue_per_trip
FROM `beejanride-analytics-505416.beejanride_marts.fct_trips` AS t
WHERE t.trip_status = 'completed'
GROUP BY t.driver_id
ORDER BY total_net_revenue DESC
LIMIT 10;


-- 5. Driver activity monitoring

SELECT
    driver_id,
    city_id,
    driver_status,
    rating,
    onboarding_date,
    driver_lifetime_trips
FROM `beejanride-analytics-505416.beejanride_marts.dim_driver`
ORDER BY driver_lifetime_trips DESC;


-- 6. Rider lifetime value

SELECT
    rider_id,
    signup_date,
    rider_lifetime_value
FROM `beejanride-analytics-505416.beejanride_marts.dim_rider`
ORDER BY rider_lifetime_value DESC
LIMIT 20;


-- 7. Payment failure rate

SELECT
    SUM(failed_payment_count) AS failed_payment_attempts,
    SUM(successful_payment_count) AS successful_payment_attempts,
    SUM(payment_count) AS total_payment_attempts,
    SAFE_DIVIDE(
        SUM(failed_payment_count),
        SUM(payment_count)
    ) AS payment_failure_rate
FROM `beejanride-analytics-505416.beejanride_int.int_payments`;


-- 8. Surge impact analysis

SELECT
    CASE
        WHEN surge_multiplier = 1 THEN 'No surge'
        WHEN surge_multiplier > 1 AND surge_multiplier <= 2 THEN 'Low surge'
        WHEN surge_multiplier > 2 AND surge_multiplier <= 5 THEN 'Moderate surge'
        WHEN surge_multiplier > 5 AND surge_multiplier <= 10 THEN 'High surge'
        ELSE 'Extreme surge'
    END AS surge_category,
    COUNT(trip_id) AS trip_count,
    AVG(actual_fare_amount) AS average_fare,
    AVG(net_revenue) AS average_net_revenue,
    SUM(net_revenue) AS total_net_revenue
FROM `beejanride-analytics-505416.beejanride_marts.fct_trips`
WHERE trip_status = 'completed'
GROUP BY surge_category
ORDER BY
    CASE surge_category
        WHEN 'No surge' THEN 1
        WHEN 'Low surge' THEN 2
        WHEN 'Moderate surge' THEN 3
        WHEN 'High surge' THEN 4
        WHEN 'Extreme surge' THEN 5
    END;


-- 9. Fraud detection insights

SELECT
    COUNTIF(duplicate_successful_payment_flag) AS duplicate_payment_trips,
    COUNTIF(failed_payment_on_completed_trip) AS completed_trips_without_successful_payment,
    COUNTIF(extreme_surge_flag) AS extreme_surge_trips,
    COUNTIF(multiple_payment_attempts_flag) AS multiple_payment_attempt_trips
FROM `beejanride-analytics-505416.beejanride_marts.fct_trips`;



-- Fraud / payment integrity investigation

SELECT
    trip_id,
    driver_id,
    rider_id,
    city_id,
    duplicate_successful_payment_flag,
    failed_payment_on_completed_trip,
    extreme_surge_flag,
    multiple_payment_attempts_flag,
    surge_multiplier,
    net_revenue
FROM `beejanride-analytics-505416.beejanride_marts.fct_trips`
WHERE duplicate_successful_payment_flag
   OR failed_payment_on_completed_trip
   OR extreme_surge_flag
   OR multiple_payment_attempts_flag
ORDER BY trip_id;


-- 10. Driver churn tracking
--
-- The current source data does not contain historical driver versions.
-- The SCD Type 2 snapshot is therefore future-ready rather than
-- retrospectively populated with historical changes.
--
-- As driver attributes change, new snapshot versions will be created.

SELECT
    driver_id,
    driver_status,
    rating,
    vehicle_id,
    dbt_valid_from,
    dbt_valid_to
FROM `beejanride-analytics-505416.beejanride_snapshots.snap_drivers`
ORDER BY
    driver_id,
    dbt_valid_from;
