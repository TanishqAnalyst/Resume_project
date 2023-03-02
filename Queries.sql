/*1. Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.*/

select distinct(market) as Markets 
from dim_customer 
where customer = "Atliq Exclusive" and region = "APAC";



/*2. What is the percentage of unique product increase in 2021 vs. 2020? The
final output contains these fields,
unique_products_2020
unique_products_2021
percentage_chg*/


WITH a2020 AS (SELECT COUNT(DISTINCT(product_code)) AS unique_products_2020
            	FROM   gdb023.fact_sales_monthly WHERE fiscal_year = 2020 ),
     a2021 AS (SELECT COUNT(DISTINCT(product_code)) AS	unique_products_2021
            	FROM   gdb023.fact_sales_monthly WHERE fiscal_year = 2021 )
        
SELECT *, ROUND((( unique_products_2021 - unique_products_2020 ) / unique_products_2020)* 100,2) AS percentage_chg
    FROM a2020,a2021
    
    
    
/*3.Provide a report with all the unique product counts for each segment and sort them in descending order of product counts. The 
final output contains 2 fields, 
segment 
product_count*/

select segment, count(distinct(product_code)) as unique_products 
from dim_product 
group by segment 
order by count(distinct(product_code)) desc;



/*4.Follow-up: Which segment had the most increase in unique products in 2021 vs 2020? 
The final output contains these fields, 
segment 
product_count_2020 
product_count_2021 
difference*/

select a.segment as segment, 
	a.product_count_2020 as product_count_2020, 
    	b.product_count_2021 as product_count_2021,  
    	b.product_count_2021 - a.product_count_2020 as Total_change 
from
	(select segment, count(distinct(product_code)) as product_count_2020 from (select a.segment as segment, a.product_code as product_code, b.fiscal_year as fiscal_year
	from dim_product a 
	left join fact_sales_monthly b 
	on a.product_code = b.product_code) a where fiscal_year=2020 group by segment) a 
inner join 
	(select segment, count(distinct(product_code)) as product_count_2021 from (select a.segment as segment, a.product_code as product_code, b.fiscal_year as fiscal_year
	from dim_product a 
	left join fact_sales_monthly b 
	on a.product_code = b.product_code) a where fiscal_year=2021 group by segment) b
on a.segment=b.segment
order by Total_change desc;



/*5.Get the products that have the highest and lowest manufacturing costs. 
The final output should contain these fields, 
product_code 
product
manufacturing_cost*/

SELECT p.product_code,
       p.product,
       ROUND(manufacturing_cost,2) AS manufacturing_cost
FROM  gdb023.dim_product p 
JOIN  gdb023.fact_manufacturing_cost mc 
ON    mc.product_code = p.product_code 
WHERE manufacturing_cost IN ( 
                         (SELECT MAX(manufacturing_cost) FROM gdb023.fact_manufacturing_cost),
                         (SELECT MIN(manufacturing_cost) FROM gdb023.fact_manufacturing_cost) 
                             )



/*6.Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market. 
The final output contains these fields, 
customer_code 
customer 
average_discount_percentage*/

SELECT c.customer_code,
       c.customer,
       ROUND(AVG(pre.pre_invoice_discount_pct),4) AS average_discount_percentage
FROM   gdb023.dim_customer c 
JOIN   gdb023.fact_pre_invoice_deductions pre 
ON     c.customer_code = pre.customer_code
WHERE  pre.fiscal_year = 2021 AND c.market ='India'
GROUP BY c.customer_code,c.customer
ORDER BY average_discount_percentage DESC
LIMIT 5




/*7.Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month. This analysis helps to get an idea of low and high-performing months and take strategic decisions. 
The final report contains these columns: 
Month Year 
Gross sales Amount*/

select concat(monthname(date),'-',year(date)) as mm_yy, 
	round(sum(gross_sales)) as gross_sales 
from 
	(select a.date, a.gross_sales from 
	(select a.product_code, a.customer_code, a.date, a.sold_quantity*a.gross_price as gross_sales from
	(select a.product_code, a.customer_code, a.sold_quantity, a.date, b.gross_price from fact_sales_monthly a
	left join
	fact_gross_price b on a.product_code=b.product_code) a)a
	left join
	dim_customer b
	on a.customer_code=b.customer_code
	where customer="Atliq Exclusive") a
group by mm_yy order by mm_yy;



/*8.In which quarter of 2020, got the maximum total_sold_quantity? 
The final output contains these fields 
sorted by the total_sold_quantity, 
Quarter total_sold_quantity*/

select quarter(date) as Sales_quarter, sum(sold_quantity) as Total_sold_quantity 
from fact_sales_monthly 
where year(date)=2020 
group by quarter(date) 
order by total_sold_quantity desc;



/*9.Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? 
The final output contains these fields, 
channel 
gross_sales_mln percentage*/

select channel, total_sales/(select sum(b.sold_quantity*a.gross_price) as gross_sales 
from fact_gross_price a
right join 
	fact_sales_monthly b on a.product_code=b.product_code) * 100 as percentage_gross_sales
	from 
	(select a.channel, sum(b.gross_sales) as total_sales from dim_customer a
right join
	(select b.customer_code, b.sold_quantity*a.gross_price as gross_sales from fact_gross_price a
	right join 
	fact_sales_monthly b on a.product_code=b.product_code) b
on a.customer_code=b.customer_code
group by channel) a;



/*10.Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021? 
The final output contains these fields, 
division 
product_code 
product
product total_sold_quantity
rank*/

select division, product_code, product, sold_quantity, RANK () OVER (PARTITION BY division ORDER BY sold_quantity desc) as ranking
	from (
	select a.division, b.sold_quantity, b.product_code, b.product, ROW_NUMBER() OVER (PARTITION BY a.division ORDER BY b.sold_quantity DESC) rn
	from 
		dim_product a
	right join
		(select a.product_code, a.sold_quantity, b.product from 
		(select product_code, 
		sum(sold_quantity) as sold_quantity 
		from fact_sales_monthly 
		where year(date)=2021 
		group by product_code) a
		left join
		(select product,product_code from dim_product) b
		on a.product_code=b.product_code) b
	on a.product_code=b.product_code 
	order by sold_quantity desc
	) t
WHERE rn <= 3;
