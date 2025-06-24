{{ config(materialized='view') }}

with raw_data as (
    select
        _airbyte_ab_id,
        _airbyte_data,
        _airbyte_emitted_at,
        _airbyte_normalized_at,
        -- Extract common fields from JSON data
        (_airbyte_data ->> 'id')::bigint as source_id,
        (_airbyte_data ->> 'created_at')::timestamp as created_at,
        (_airbyte_data ->> 'updated_at')::timestamp as updated_at
    from {{ source('airbyte_raw', '_airbyte_raw_users') }}
    where _airbyte_data is not null
)

select * from raw_data