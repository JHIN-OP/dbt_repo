{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key='SALE_ID',
        on_schema_change='fail',
        alias='FACT_CAR_SALES',

        query_tag=generate_prizm_query_tag(
            model_name='FACT_CAR_SALES',
            source_table='DQLABS.CMX_STAGING.STG_SALES_TRANSACTIONS',
            target_table='DQLABS.CMX_CONSUMPTION.FACT_CAR_SALES',
            asset_group='CAR_SALES',
            operation='INCREMENTAL_INSERT_NEW'
        ),

        tags=[
            'PRIZM',
            'SECOND_HAND_CAR',
            'SNOWFLAKE',
            'STAGING_TO_CONSUMPTION',
            'FACT_CAR_SALES'
        ]
    )
}}

with source_records as (

    select
        src.*,

        row_number() over (
            partition by src.SALE_ID
            order by src.SALE_ID
        ) as DBT_SOURCE_ROW_NUMBER

    from {{
        source(
            'cmx_staging',
            'stg_sales_transactions'
        )
    }} as src

    where src.SALE_ID is not null

),

deduplicated_source as (

    select
        * exclude DBT_SOURCE_ROW_NUMBER

    from source_records

    where DBT_SOURCE_ROW_NUMBER = 1

),

new_records_only as (

    select
        src.*

    from deduplicated_source as src

    {% if is_incremental() %}

        where not exists (

            select 1

            from {{ this }} as target

            where target.SALE_ID = src.SALE_ID
        )

    {% endif %}

)

select *
from new_records_only