{{ 
    config (
    materialized='incremental',
    unique_key='sale_id',
    incremental_strategy='merge'
    ) 
}}

with raw_data as (
    select * 
    from {{ source('circana_lab', 'circana_sales_changes') }}

    {% if is_incremental() %}

    where cdc_loaded_at > (select max(cdc_loaded_at) from {{this}})

    {% endif %}
),

latest as (
    select *
    from raw_data
    -- drop the DELETE half of update pairs
    where not (cdc_action = 'DELETE' and cdc_is_update)
    qualify row_number() over (
        partition by sale_id
        order by cdc_loaded_at desc
    ) = 1
)

select
    sale_id, product_id, store_id, units, dollars, week_ending,
    (cdc_action = 'DELETE') as is_deleted,
    cdc_loaded_at
from latest