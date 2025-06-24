{{ config(materialized='table') }}

with sync_data as (
    select
        date_trunc('day', _airbyte_emitted_at) as sync_date,
        count(*) as records_synced,
        max(_airbyte_emitted_at) - min(_airbyte_emitted_at) as sync_duration,
        extract(epoch from (max(_airbyte_emitted_at) - min(_airbyte_emitted_at))) / 60 as sync_duration_minutes
    from {{ ref('stg_raw_data') }}
    group by date_trunc('day', _airbyte_emitted_at)
),

final as (
    select
        sync_date,
        records_synced,
        coalesce(sync_duration_minutes, 0) as sync_duration_minutes,
        current_timestamp as created_at
    from sync_data
)

select * from final