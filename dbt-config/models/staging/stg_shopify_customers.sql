{{ config(materialized='view') }}

with raw_customers as (
    select
        _airbyte_ab_id,
        _airbyte_data,
        _airbyte_emitted_at,
        -- Extract customer fields from JSON
        (_airbyte_data ->> 'id')::bigint as customer_id,
        _airbyte_data ->> 'email' as email,
        _airbyte_data ->> 'first_name' as first_name,
        _airbyte_data ->> 'last_name' as last_name,
        (_airbyte_data ->> 'created_at')::timestamp as created_at,
        (_airbyte_data ->> 'updated_at')::timestamp as updated_at,
        (_airbyte_data ->> 'total_spent')::decimal(10,2) as total_spent,
        (_airbyte_data ->> 'orders_count')::integer as orders_count
    from {{ source('airbyte_raw', '_airbyte_raw_customers') }}
    where _airbyte_data is not null
)

select * from raw_customers