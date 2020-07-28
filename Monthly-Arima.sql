# Predict overall monthly costs using time series analysis (ARIMA)

# 1. Extracting monthly summarized data 
# --------------------------------------------

CREATE OR REPLACE TABLE `cio-gcp-bill-analysis-357b8b12.cio_gcp_bill_analysis.arima_monthly_costs`
AS
select DATE_TRUNC(cast(usage_start_time as date), MONTH) as month,
       sum(cost) as cost
from `cio-gcp-bill-analysis-357b8b12.cio_gcp_bill_analysis.gcp_billing_export_v1_01F4C6_EB9270_25C051`
where invoice.month like "%2020%" and cost > 1
group by month
order by month;

 
# 2. Creating a model to predict monthly costs 
# --------------------------------------------

CREATE OR REPLACE MODEL `cio-gcp-bill-analysis-357b8b12.cio_gcp_bill_analysis.monthly_arima`
OPTIONS(MODEL_TYPE = 'ARIMA', TIME_SERIES_TIMESTAMP_COL = 'month', TIME_SERIES_DATA_COL = 'cost',
        DATA_FREQUENCY = 'MONTHLY' , HORIZON = 5)
AS
select * from `cio-gcp-bill-analysis-357b8b12.cio_gcp_bill_analysis.arima_monthly_costs`;


# 3. Create predictions
# --------------------------------------------

create or replace table  `cio-gcp-bill-analysis-357b8b12.cio_gcp_bill_analysis.monthly_arima_table1` AS
  select DATE_TRUNC(cast(forecast_timestamp  as date), MONTH) as month,
         forecast_value as forecast_cost,
         prediction_interval_lower_bound as low,
         prediction_interval_upper_bound as high
  from ML.FORECAST(MODEL `cio-gcp-bill-analysis-357b8b12.cio_gcp_bill_analysis.monthly_arima`,
                   STRUCT(5 AS horizon, 0.90 AS confidence_level));

                  
# 4. Merge actual and prediction for presentation 
# --------------------------------------------

create or replace table  `cio-gcp-bill-analysis-357b8b12.cio_gcp_bill_analysis.monthly_arima_prediction` AS                   
select month, cost, 0 as low,0 as high from   `cio-gcp-bill-analysis-357b8b12.cio_gcp_bill_analysis.arima_monthly_costs`
union all
select month, 0 , low, high from  `cio-gcp-bill-analysis-357b8b12.cio_gcp_bill_analysis.monthly_arima_table1`
order by month