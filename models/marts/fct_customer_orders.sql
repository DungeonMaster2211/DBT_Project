-- Import CTEs

With customers as (

  select * from {{ ref('stg_customers') }}

),

orders as (

  select * from {{ ref('stg_orders') }}

),

payments as (

  select * from {{ ref('stg_payments') }}

),

-- Logical CTEs
completed_payments as (

  select 
    order_id,
    max(payment_created_at) as payment_finalized_date,
    sum(payment_amount) as total_amount_paid
  from payments
  where payment_status <> 'fail'
  group by 1

),
paid_orders as (

  select 
    o.order_id,
    o.customer_id,
    o.order_placed_at,
    o.order_status,
    cp.total_amount_paid,
    cp.payment_finalized_date,
    c.customer_first_name,
    c.customer_last_name
  from orders o
  left join completed_payments cp on o.order_id = cp.order_id
  left join customers c on o.customer_id = c.customer_id

),



-- Final CTE

final as (
    select
     order_id,
     customer_id, 
     order_placed_at,
     order_status,
     total_amount_paid,
     payment_finalized_date,
     customer_first_name,
     customer_last_name,

        row_number() over (order by order_id) as transaction_seq,
        row_number() over(partition by customer_id order by order_id) as customer_sales_seq,
        case
        
            when (
                rank() over(partition by customer_id order by order_placed_at,order_id) = 1) then 'new'
            else 'return'
         
        end as nvsr,
        sum(total_amount_paid) over(partition by customer_id order by order_placed_at) as customer_lifetime_value,
        
    -- first day of sale
    first_value(order_placed_at) over (
      partition by customer_id
      order by order_placed_at
      ) as fdos

    from paid_orders
    -- Simple Select Statment
)
Select * from final
order by order_id