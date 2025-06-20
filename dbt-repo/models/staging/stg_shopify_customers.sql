{{ config(
    materialized='view',
    schema='staging'
) }}

with raw_customers as (
    select
        _airbyte_ab_id,
        _airbyte_emitted_at,
        jsonb_extract_path_text(_airbyte_data, 'id')::bigint as customer_id,
        jsonb_extract_path_text(_airbyte_data, 'email') as email,
        jsonb_extract_path_text(_airbyte_data, 'first_name') as first_name,
        jsonb_extract_path_text(_airbyte_data, 'last_name') as last_name,
        jsonb_extract_path_text(_airbyte_data, 'phone') as phone,
        jsonb_extract_path_text(_airbyte_data, 'state') as customer_state,
        jsonb_extract_path_text(_airbyte_data, 'verified_email')::boolean as email_verified,
        jsonb_extract_path_text(_airbyte_data, 'accepts_marketing')::boolean as accepts_marketing,
        jsonb_extract_path_text(_airbyte_data, 'currency') as currency,
        jsonb_extract_path_text(_airbyte_data, 'created_at')::timestamp as created_at,
        jsonb_extract_path_text(_airbyte_data, 'updated_at')::timestamp as updated_at,
        jsonb_extract_path_text(_airbyte_data, 'total_spent') as total_spent,
        jsonb_extract_path_text(_airbyte_data, 'orders_count')::int as orders_count,
        _airbyte_data
    from {{ source('airbyte_raw', '_airbyte_raw_customers') }}
    where _airbyte_data is not null
)

select * from raw_customers