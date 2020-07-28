# Predict overall monthly costs using Linear Regression

# 1. Extracting monthly summarized data 
# -------------------------------------

CREATE OR REPLACE TABLE `cio-gcp-bill-analysis-357b8b12.cio_gcp_bill_analysis.monthly_costs`
AS
select cast (substr(invoice.month,length(invoice.month)-1,2) as int64) as month,
       sum(cost) as cost
from `cio-gcp-bill-analysis-357b8b12.cio_gcp_bill_analysis.gcp_billing_export_v1_01F4C6_EB9270_25C051`
where invoice.month like "%2020%" and cost > 1
group by invoice.month
order by invoice.month;


# 2. Creating a model to predict monthly costs 
# --------------------------------------------

CREATE OR REPLACE MODEL `cio-gcp-bill-analysis-357b8b12.cio_gcp_bill_analysis.monthly_costs_model`
OPTIONS(model_type='LINEAR_REG',INPUT_LABEL_COLS=['cost'] )
AS
select * from  `cio-gcp-bill-analysis-357b8b12.cio_gcp_bill_analysis.monthly_costs`;

 
# 3. Add months to predict on
# --------------------------------------------

INSERT `cio-gcp-bill-analysis-357b8b12.cio_gcp_bill_analysis.monthly_costs` (month, cost)
VALUES (08, 0), (09, 0), (10, 0), (11, 0), (12, 0);


# 4. Predict overall monthly costs
# --------------------------------------------

create or replace table  `cio-gcp-bill-analysis-357b8b12.cio_gcp_bill_analysis.monthly_forecast` AS
  select month, predicted_cost from ML.PREDICT (MODEL `cio-gcp-bill-analysis-357b8b12.cio_gcp_bill_analysis.monthly_costs_model`,
                   (select month
                    from  `cio-gcp-bill-analysis-357b8b12.cio_gcp_bill_analysis.monthly_costs`
                    where cost = 0))
  order by month;            

 
# 5. Merge all data into one table for presentation 
# --------------------------------------------

create or replace table  `cio-gcp-bill-analysis-357b8b12.cio_gcp_bill_analysis.monthly` AS
select * from `cio-gcp-bill-analysis-357b8b12.cio_gcp_bill_analysis.monthly_costs` where cost > 0
union all
select * from `cio-gcp-bill-analysis-357b8b12.cio_gcp_bill_analysis.monthly_forecast`
order by month