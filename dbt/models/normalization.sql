WITH norm AS (
    select
    	"_airbyte_ab_id" as id, 
        (_airbyte_data ->> 'User') AS cc_owner,
        (_airbyte_data ->> 'Card') AS ccard,
        (_airbyte_data ->> 'Year') AS year,
        (_airbyte_data ->> 'Month') AS month,
        (_airbyte_data ->> 'Day') AS day,
        (_airbyte_data ->> 'Time') AS time,
        (_airbyte_data ->> 'Amount') AS amount,
        (_airbyte_data ->> 'Use Chip') AS txn_type,
        (_airbyte_data ->> 'Merchant Name') AS merchant_name,
        (_airbyte_data ->> 'Merchant City') AS merchant_city,
        (_airbyte_data ->> 'Merchant State') AS merchant_state,
        (_airbyte_data ->> 'Zip') AS merchant_zip,
        (_airbyte_data ->> 'MCC') AS mcc,
        (_airbyte_data ->> 'Errors?') AS errors,
        (_airbyte_data ->> 'Is Fraud?') AS is_fraud,
        _airbyte_emitted_at
    FROM _airbyte_raw_credit_card_txns_raw 
)
SELECT 
    CAST(id AS VARCHAR) AS id,
    CAST(cc_owner AS VARCHAR) AS cc_owner,
    CAST(ccard AS VARCHAR) AS ccard,
    CAST(year AS INT) AS year,
    CAST(month AS INT) AS month,
    CAST(day AS INT) AS day,
    CAST(
        (year || '-' || TO_CHAR(month::INT, 'FM00') || '-' || TO_CHAR(day::INT, 'FM00')) AS DATE
    ) AS full_date,
    CAST(time AS TIME) AS time,
    CAST(REPLACE(REPLACE(amount, '$', ''), ',', '') AS NUMERIC(10, 2)) AS dollar_amount,
    CAST(txn_type AS VARCHAR) AS txn_type,
    CAST(merchant_name AS VARCHAR) AS merchant_name,
    CAST(merchant_city AS VARCHAR) AS merchant_city,
    CAST(merchant_state AS VARCHAR) AS merchant_state,
    CAST(merchant_zip AS VARCHAR) AS merchant_zip,
    CAST(mcc AS VARCHAR) AS mcc,
	CAST(errors AS VARCHAR) AS errors, 
    CASE WHEN is_fraud = 'Yes' THEN TRUE ELSE FALSE END AS is_fraud, 
    _airbyte_emitted_at
FROM norm
