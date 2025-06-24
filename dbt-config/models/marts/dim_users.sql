{{ config(materialized='table') }}

with staging_data as (
    select * from {{ ref('stg_raw_data') }}
),

cleaned_users as (
    select
        source_id as user_id,
        _airbyte_ab_id,
        created_at,
        updated_at,
        _airbyte_emitted_at as last_synced_at,
        -- Add data quality checks
        case 
            when source_id is null then 'missing_id'
            when created_at > current_timestamp then 'future_date'
            else 'valid'
        end as data_quality_status
    from staging_data
    where source_id is not null
)

select * from cleaned_users