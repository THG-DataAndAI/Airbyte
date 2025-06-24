{{ config(materialized='view') }}

with raw_orders as (
    select
        _airbyte_ab_id,
        _airbyte_data,
        _airbyte_emitted_at,
        -- Extract order fields from JSON
        (_airbyte_data ->> 'id')::bigint as order_id,
        (_airbyte_data ->> 'customer_id')::bigint as customer_id,
        _airbyte_data ->> 'order_number' as order_number,
        (_airbyte_data ->> 'total_price')::decimal(10,2) as total_price,
        _airbyte_data ->> 'currency' as currency,
        _airbyte_data ->> 'financial_status' as financial_status,
        _airbyte_data ->> 'fulfillment_status' as fulfillment_status,
        (_airbyte_data ->> 'created_at')::timestamp as created_at,
        (_airbyte_data ->> 'updated_at')::timestamp as updated_at
    from {{ source('airbyte_raw', '_airbyte_raw_orders') }}
    where _airbyte_data is not null
)

select * from raw_orders