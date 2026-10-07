-- Import CTEs

With customers as (

  select * from {{ ref('stg_customers') }}

),

paid_orders as (
    select * from {{ ref('int_orders') }}
    
    ),



-- Final CTE

final as (
    select
     po.order_id,
     po.customer_id, 
     po.order_placed_at,
     po.order_status,
     po.total_amount_paid,
     po.payment_finalized_date,
     c.customer_first_name,
     c.customer_last_name,

        row_number() over (order by po.order_id) as transaction_seq,
        row_number() over(partition by  po.customer_id order by po.order_id) as customer_sales_seq,
        case
        
            when (
                rank() over(partition by po.customer_id order by po.order_placed_at,po.order_id) = 1) then 'new'
            else 'return'
         
        end as nvsr,
        sum(total_amount_paid) over(partition by po.customer_id order by po.order_placed_at) as customer_lifetime_value,
        
    -- first day of sale
    first_value(po.order_placed_at) over (
      partition by po.customer_id
      order by po.order_placed_at
      ) as fdos

    from paid_orders po
    left join customers c on po.customer_id = c.customer_id
    -- Simple Select Statment
)
Select * from final
order by order_id