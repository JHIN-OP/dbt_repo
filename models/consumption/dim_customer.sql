{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key='CUSTOMER_ID',
        on_schema_change='append_new_columns',
        alias='DIM_CUSTOMER',

        query_tag=generate_prizm_query_tag(
            model_name='DIM_CUSTOMER',
            source_table='DQLABS.CMX_STAGING.STG_CUSTOMERS',
            target_table='DQLABS.CMX_CONSUMPTION.DIM_CUSTOMER',
            asset_group='CUSTOMER',
            operation='INCREMENTAL_INSERT_NEW'
        ),

        tags=[
            'PRIZM',
            'SECOND_HAND_CAR',
            'SNOWFLAKE',
            'STAGING_TO_CONSUMPTION',
            'DIM_CUSTOMER'
        ]
    )
}}

with source_records as (

    select
        src.*,

        row_number() over (
            partition by src.CUSTOMER_ID
            order by src.CUSTOMER_ID
        ) as DBT_SOURCE_ROW_NUMBER

    from {{ source('cmx_staging', 'stg_customers') }} as src

    where src.CUSTOMER_ID is not null

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

            where target.CUSTOMER_ID = src.CUSTOMER_ID
        )

    {% endif %}

)

select *
from new_records_only