{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key='SALE_ID',
        on_schema_change='append_new_columns',
        alias='FACT_CAR_SALES',

        pre_hook=[
            "{{ validate_car_year(ref('dim_car')) }}"
        ],

        query_tag=generate_prizm_query_tag(
            model_name='FACT_CAR_SALES',
            source_table='DQLABS.CMX_STAGING.STG_SALES_TRANSACTIONS,DQLABS.CMX_CONSUMPTION.DIM_CAR',
            target_table='DQLABS.CMX_CONSUMPTION.FACT_CAR_SALES',
            asset_group='CAR_SALES',
            operation='INCREMENTAL_MERGE'
        ),

        tags=[
            'PRIZM',
            'SECOND_HAND_CAR',
            'SNOWFLAKE',
            'STAGING_TO_CONSUMPTION',
            'FACT_CAR_SALES',
            'CAR_YEAR_QUALITY',
            'TABLEAU_CRITICAL'
        ]
    )
}}


with sales_source_records as (

    select
        src.SALE_ID,
        src.CUSTOMER_ID,
        src.CAR_ID,
        src.SALE_DATE,
        src.SALE_PRICE,
        src.PAYMENT_METHOD,

        row_number() over (
            partition by src.SALE_ID
            order by
                src.SALE_DATE desc nulls last,
                src.SALE_ID
        ) as DBT_SOURCE_ROW_NUMBER

    from {{ source(
        'cmx_staging',
        'stg_sales_transactions'
    ) }} as src

    where src.SALE_ID is not null

),


deduplicated_sales as (

    select
        SALE_ID,
        CUSTOMER_ID,
        CAR_ID,
        SALE_DATE,
        SALE_PRICE,
        PAYMENT_METHOD

    from sales_source_records

    where DBT_SOURCE_ROW_NUMBER = 1

),


car_dimension as (

    select
        CAR_ID,
        PURCHASE_PRICE,
        LISTING_PRICE,
        DEALER_LOCATION,
        MAKE,
        MODEL,
        CAR_YEAR

    from {{ ref('dim_car') }}

    where CAR_ID is not null
      and CAR_YEAR is not null
      and CAR_YEAR between 1980 and YEAR(CURRENT_DATE()) + 1

),


enriched_sales as (

    select
        sales.SALE_ID,
        sales.CUSTOMER_ID,
        sales.CAR_ID,
        sales.SALE_DATE,
        sales.SALE_PRICE,
        sales.PAYMENT_METHOD,

        car.PURCHASE_PRICE,
        car.LISTING_PRICE,

        sales.SALE_PRICE - car.PURCHASE_PRICE
            as PROFIT_AMOUNT,

        car.DEALER_LOCATION,
        car.MAKE,
        car.MODEL,
        car.CAR_YEAR,

        current_timestamp()::timestamp_ntz
            as DW_UPDATED_DATE

    from deduplicated_sales as sales

    inner join car_dimension as car
        on sales.CAR_ID = car.CAR_ID

)


select
    SALE_ID,
    CUSTOMER_ID,
    CAR_ID,
    SALE_DATE,
    SALE_PRICE,
    PAYMENT_METHOD,
    PURCHASE_PRICE,
    LISTING_PRICE,
    PROFIT_AMOUNT,
    DEALER_LOCATION,
    MAKE,
    MODEL,
    CAR_YEAR,
    DW_UPDATED_DATE

from enriched_sales