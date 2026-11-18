{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key='CAR_ID',
        on_schema_change='append_new_columns',
        alias='DIM_CAR',

        pre_hook=[
            "{{ validate_car_year(source('cmx_staging', 'stg_car_inventory')) }}"
        ],

        query_tag=generate_prizm_query_tag(
            model_name='DIM_CAR',
            source_table='DQLABS.CMX_STAGING.STG_CAR_INVENTORY',
            target_table='DQLABS.CMX_CONSUMPTION.DIM_CAR',
            asset_group='CAR_INVENTORY',
            operation='INCREMENTAL_MERGE'
        ),

        tags=[
            'PRIZM',
            'SECOND_HAND_CAR',
            'SNOWFLAKE',
            'STAGING_TO_CONSUMPTION',
            'DIM_CAR',
            'CAR_YEAR_QUALITY',
            'TABLEAU_CRITICAL'
        ]
    )
}}


with source_records as (

    select
        src.CAR_ID,
        src.VIN,
        src.MAKE,
        src.MODEL,
        src.CAR_YEAR,
        src.PURCHASE_PRICE,
        src.LISTING_PRICE,
        src.MILEAGE,
        src.DEALER_LOCATION,

        row_number() over (
            partition by src.CAR_ID
            order by
                src.CAR_ID,
                src.CAR_YEAR desc nulls last
        ) as DBT_SOURCE_ROW_NUMBER

    from {{ source('cmx_staging', 'stg_car_inventory') }} as src

),


deduplicated_source as (

    select
        CAR_ID,
        VIN,
        MAKE,
        MODEL,
        CAR_YEAR,
        PURCHASE_PRICE,
        LISTING_PRICE,
        MILEAGE,
        DEALER_LOCATION

    from source_records

    where DBT_SOURCE_ROW_NUMBER = 1

),


validated_source as (

    select
        CAR_ID,
        VIN,
        MAKE,
        MODEL,
        CAR_YEAR,
        PURCHASE_PRICE,
        LISTING_PRICE,
        MILEAGE,
        DEALER_LOCATION

    from deduplicated_source

    where CAR_ID is not null
      and CAR_YEAR is not null
      and CAR_YEAR between 1980 and YEAR(CURRENT_DATE()) + 1

),


final as (

    select
        CAR_ID,
        VIN,
        MAKE,
        MODEL,
        CAR_YEAR,
        PURCHASE_PRICE,
        LISTING_PRICE,
        MILEAGE,
        DEALER_LOCATION,
        current_timestamp()::timestamp_ntz as DW_UPDATED_DATE

    from validated_source

)


select
    CAR_ID,
    VIN,
    MAKE,
    MODEL,
    CAR_YEAR,
    PURCHASE_PRICE,
    LISTING_PRICE,
    MILEAGE,
    DEALER_LOCATION,
    DW_UPDATED_DATE

from final