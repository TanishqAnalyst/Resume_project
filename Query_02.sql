2.What is the percentage of unique product increase in 2021 vs. 2020? The final output contains these fields, unique_products_2020 unique_products_2021 percentage_chg

WITH a2020 AS (
			SELECT 
				   COUNT(DISTINCT(product_code)) AS	unique_products_2020
            FROM   gdb023.fact_sales_monthly
            WHERE fiscal_year = 2020 ),
     a2021 AS (
			SELECT 
				   COUNT(DISTINCT(product_code)) AS	unique_products_2021
            FROM   gdb023.fact_sales_monthly
            WHERE fiscal_year = 2021 )
        
SELECT *,
		   ROUND((( unique_products_2021 - unique_products_2020 ) / unique_products_2020)* 100,2) AS percentage_chg
    FROM a2020,a2021
