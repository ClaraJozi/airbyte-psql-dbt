select 
	full_date, 
	year, 
	month, 
	day, 
	count(distinct cc_owner) as cc_owner_cnt, 
	count(*) as txn_cnt, 
	sum(dollar_amount) as amount_sum, 
	sum(case when is_fraud is true then 1 else 0 end) as fraud_cnt, 
	1.00*sum(case when is_fraud is true then 1 else 0 end)/count(*) as fraud_rate_cnt, 
	sum(case when is_fraud is true then dollar_amount else 0 end) as fraud_vol,
	1.00*sum(case when is_fraud is true then dollar_amount else 0 end)/sum(dollar_amount) as fraud_rate_vol,
	avg(case when is_fraud is false then dollar_amount else 0 end) as avg_amount_non_fraud,
	avg(case when is_fraud is true then dollar_amount else 0 end) as avg_amount_fraud
from {{ ref('normalization') }}
group by 1,2,3,4
order by 1 desc