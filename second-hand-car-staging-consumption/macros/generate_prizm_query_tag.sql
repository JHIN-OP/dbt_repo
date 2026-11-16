{% macro generate_prizm_query_tag(
    model_name,
    source_table,
    target_table,
    asset_group,
    operation
) %}

    {% set tag_data = {
        "pipeline_name":
            "DBT_SECOND_HAND_CAR_STAGING_TO_CONSUMPTION",

        "project_name":
            project_name,

        "model_name":
            model_name,

        "source_table":
            source_table,

        "target_table":
            target_table,

        "asset_group":
            asset_group,

        "operation":
            operation,

        "orchestrator":
            "DBT_CLOUD",

        "platform":
            "SNOWFLAKE",

        "environment":
            target.name,

        "invocation_id":
            invocation_id
    } %}

    {{ return(tojson(tag_data)) }}

{% endmacro %}