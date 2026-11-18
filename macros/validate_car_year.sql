{% macro validate_car_year(source_relation) %}

    {% if execute %}

        {% set validation_query %}

            SELECT
                COUNT_IF(CAR_ID IS NULL) AS NULL_CAR_ID_COUNT,

                COUNT_IF(CAR_YEAR IS NULL) AS NULL_CAR_YEAR_COUNT,

                COUNT_IF(
                    CAR_YEAR < 1980
                    OR CAR_YEAR > YEAR(CURRENT_DATE()) + 1
                ) AS INVALID_CAR_YEAR_COUNT

            FROM {{ source_relation }}

        {% endset %}

        {% set validation_result = run_query(validation_query) %}

        {% if validation_result is not none
              and validation_result.rows | length > 0 %}

            {% set null_car_id_count =
                validation_result.columns[0].values()[0] | int %}

            {% set null_car_year_count =
                validation_result.columns[1].values()[0] | int %}

            {% set invalid_car_year_count =
                validation_result.columns[2].values()[0] | int %}

            {% if null_car_id_count > 0
                  or null_car_year_count > 0
                  or invalid_car_year_count > 0 %}

                {{ exceptions.raise_compiler_error(
                    "DIM_CAR data-quality validation failed. "
                    ~ "NULL CAR_ID count: "
                    ~ null_car_id_count
                    ~ "; NULL CAR_YEAR count: "
                    ~ null_car_year_count
                    ~ "; invalid CAR_YEAR count: "
                    ~ invalid_car_year_count
                    ~ ". CAR_YEAR must be between 1980 and "
                    ~ "the next calendar year."
                ) }}

            {% endif %}

        {% endif %}

    {% endif %}

    SELECT 1

{% endmacro %}