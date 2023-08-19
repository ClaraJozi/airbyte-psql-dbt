select 
	full_date,
	year, 
	month, 
	day,  
	merchant_state,
	merchant_city,
	count(distinct cc_owner) as cc_owner_cnt, 
	count(*) as txn_cnt, 
	sum(dollar_amount) as amount_sum, 
	sum(case when is_fraud is true then 1 else 0 end) as fraud_cnt, 
	sum(case when is_fraud is true then dollar_amount else 0 end) as fraud_amount,
	avg(case when is_fraud is false then dollar_amount else 0 end) as avg_amount_non_fraud,
	avg(case when is_fraud is true then dollar_amount else 0 end) as avg_amount_fraud
from {{ ref('normalization') }}
where true 
	and merchant_state is not null 
	and merchant_city != 'ONLINE'
group by 1,2,3,4,5,6
order by 1 desc,5,6