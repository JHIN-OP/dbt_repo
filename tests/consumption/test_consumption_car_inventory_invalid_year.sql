{{ config(
    severity = 'error',
    store_failures = true,
    tags = ['car_year_quality', 'tableau_critical', 'prizm_lineage']
) }}

SELECT
    CAR_ID,
    CAR_YEAR,
    MAKE,
    MODEL,
    DEALER_LOCATION
FROM {{ ref('dim_car') }}
WHERE CAR_YEAR IS NULL
   OR CAR_YEAR < 1980
   OR CAR_YEAR > YEAR(CURRENT_DATE()) + 1