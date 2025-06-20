{{ config(
    materialized='view',
    schema='staging'
) }}

with raw_orders as (
    select
        _airbyte_ab_id,
        _airbyte_emitted_at,
        jsonb_extract_path_text(_airbyte_data, 'id')::bigint as order_id,
        jsonb_extract_path_text(_airbyte_data, 'order_number')::int as order_number,
        jsonb_extract_path_text(_airbyte_data, 'customer', 'id')::bigint as customer_id,
        jsonb_extract_path_text(_airbyte_data, 'email') as email,
        jsonb_extract_path_text(_airbyte_data, 'financial_status') as financial_status,
        jsonb_extract_path_text(_airbyte_data, 'fulfillment_status') as fulfillment_status,
        jsonb_extract_path_text(_airbyte_data, 'currency') as currency,
        jsonb_extract_path_text(_airbyte_data, 'total_price')::decimal(10,2) as total_price,
        jsonb_extract_path_text(_airbyte_data, 'subtotal_price')::decimal(10,2) as subtotal_price,
        jsonb_extract_path_text(_airbyte_data, 'total_tax')::decimal(10,2) as total_tax,
        jsonb_extract_path_text(_airbyte_data, 'total_discounts')::decimal(10,2) as total_discounts,
        jsonb_extract_path_text(_airbyte_data, 'created_at')::timestamp as created_at,
        jsonb_extract_path_text(_airbyte_data, 'updated_at')::timestamp as updated_at,
        jsonb_extract_path_text(_airbyte_data, 'processed_at')::timestamp as processed_at,
        jsonb_extract_path_text(_airbyte_data, 'cancelled_at')::timestamp as cancelled_at,
        _airbyte_data
    from {{ source('airbyte_raw', '_airbyte_raw_orders') }}
    where _airbyte_data is not null
)

select * from raw_orders