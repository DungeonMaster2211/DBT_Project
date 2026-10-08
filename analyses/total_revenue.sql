 with revenue as (
    select * from {{ ref('stg_payments')}}
 ),


 total_revenue as (
    select payment_id,
    {% for order_status in ['success'] %}
        sum(case when order_status = '{{ order_status }}' then payment_amount else 0 end) as total_revenue_{{ order_status }}
    {% endfor %}
    from revenue
    group by payment_id
    where revenue_status = 1
 )