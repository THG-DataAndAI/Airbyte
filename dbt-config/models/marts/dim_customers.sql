{{ config(materialized='table') }}

with customers as (
    select * from {{ ref('stg_shopify_customers') }}
),

customer_orders as (
    select
        customer_id,
        count(*) as order_count,
        sum(total_price) as lifetime_value,
        min(created_at) as first_order_date,
        max(created_at) as last_order_date
    from {{ ref('stg_shopify_orders') }}
    group by customer_id
),

final as (
    select
        c.customer_id,
        c.email,
        c.first_name,
        c.last_name,
        c.created_at as customer_created_at,
        c.updated_at as customer_updated_at,
        coalesce(co.order_count, 0) as total_orders,
        coalesce(co.lifetime_value, 0) as lifetime_value,
        co.first_order_date,
        co.last_order_date,
        case
            when co.last_order_date >= current_date - interval '30 days' then 'active'
            when co.last_order_date >= current_date - interval '90 days' then 'at_risk'
            when co.last_order_date is not null then 'churned'
            else 'prospect'
        end as customer_status,
        c._airbyte_emitted_at as last_synced_at
    from customers c
    left join customer_orders co on c.customer_id = co.customer_id
)

select * from final