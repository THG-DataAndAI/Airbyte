{{ config(
    materialized='table',
    schema='marts'
) }}

with customers as (
    select * from {{ ref('stg_shopify_customers') }}
),

customer_orders as (
    select
        customer_id,
        count(distinct order_id) as lifetime_order_count,
        sum(total_price) as lifetime_value,
        min(created_at) as first_order_date,
        max(created_at) as last_order_date
    from {{ ref('stg_shopify_orders') }}
    where customer_id is not null
    group by customer_id
),

final as (
    select
        c.customer_id,
        c.email,
        c.first_name,
        c.last_name,
        concat(c.first_name, ' ', c.last_name) as full_name,
        c.phone,
        c.customer_state,
        c.email_verified,
        c.accepts_marketing,
        c.currency,
        c.created_at as customer_created_at,
        c.updated_at as customer_updated_at,
        coalesce(co.lifetime_order_count, 0) as lifetime_order_count,
        coalesce(co.lifetime_value, 0) as lifetime_value,
        co.first_order_date,
        co.last_order_date,
        case 
            when co.lifetime_order_count = 0 then 'prospect'
            when co.lifetime_order_count = 1 then 'new_customer'
            when co.lifetime_order_count between 2 and 5 then 'returning_customer'
            else 'vip_customer'
        end as customer_segment,
        current_timestamp as dbt_updated_at
    from customers c
    left join customer_orders co on c.customer_id = co.customer_id
)

select * from final