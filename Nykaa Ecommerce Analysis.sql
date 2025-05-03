create table customer(
  C_ID varchar(300) primary key,
  C_Name char(250),
  Gender char(200),
  Age int,
  City char(250),
  States char(250),
  Street_Address varchar(500),
  Mobile bigint
);

create table product(
  P_ID varchar(300) primary key,
  P_Name varchar(400),
  Category char(250),
  Company_Name char(250),
  Gender char(250),
  Price float
);

create table orders (
  Or_ID	varchar(300) primary key,
  C_ID varchar(300),
  P_ID varchar(300),
  Order_Date  date,
  Order_Time time,
  Qty int,
  Coupon varchar(200),
  DP_ID	varchar(300),
  Discount float
);

create table delivery (
   DP_ID varchar(300) primary key,
   DP_name char(200),
   DP_Ratings float,
   Percent_Cut float
);

create table rating(
  R_ID varchar(300) primary key,
  Or_ID varchar(300),
  Prod_Rating float,
  Delivery_Service_Rating float
);

create table transactions(
  Tr_ID	varchar(300) primary key ,
  Or_ID	varchar(300),
  Transaction_Mode char(250),
  Reward char(200)
);

create table return_refund(
  RT_ID varchar(300) primary key,
  Or_ID varchar(300),
  Reason char(250),
  Return_Refund	char(250), 
  Dates date
);

/* Column Changes  */
alter table orders add constraint fk_cid foreign key (C_ID) references customer(C_ID), add constraint fk_pid foreign key (P_ID)
references product(P_ID) , add constraint fk_dpid foreign key (DP_ID) references delivery(DP_ID);
alter table rating add constraint fk_orid foreign key (Or_ID) references orders(Or_ID);
alter table transactions add constraint fk_orid foreign key (Or_ID) references orders(Or_ID);
alter table return_refund add constraint fk_orid foreign key (Or_ID) references orders(Or_ID);

alter table customer add constraint cs_mn unique (Mobile);
alter table product rename column Gender to p_gender;

/* enter data */
copy customer from 'C:\Capstone Project\Nykaa ECommerce\Import Files\customer.csv' delimiter ',' csv header;
copy product from 'C:\Capstone Project\Nykaa ECommerce\Import Files\product.csv' delimiter ',' csv header;
copy orders from 'C:\Capstone Project\Nykaa ECommerce\Import Files\orders.csv' delimiter ',' csv header;
copy delivery from 'C:\Capstone Project\Nykaa ECommerce\Import Files\delivery.csv' delimiter ',' csv header;
copy rating from 'C:\Capstone Project\Nykaa ECommerce\Import Files\ratings.csv' delimiter ',' csv header;
copy transactions from 'C:\Capstone Project\Nykaa ECommerce\Import Files\transaction.csv' delimiter ',' csv header;
copy return_refund from 'C:\Capstone Project\Nykaa ECommerce\Import Files\returns.csv' delimiter ',' csv header;

select * from customer;
select * from product;
select * from orders;
select * from delivery;
select * from rating;
select * from transactions;
select * from return_refund;

/* BASIC ANALYSIS */
/* Customer Analysis */
-- 1.	What is the gender-wise distribution of customers across different states along with its  Male vs Female ratio?
with MF_Ratio as
(select  c.states , sum( case when c.gender='Male' then 1 else 0 end )  as Male, round( avg(case when c.gender='Male' then c.Age else 0 end) ) as Male_Age_Av,
sum(case when c.gender='Female' then 1 else 0 end )  as Female , round(avg(case when c.gender='Female' then c.Age else 0 end) ) as Female_Age_Av
from customer as c join orders as o on o.C_ID=c.C_ID group by c.states order by male desc, female desc)
select *, round((Male::Float/Female::Float)::Numeric,2)   as Female_Male_Ratio from MF_Ratio; 

-- 2.	What is the min age and max age of customers per city along with total customer ?
select c.city, round(min(c.age)) as Min_Age,round(max(c.age)) as Max_Age,
round(avg(c.age)) as Avg_Age , count(*) as total_customer from customer as c where c.C_ID in 
(select o.C_ID from orders as o where o.C_ID=c.C_ID) group by c.city order by total_customer desc;

-- 3.	Which cities have the top 2 highest number of young customers and which have lowest (age < 25) genderwise?
select * from 
(select c.city , sum(case when c.gender='Male' then 1 else 0 end ) as Male , sum(case when c.gender='Female' then 1 else 0 end ) as Female
from customer as c where c.C_ID in (select  o.C_ID from orders as o where o.C_ID=c.C_ID ) and c.Age<=25 group by c.city
order by Male asc, Female asc limit 2) as max_city union all
select * from 
(select c.city , sum(case when c.gender='Male' then 1 else 0 end ) as Male , sum(case when c.gender='Female' then 1 else 0 end ) as Female
from customer as c where c.C_ID in (select o.C_ID from orders as o where o.C_ID=c.C_ID ) and c.Age<=25 group by c.city
order by Male desc, Female desc limit 2) as min_city ;

-- 4.	How many  customers are there in each state yearwise , top 10?
select c.states,sum( case  when extract('year' from o.Order_Date)=2024 then 1 else 0 end) as Year_2024,  
sum(case when extract('year' from o.Order_Date)=2023 then 1 else 0 end) as Year_2023 from customer as c join
 orders as o on o.C_ID=c.C_ID group by c.states order by Year_2024 desc , Year_2023 desc limit 10;

-- 5.	What is the male to female customer percentage in different month as compared to previous month ?
select month_name, case when male is null then 0 else male end as male , 
case when female is null then 0 else female end as female from 
(with mnth_mf as
(select month_name, male,lag(male,1) over (order by months) as pre_month_male,female,lag(female,1) over (order by months) as pre_month_female from 
(select to_char(o.order_date,'month' ) as month_name, extract( 'month' from o.order_date ) as months  ,  
sum(case when c.gender='Male' then 1 else 0 end ) as Male,sum(case when c.gender='Female' then 1 else 0 end ) as Female 
from customer as c join orders as o on o.C_ID=c.C_ID group by month_name , months) as mf_prct)
select month_name,round( ((male::float-pre_month_male::float)/(pre_month_male::float))::numeric,2)*100 as Male,
round( ((female::float-pre_month_female::float)/(pre_month_female::float))::numeric,2)*100 as Female from mnth_mf) as mfn;

-- 6.	Which state has the most diverse age group among customers?
with age_gp as 
(select *, case when age between 18 and 25 then '18-25' when age between 26 and 35 then '26-35' when age between 36 and 45 then '36-45'
when age between 45 and 60 then '45-60' else '>60' end as age_grp from customer) 
select c.states,sum(case when c.age_grp='18-25' then 1 else 0 end) as "18-25",sum(case when c.age_grp='26-35' then 1 else 0 end) as "26-35",
sum(case when c.age_grp='36-45' then 1 else 0 end) as "36-45",sum(case when c.age_grp='45-60' then 1 else 0 end) as "45-60",
sum(case when c.age_grp='>60' then 1 else 0 end) as ">60" from age_gp as c join orders as o on o.C_ID=c.C_ID group by c.states order by "18-25" desc,
"26-35" desc, "36-45" desc, "45-60" desc, ">60" desc limit 10 ;

-- 7.	Create a customer age band (e.g., 18–25, 26–35...) and count how many customers fall in each brandwise.
with age_gp as 
(select *, case when age between 18 and 25 then '18-25' when age between 26 and 35 then '26-35' when age between 36 and 45 then '36-45'
when age between 45 and 60 then '45-60' else '>60' end as age_grp from customer) 
select p.company_name,sum(case when c.age_grp='18-25' then 1 else 0 end) as "18-25",sum(case when c.age_grp='26-35' then 1 else 0 end) as "26-35",
sum(case when c.age_grp='36-45' then 1 else 0 end) as "36-45",sum(case when c.age_grp='45-60' then 1 else 0 end) as "45-60",
sum(case when c.age_grp='>60' then 1 else 0 end) as ">60" from age_gp as c join orders as o on o.C_ID=c.C_ID join product as p on p.P_ID=o.P_ID
group by p.company_name order by  "18-25" desc, "26-35" desc, "36-45" desc, "45-60" desc, ">60" desc limit 5 ;

-- 8.	Find top 20 customers who have placed the most orders?
select c.C_Name, count(*) as total_customer from customer as c join orders as o on o.C_ID=c.C_ID 
group by c.C_Name order by total_customer desc limit 20;

-- 9.	Identify the top 3 cities where Nykaa has the lowest  and highestcustomer percent growth yearwise.
select * from 
(select * , round(((year_2024::float-year_2023::float)/(year_2023::float)*100)::numeric,2) as year_growth from
(with orders as (select *,extract('year'  from order_date) as years from orders) 
select c.city, sum(case when years=2024 then 1 else 0 end ) as year_2024, sum(case when years=2023 then 1 else 0 end ) as year_2023
 from customer as c join orders as o on o.C_ID=c.C_ID group by c.city ) as csk order by year_growth desc limit 3)
 union all
 select * from 
(select * , round(((year_2024::float-year_2023::float)/(year_2023::float)*100)::numeric,2) as year_growth from
(with orders as (select *,extract('year'  from order_date) as years from orders) 
select c.city, sum(case when years=2024 then 1 else 0 end ) as year_2024, sum(case when years=2023 then 1 else 0 end ) as year_2023
 from customer as c join orders as o on o.C_ID=c.C_ID group by c.city ) as csk order by year_growth asc limit 3);

 --10.  Calculate the percent proportion of customers in each state compared to the total customer base yearwise
select city, round(((year_2024::float/sum(year_2024) over() ::float*100)::numeric),2)   as "% Customer Year 2024" ,
round(((year_2023::float/sum(year_2023) over() ::float*100)::numeric),2)   as "% Customer Year 2023" from
(with orders as (select *,extract('year'  from order_date) as years from orders) 
select c.city, sum(case when years=2024 then 1 else 0 end ) as year_2024, sum(case when years=2023 then 1 else 0 end ) as year_2023
 from customer as c join orders as o on o.C_ID=c.C_ID group by c.city) as cst_prct order by "% Customer Year 2024" desc , "% Customer Year 2023" desc;

/* Product Analysis */
-- 11.	Which category has the highest number of buyers yearwise , along with its total qty?
with ordr_pct as 
(with orders as 
(select *, extract('year' from order_date ) as years from orders) select p.category,
sum(case when o.years=2024 then 1 else 0 end ) as year_2024 , sum(case when o.years=2024 then o.qty else 0 end ) as year_2024_qty,
sum(case when o.years=2023 then 1 else 0 end ) as year_2023 , sum(case when o.years=2023 then o.qty else 0 end ) as year_2023_qty
from product as p join orders as o on o.P_ID = p.P_ID where o.C_ID in (select c.C_ID from customer as c where c.C_ID=o.C_ID )
group by p.category ) select category, year_2024,year_2023, round(((year_2024::float-year_2023::float)/year_2023::float*100)::numeric,2) as "Customer Percentage",
year_2024_qty,year_2023_qty, round(((year_2024_qty::float-year_2023_qty::float)/year_2023_qty::float*100)::numeric,2) as "Quantity Percentage" from 
ordr_pct order by "Customer Percentage" desc, "Quantity Percentage" desc;

-- 12.	What is the average sale of company along with its total quantity by product gender?
select p.company_name,concat('₹ ',round( avg( case when p.p_gender='Men' then  p.price*o.qty*(1-o.discount/100) else 0 end )::numeric,2)) as Men_avg_sales,
sum( case when p.p_gender='Men' then  o.qty else 0 end ) as Men_Qty,
concat('₹ ', round(avg( case when p.p_gender='Women' then  p.price*o.qty*(1-o.discount/100) else 0 end)::numeric,2)) as Women_avg_sales,
 sum( case when p.p_gender='Women' then  o.qty else 0 end ) as Women_Qty,
concat('₹ ',round(avg( case when p.p_gender='Unisex' then  p.price*o.qty*(1-o.discount/100) else 0 end)::numeric,2)) as Unisex_avg_sales,
 sum( case when p.p_gender='Unisex' then  o.qty else 0 end ) as Unisex_Qty
from orders as o join product as p on p.P_ID=o.P_ID
where o.C_ID in (select c.C_ID from customer as c ) group by p.company_name ;

-- 13.	Get the count of products for each company, along with  price range , product rating
select p.company_name,count(o.Or_ID) as total_product,concat(min(p.price),' - ',max(p.price) ) as price_range ,round(avg(r.prod_rating)::numeric,2) as prod_rating
from product as p join orders as o on o.P_ID=p.P_ID join rating as r on r.Or_ID=o.Or_ID 
where o.C_ID in (select c.C_ID from customer as c where c.C_ID=o.C_ID) group by p.company_name;

-- 14.	List the top 5 least frequently bought product categories based on its quantity, yearwise ?
with orders as (select *,extract('year' from order_date) as years from orders) select p.category,
sum(case when o.years=2024 then o.qty else 0 end ) as year_2024,sum(case when o.years=2023 then o.qty else 0 end ) as year_2023
from product as p join orders as o on o.P_ID=p.P_ID where o.C_ID in (select c.C_ID from customer as c where c.C_ID=o.C_ID ) 
group by p.category order by  year_2024 asc, year_2023 asc limit 5;

-- 15.	Identify brands for women's clothing for total orders,its quantity and its rating
with orders as (select *, extract('years' from order_date) as years from orders), products as (select * from product where p_gender='Women')
select p.company_name, sum(case when o.years=2024 then 1 else 0 end ) as year_2024,sum(case when o.years=2024 then qty else 0 end ) as year_2024_qty,
round(avg(case when o.years=2024 then r.prod_rating else 0 end )::numeric,2) as year_2024_rating,
sum(case when o.years=2023 then 1 else 0 end ) as year_2023,sum(case when o.years=2023 then qty else 0 end ) as year_2023_qty,
round(avg(case when o.years=2023 then r.prod_rating else 0 end )::numeric,2) as year_2023_rating from products as p join orders as o on o.P_ID=p.P_ID
join rating as r on r.Or_ID=o.Or_ID where o.C_ID in (select c.C_ID from customer as c where c.C_ID=o.C_ID) group by p.company_name order by 
year_2024_rating desc, year_2023_rating desc;

-- 16.	Identify the Companies that have products priced above ₹300, its orders, Qty and rating product_genderwise
with product as (select * from product where price>300) select p.company_name,
sum(case when p.p_gender='Men' then 1 else 0 end ) as Male_orders,sum(case when p.p_gender='Men' then o.qty else 0 end ) as Male_Qty,
round(avg(case when p.p_gender='Men' then r.prod_rating else 0 end)::numeric,2 ) as Male_rating,
sum(case when p.p_gender='Women' then 1 else 0 end ) as Female_orders,sum(case when p.p_gender='Women' then o.qty else 0 end ) as Female_Qty,
round(avg(case when p.p_gender='Women' then r.prod_rating else 0 end)::numeric,2 ) as Female_rating,
sum(case when p.p_gender='Unisex' then 1 else 0 end ) as Unisex_orders,sum(case when p.p_gender='Unisex' then o.qty else 0 end ) as Unisex_Qty,
round(avg(case when p.p_gender='Unisex' then r.prod_rating else 0 end)::numeric,2 ) as Unisex_rating from product as p join orders as o on 
o.P_ID=p.P_ID join rating as r on r.Or_ID=o.Or_ID where o.C_ID in (select c.C_ID from customer as c where c.C_ID=o.C_ID ) group by p.company_name;

-- 17.	Which product category has the highest average price and which is the lowest,its price range,qty ,sales, and rating?
select * from 
(select p.category, round(avg(p.price)::numeric,2)as price ,concat( min(p.price),' - ',max(p.price)) as price_range, sum(o.qty),
concat('₹ ', round(( sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100) )::numeric,2)) as sales,round(avg(r.prod_rating)::numeric,2) as rating from product as p join 
orders as o on o.P_ID=p.P_ID join rating as r on r.Or_ID=o.Or_ID where o.C_ID in (select c.C_ID from customer as c where c.C_ID=o.C_ID) group by p.category
order by price desc limit 1) union all
select * from 
(select p.category, round(avg(p.price)::numeric,2)as price ,concat( min(p.price),' - ',max(p.price)) as price_range, sum(o.qty) as Quantity,
concat('₹ ',round(( sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100) )::numeric,2)) as sales,round(avg(r.prod_rating)::numeric,2) as rating from product as p join 
orders as o on o.P_ID=p.P_ID join rating as r on r.Or_ID=o.Or_ID where o.C_ID in (select c.C_ID from customer as c where c.C_ID=o.C_ID) group by p.category
order by price asc limit 1);

-- 18.	Enumerate the top 3 product  that are the most and then the least popular , based on orders,qty and sales 
with orders as (select *, extract('years' from order_date) as years from orders) 
select p.p_name, sum(case when o.years=2024 then 1 else 0 end )  as total_order_2024 ,sum(case when o.years=2023 then 1 else 0 end )  as total_order_2023 , 
sum(case when o.years=2024 then o.qty else 0 end )  as total_qty_2024 ,sum(case when o.years=2023 then o.qty else 0 end )  as total_qty_2023,
round(sum(case when o.years=2024 then p.price*o.qty*(1-o.discount/100)  else 0 end)::numeric,2)  as total_sales_2024 ,
round(sum(case when o.years=2023 then p.price*o.qty*(1-o.discount/100)  else 0 end)::numeric,2)  as total_sales_2023 from orders as o  join product as p
on o.P_ID=p.P_ID where o.C_ID in (select c.C_ID from customer as c where c.C_ID=o.C_ID ) group by p.p_name  order by total_order_2024  desc,total_order_2023 desc
limit 20;

-- 19.	List the top 5 least frequently bought product categories genderwise , along with its quamtity
select p.category,sum(case when p.p_gender='Men' then 1 else 0 end ) as men_order,sum(case when p.p_gender='Men' then o.qty else 0 end ) as men_qty,
sum(case when p.p_gender='Women' then 1 else 0 end ) as women_order,sum(case when p.p_gender='Women' then o.qty else 0 end ) as women_qty,
sum(case when p.p_gender='Unisex' then 1 else 0 end ) as unisex_order,sum(case when p.p_gender='Unisex' then o.qty else 0 end ) as unisex_qty
from orders as o join product as p on p.P_ID=o.P_ID where o.C_ID in (select c.C_ID from customer as c where c.C_ID=o.C_ID) group by p.category
order by men_order asc,women_order asc,unisex_order asc;


/* Orders Analysis */
-- 21. Retrieve  total sales ,total orders placed, total customer ordered ,total quantity sold , AOV, revenue per customer using sales table .
select concat('₹ ',round((sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100))::numeric,2)) as total_sales,count(o.Or_ID) as total_orders ,
count( distinct o.C_ID) as total_customer_ordered, sum(o.qty) as total_quantity_sold, 
concat('₹ ',round( (sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100)/count(o.Or_ID)) :: numeric,2)) as Average_Order_Value,
concat('₹ ', round( (sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100)/count(distinct o.C_ID)) :: numeric,2)) as Revenue_per_Customer
from product as p join orders as o on o.P_ID=p.P_ID join customer as c on c.C_ID=o.C_ID ;

-- 22. Determine the peak time periods (morning, afternoon, evening, night) when the highest number of orders are placed.
with orders as 
(with orders as (select *, extract('hours' from order_time ) as hours from orders)
select *, case when hours between 6 and 11 then 'Morning' when hours between 12 and 17 then 'Afternoon' when hours between 18 and 22 then 'Evening' 
else 'Night' end as Hr_Prt from orders)
select o.Hr_Prt,count(o.Or_ID) as total_orders, sum(o.Qty) as total_qty , count(distinct o.C_ID ) as total_customer
from orders as o join customer as c on c.C_ID=o.C_ID join product as p on p.P_ID=o.P_ID group by o.Hr_Prt order by total_customer desc;

-- 23. Identify the top 20 customers with the most orders placed within the past 6 month , latest date is considered from 31/12/2024.
with orders as 
(select * from orders where  order_date>=(select max(order_date)-interval '6 month' from orders) and  order_date<=(select max(order_date) from orders))
select c.c_name,count(p.P_ID) as total_product, sum(o.qty) as quantity, round(avg(r.prod_rating)::numeric,2) as total_rating,
round((sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100))::numeric,2) as total_amount from product as p join orders as o on o.P_ID=p.P_ID join 
customer as c on c.C_ID=o.C_ID join rating as r on r.Or_ID=o.Or_ID group by c.C_Name order by total_amount desc limit 20;

-- 24. Analyze the trend of products ordered based on month, yearwise.
with order_month as (with orders as 
(select * ,extract('month' from order_date) as M,to_char(order_date,'month') as months,extract('year' from order_date) as years from orders ) 
select o.months,sum(case when o.years=2024 then 1 else 0 end) as order_2024,sum(case when o.years=2023 then 1 else 0 end) as order_2023, 
sum(case when o.years=2024 then o.qty else 0 end) as qty_2024,sum(case when o.years=2023 then o.qty else 0 end) as qty_2023,
round(sum(case when o.years=2024 then o.qty*p.price*(1-o.discount/100)  else 0 end)::numeric,2)   as sales_2024,
round(sum(case when o.years=2023 then o.qty*p.price*(1-o.discount/100) else 0 end)::numeric,2)   as sales_2023
from orders as o join product as p on p.P_ID=o.P_ID join customer as c on c.C_ID=o.C_ID group by o.months,o.m order by o.m asc)
select months,order_2024,order_2023, round(((order_2024-order_2023)/order_2023*100) ::numeric,2) as "%_order_change",
qty_2024,qty_2023,round(((qty_2024-qty_2023)/qty_2023*100)::numeric,2) as "%_qty_change",
sales_2024,sales_2023,
round(((sales_2024-sales_2023)/sales_2023*100)::numeric,2) as "%_sales_change" from order_month;

-- 25. Find the top 5 companies that generated the highest revenue in a given year.
with orders as (select *,extract('year' from order_date) as years from orders)
select p.company_name,sum(case when o.years=2024 then 1 else 0 end) as order_2024,sum(case when o.years=2023 then 1 else 0 end) as order_2023,
sum(case when years=2024 then o.qty else 0 end) as qty_2024,sum(case when years=2023 then o.qty else 0 end) as qty_2023,
round(sum(case when o.years=2024 then o.qty*p.price*(1-o.discount/100) else 0 end)::numeric,2) as sales_2024,
round(sum(case when o.years=2023 then o.qty*p.price*(1-o.discount/100) else 0 end)::numeric,2) as sales_2023,
round(avg( case when o.years=2024 then r.prod_rating else 0 end)::numeric,2) as rating_2024,
round(avg( case when o.years=2023 then r.prod_rating else 0 end)::numeric,2) as rating_2024
from orders as o join product as p on p.P_ID=o.P_ID join customer as c on c.C_ID=o.C_ID join rating as r on r.Or_ID=o.Or_ID group by p.company_name
order by sales_2024 desc, sales_2023 desc limit 5;

-- 26. Evaluate the impact of discounts by comparing company  sales before and after discounts are applied, product gender wise
select p.company_name,round(sum(case when p.p_gender='Men' then o.qty*p.price  else 0 end)::numeric,2) as before_discount_men,
round(sum(case when p.p_gender='Men' then o.qty*p.price*(1-o.discount/100) else 0 end)::numeric,2) as after_discount_men,
round(sum(case when p.p_gender='Women' then o.qty*p.price  else 0 end)::numeric,2) as before_discount_women,
round(sum(case when p.p_gender='Women' then o.qty*p.price*(1-o.discount/100)  else 0 end)::numeric,2) as after_discount_women,
round(sum(case when p.p_gender='Unisex' then o.qty*p.price  else 0 end)::numeric,2) as before_discount_unisex,
round(sum(case when p.p_gender='Unisex' then o.qty*p.price*(1-o.discount/100)  else 0 end)::numeric,2) as after_discount_unisex
from product as p join orders as o on o.P_ID=p.P_ID where o.C_ID in (select c.C_ID from customer as c where c.C_ID=o.C_ID)
group by p.company_name;

-- 27. Identify the top-selling brand within each state.
select states,company_name,total_sales from 
(with st_cmp as (select c.states,p.company_name,round((sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100)/count(o.Or_ID)) :: numeric,2) as total_sales
from customer as c join orders as o on o.C_ID=c.C_ID join product as p on p.P_ID=o.P_ID group by c.states,p.company_name )
select *, dense_rank() over(partition by states order by total_sales desc) as ranks from st_cmp) as rnks
where rnks.ranks=1 order by total_sales desc;

-- 28. Calculate the total number of orders per product where customers used a discount of less than 20%.
select p.p_name,p.company_name,count(o.Or_ID) as total_orders,sum(o.qty) as Qty,
round((sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100)/count(o.Or_ID)) :: numeric,2) as sales from 
product as p join orders as o on o.P_ID=p.P_ID group by p.p_name,p.company_name having avg(o.discount)<20
order by sales desc limit 10;

-- 29. Determine the top 20 products based on total order quantity, along with their average customer age, order amount, and product rating.
select p.p_name,p.category,p.company_name,count(o.Or_ID) as total_orders,sum(o.qty) as Qty,
round((sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100)/count(o.Or_ID)) :: numeric,2) as sales ,
round( avg(r.prod_rating)::numeric,2) as rating from product as p join orders as o on o.P_ID=p.P_ID 
join rating as r on r.Or_ID=o.Or_ID where o.C_ID in (select c.C_ID from customer as c where c.C_ID=o.C_ID )
group by p.p_name,p.category,p.company_name  order by sales desc limit 20;

-- 30. Calculate  MOM sales yearwise
with mom_sales as
(select months,sales_2024,lag(sales_2024,1) over() as pre_sales_2024, sales_2023,lag(sales_2023,1) over() as pre_sales_2023 from 
(with orders as (select *,extract('months' from order_date) as m, to_char(order_date,'month') as months ,
extract('years' from order_date) as years from orders ) select o.months,
round(sum(case when years=2024 then o.qty*p.price*(1-o.discount/100) else 0 end )::numeric,2)  as sales_2024,
round(sum(case when years=2023 then o.qty*p.price*(1-o.discount/100) else 0 end )::numeric,2)  as sales_2023
from product as p join orders as o on o.P_ID=p.P_ID where o.C_ID in (select c.C_ID from customer as c where c.C_ID=o.C_ID)
group by months,m order by m asc) as M_sales)
select months,  round((sales_2024-pre_sales_2024)/pre_sales_2024*100::numeric,2) as MOM_Sales_2024,
 round((sales_2023-pre_sales_2023)/pre_sales_2023*100::numeric,2) as MOM_Sales_2023 from mom_sales;


/* Transaction Analysis */
-- 31. Determine how many rewards were given and and how many not in different transaction mode,  overall.
select t.transaction_mode,sum(case when t.reward = 'Yes' then 1 else 0 end ) as Reward_Yes,
sum(case when t.reward='No' then 1 else 0 end ) as Reward_No from transactions as t join orders as o on
o.Or_ID=t.Or_ID join customer as c on c.C_ID=o.C_ID group by t.transaction_mode order by Reward_Yes desc ;

-- 32. Determine the company and the number of rewards offered for each transaction.
with transactions as (select * from transactions where reward='Yes')
select p.company_name, sum(case when t.transaction_mode='Wallet' then 1 else 0 end ) as Wallet,
sum(case when t.transaction_mode='Net Banking' then 1 else 0 end ) as Net_Banking,
sum(case when t.transaction_mode='Debit Card' then 1 else 0 end ) as Debit_Card,
sum(case when t.transaction_mode='UPI' then 1 else 0 end ) as UPI,
sum(case when t.transaction_mode='Credit Card' then 1 else 0 end ) as Credit_Card
from transactions as t join orders as o on o.Or_ID=t.Or_ID join product as p on p.P_ID=o.P_ID
group by p.company_name ;

-- 33. Find out which transaction method clients use most frequently,along with its total amount transcation yearwise .
with ord_tr as 
(with orders as (select *,extract('year' from order_date) as years from orders ) 
select t.transaction_mode,
sum(case when o.years=2024 then 1 else 0 end) as transactions_2024,
sum(case when o.years=2023 then 1 else 0 end) as transactions_2023,
round(sum(case when o.years=2024 then o.qty*p.price*(1-o.discount/100) else 0 end ):: numeric,2)  as amount_2024,
round(sum(case when o.years=2023 then o.qty*p.price*(1-o.discount/100) else 0 end )::numeric,2)  as amount_2023
from transactions as t join orders as o on o.Or_ID=t.Or_ID join product as p on p.P_ID=o.P_ID group by t.transaction_mode)
select transaction_mode,transactions_2024,transactions_2023, 
concat('₹ ', amount_2024) as amount_2024, concat('₹ ', amount_2023) as amount_2023,
concat( round((amount_2024-amount_2023)/amount_2023*100::numeric,2),' %') as amount_change from ord_tr;

-- 34. Determine which transaction mode has the largest no-reward percentage.
with tr_nor as 
(select t.transaction_mode,count(o.Or_ID) as total_orders  from transactions as t join orders as o on o.Or_ID=t.Or_ID where t.reward='No'
group by t.transaction_mode order by total_orders desc)
select *,concat(round((total_orders/(sum(total_orders) over ()) )*100::numeric,2),' %') as Transaction_No_Rewards from tr_nor;

-- 35. Determine each state's total transactions along with average transaction amount, yearwise.
with orders as (select * ,extract('year' from order_date) as years from orders) 
select c.states,sum(case when years=2024 then 1 else 0 end ) as transaction_2024,
sum(case when years=2023 then 1 else 0 end ) as transaction_2023,
round(avg(case when o.years=2024 then o.qty*p.price*(1-o.discount/100) else 0 end ):: numeric,2) as amount_2024,
round(avg(case when o.years=2023 then o.qty*p.price*(1-o.discount/100) else 0 end ):: numeric,2) as amount_2023
from transactions as t join orders as o on o.Or_ID=t.Or_ID join customer as c on c.C_ID=o.C_ID 
join product as p on p.P_ID=o.P_ID  group by c.states;

-- 36. Obtain a monthly summary of all transactions along with amount .
with orders as (select * ,extract('year' from order_date) as years,to_char(order_date,'month') as months,
extract('month' from order_date) as m from orders) 
select o.months,sum(case when years=2024 then 1 else 0 end ) as transaction_2024,
sum(case when years=2023 then 1 else 0 end ) as transaction_2023,
round(avg(case when o.years=2024 then o.qty*p.price*(1-o.discount/100) else 0 end ):: numeric,2) as amount_2024,
round(avg(case when o.years=2023 then o.qty*p.price*(1-o.discount/100) else 0 end ):: numeric,2) as amount_2023
from transactions as t join orders as o on o.Or_ID=t.Or_ID join customer as c on c.C_ID=o.C_ID 
join product as p on p.P_ID=o.P_ID  group by o.months,o.m order by o.m asc;

-- 37. Determine which company has the most no-rewards transactions and how many have , transaction mode wise.
with tr1 as
(with transactions as (select * from transactions where reward='Yes') 
select p.company_name, count(case when t.transaction_mode='Wallet' then o.Or_ID else null end ) as Wallet_Yes,
count(case when t.transaction_mode='Net Banking' then o.Or_ID else null end ) as Net_Banking_Yes,
count(case when t.transaction_mode='Debid Card' then o.Or_ID else null end ) as Debid_Card_Yes,
count(case when t.transaction_mode='UPI' then o.Or_ID else null end ) as UPI_Yes,
count(case when t.transaction_mode='Credid Card' then o.Or_ID else null end ) as Credid_Card_Yes
from transactions as t join orders as o on o.Or_ID=t.Or_ID join product as p on 
o.P_ID=p.P_ID group by p.company_name) ,
 tr2 as
(with transactions as (select * from transactions where reward='No') 
select p.company_name, count(case when t.transaction_mode='Wallet' then o.Or_ID else null end ) as Wallet_No,
count(case when t.transaction_mode='Net Banking' then o.Or_ID else null end ) as Net_Banking_No,
count(case when t.transaction_mode='Debid Card' then o.Or_ID else null end ) as Debid_Card_No,
count(case when t.transaction_mode='UPI' then o.Or_ID else null end ) as UPI_No,
count(case when t.transaction_mode='Credid Card' then o.Or_ID else null end ) as Credid_Card_No
from transactions as t join orders as o on o.Or_ID=t.Or_ID join product as p on 
o.P_ID=p.P_ID group by p.company_name) 
select t1.company_name,t1.Wallet_Yes,t2.Wallet_No,t1.Net_Banking_Yes,t2.Net_Banking_No,t1.UPI_Yes,t2.UPI_No,
t1.Debid_Card_Yes,t2.Debid_Card_No, t1.Credid_Card_Yes,t2.Credid_Card_No from tr1 as t1 join tr2 as t2 on t1.company_name=t2.company_name;


/* Ratings & Customer Feedback */
-- 41. Determine each product category's average rating and mark the top 10, product gender wise.
select p.category,round(avg(case when p.p_gender='Men' then prod_rating else 0 end )::numeric,2)  as Men,
round(avg(case when p.p_gender='Women' then prod_rating else 0 end )::numeric,2)  as Women,
round(avg(case when p.p_gender='Unisex' then prod_rating else 0 end )::numeric,2)  as Unisex
from product as p join orders as o on o.P_ID=p.P_ID join rating as r on r.Or_ID=o.Or_ID 
group by p.category order by Men desc, Women desc, Unisex desc ;

-- 42. Determine which products, by company, got the best ratings and which got the worst.
with total_ranks as 
(select * from 
(with rkd1 as 
(select company_name,p_name, p_ratings,row_number() over(partition by company_name order by p_ratings desc ) as ranks from
(select p.company_name,p.p_name,round( avg(r.prod_rating) :: numeric,2) as p_ratings from product as p join orders as o on
o.P_ID=p.P_ID join rating as r on r.Or_ID=o.Or_ID group by p.company_name,p.p_name) as rnks) 
select * from rkd1 where ranks = (select min(ranks) from rkd1 )) union all
select * from
(with rkd2 as
(select company_name,p_name, p_ratings,row_number() over(partition by company_name order by p_ratings asc ) as ranks from
(select p.company_name,p.p_name,round( avg(r.prod_rating) :: numeric,2) as p_ratings from product as p join orders as o on
o.P_ID=p.P_ID join rating as r on r.Or_ID=o.Or_ID group by p.company_name,p.p_name) as rnks)
select * from rkd2 where ranks = (select min(ranks) from rkd2 )))
select company_name,p_name,p_ratings  from total_ranks order by company_name asc,p_ratings desc ;

-- 43. Determine the number of orders, city-by-city, with a delivery rating where delivery rating below 3, delivery_partner wise
with ratings as (select * from rating where delivery_service_rating<=3 ) 
select c.city, 
sum(case when d.dp_name='Delhivery' then 1 else 0 end) as Delhivery_orders,
round(avg(case when d.dp_name='Delhivery' then r.delivery_service_rating else 0 end)::numeric,2)  as Delhivery_rating,
sum(case when d.dp_name='Ecom Express' then 1 else 0 end) as Ecom_Express_orders,
round(avg(case when d.dp_name='Ecom Express' then r.delivery_service_rating else 0 end)::numeric,2)  as Ecom_Express_rating,
sum(case when d.dp_name='Blue Dart' then 1 else 0 end) as Blue_Dart_orders,
round(avg(case when d.dp_name='Blue Dart' then r.delivery_service_rating else 0 end)::numeric,2)  as Blue_Dart_rating,
sum(case when d.dp_name='Xpressbees' then 1 else 0 end) as Xpressbees_orders,
round(avg(case when d.dp_name='Xpressbees' then r.delivery_service_rating else 0 end)::numeric,2)  as Xpressbees_rating,
sum(case when d.dp_name='Shadowfax' then 1 else 0 end) as Shadowfax_orders,
round(avg(case when d.dp_name='Shadowfax' then r.delivery_service_rating else 0 end)::numeric,2)  as Shadowfax_rating
from customer as c join orders as o on o.C_ID=c.C_ID join delivery as d on d.DP_ID=o.DP_ID join ratings as r on 
r.Or_ID=o.Or_ID group by c.city order by c.city asc ;

-- 44. Determine which delivery partner has the highest overall company rating.
with comp_rt as 
(select p.company_name, 
round(avg(case when d.dp_name='Delhivery' then r.delivery_service_rating else 0 end)::numeric,2)  as Delhivery_rating,
round(avg(case when d.dp_name='Ecom Express' then r.delivery_service_rating else 0 end)::numeric,2)  as Ecom_Express_rating,
round(avg(case when d.dp_name='Blue Dart' then r.delivery_service_rating else 0 end)::numeric,2)  as Blue_Dart_rating,
round(avg(case when d.dp_name='Xpressbees' then r.delivery_service_rating else 0 end)::numeric,2)  as Xpressbees_rating,
round(avg(case when d.dp_name='Shadowfax' then r.delivery_service_rating else 0 end)::numeric,2)  as Shadowfax_rating
from product as p join orders as o on p.P_ID=o.P_ID join rating as r on r.Or_ID=o.Or_ID join delivery as d on d.DP_ID=o.DP_ID
group by p.company_name)
select * , round((Delhivery_rating+Ecom_Express_rating+Blue_Dart_rating+Xpressbees_rating+Shadowfax_rating)/5::numeric,2) 
as overall_rating from comp_rt order by overall_rating desc; 

-- 45. Determine which customers, by category, gave the highest and lowest product ratings.
with total_ranks as 
(select * from 
(with rkd1 as 
(select category,c_name, p_ratings,row_number() over(partition by category order by p_ratings desc ) as ranks from
(select p.category,c.c_name,round( avg(r.prod_rating) :: numeric,2) as p_ratings from product as p join orders as o on
o.P_ID=p.P_ID join rating as r on r.Or_ID=o.Or_ID join customer as c on c.C_ID=o.C_ID group by p.category,c.c_name) as rnks) 
select * from rkd1 where ranks = (select min(ranks) from rkd1 )) union all
select * from
(with rkd2 as
(select category,c_name, p_ratings,row_number() over(partition by category order by p_ratings asc ) as ranks from
(select p.category,c.c_name,round( avg(r.prod_rating) :: numeric,2) as p_ratings from product as p join orders as o on
o.P_ID=p.P_ID join rating as r on r.Or_ID=o.Or_ID join customer as c on c.C_ID=o.C_ID group by p.category,c.c_name) as rnks)
select * from rkd2 where ranks = (select min(ranks) from rkd2 )))
select category,c_name,p_ratings  from total_ranks order by category asc,p_ratings asc ;

-- 46. Look for state, broken down by company name , who have regularly given delivery partners ratings higher than four stars.
with ratings as (select * from rating where delivery_service_rating>=4 )
select c.states,
sum(case when p.company_name='Puma' then 1 else 0 end ) as Puma,
sum(case when p.company_name='Gap' then 1 else 0 end ) as Gap,
sum(case when p.company_name='Pantaloons' then 1 else 0 end ) as Pantaloons,
sum(case when p.company_name='Reebok' then 1 else 0 end ) as Reebok,
sum(case when p.company_name='Adidas' then 1 else 0 end ) as Adidas,
sum(case when p.company_name like 'Levi%' then 1 else 0 end ) as Levis,
sum(case when p.company_name='H&M' then 1 else 0 end ) as H_M,
sum(case when p.company_name='Zara' then 1 else 0 end ) as Zara,
sum(case when p.company_name='Uniqlo' then 1 else 0 end ) as Uniqlo,
sum(case when p.company_name='Nike' then 1 else 0 end ) as Nike
from customer as c join orders as o on o.C_ID=c.C_ID join product as p on p.P_ID=o.P_ID join ratings as r
on r.Or_ID=o.Or_ID group by c.states;

-- 47. Refer the Months for which the product is substantially higher and lower product_rating.
with total_ranks as 
(select * from (with rnk1 as
(select *, row_number() over (partition by months order by p_rating desc ) as ranks from
(with orders as (select * ,to_char(order_date,'month')  as months,extract('month' from order_date) as m  from orders ) 
select o.months,o.m,p.p_name, round(avg(r.prod_rating)::numeric,2) as p_rating 
from product as p join orders as o on p.P_ID=o.P_ID join rating as r on r.Or_ID=o.Or_ID
group by o.months,o.m,p.p_name) as rnk )
select * from rnk1 where ranks = (select min(ranks) from rnk1 )) union all 
select * from 
(with rnk2 as
(select *, row_number() over (partition by months order by p_rating asc ) as ranks from
(with orders as (select * ,to_char(order_date,'month')  as months,extract('month' from order_date) as m  from orders ) 
select o.months,o.m,p.p_name, round(avg(r.prod_rating)::numeric,2) as p_rating 
from product as p join orders as o on p.P_ID=o.P_ID join rating as r on r.Or_ID=o.Or_ID
group by o.months,o.m,p.p_name) as rnk )
select * from rnk2 where ranks = (select min(ranks) from rnk2 )))
select months,p_name,p_rating from total_ranks order by m asc,p_rating desc;

-- 48. Determine each company's product rating by customer gender.
select p.company_name,
round(avg(case when c.gender='Male' then r.prod_rating else 0 end )::numeric,2)  as Male,
round(avg(case when c.gender='Female' then r.prod_rating else 0 end )::numeric,2)  as Female
from customer as c join orders as o on o.C_ID=c.C_ID join product as p on p.P_ID=o.P_ID join
rating as r on r.Or_ID=o.Or_ID group by p.company_name;


/* Delivery Partner Analysis */
-- 51. Determine the average rating for delivery partners, along with its amount get and orders handled, yearwise.
with orders as (select *, extract('year' from order_date) as years from orders )
select d.dp_name,
sum(case when o.years=2024 then 1 else 0 end ) as order_2024,
sum(case when o.years=2023 then 1 else 0 end ) as order_2023,
concat('₹ ',round(sum(case when o.years=2024 then o.qty*p.price*(1-o.discount/100)*(d.percent_cut/100)  else 0 end )::numeric,2))  as amount_2024,
concat('₹ ',round(sum(case when o.years=2023 then o.qty*p.price*(1-o.discount/100)*(d.percent_cut/100)  else 0 end )::numeric,2))  as amount_2023,
round(avg(case when o.years=2024 then r.delivery_service_rating else 0 end):: numeric,2) as rating_2024,
round(avg(case when o.years=2023 then r.delivery_service_rating else 0 end):: numeric,2) as rating_2023
from product as p join orders as o on o.P_ID=p.P_ID join rating as r on r.Or_ID=o.Or_ID join delivery 
as d on d.DP_ID=o.DP_ID group by  d.dp_name;

-- 52. Based on product category, determine which delivery partner has the lowest rating and which is highest.
with total_ranks as 
(select * from
(with rnk1 as 
(select *,row_number() over(partition by category order by p_rating desc ) as ranks from
(select p.category, d.dp_name,round(avg(r.delivery_service_rating)::numeric,2) as p_rating from product as p join orders as o 
on o.P_ID=p.P_ID join delivery as d on d.DP_ID=o.DP_ID join rating as r on r.Or_ID=o.Or_ID group by p.category, d.dp_name) as rnk)
select * from rnk1 where ranks=(select min(ranks) from rnk1))
union all
select * from
(with rnk2 as 
(select *,row_number() over(partition by category order by p_rating asc ) as ranks from
(select p.category, d.dp_name,round(avg(r.delivery_service_rating)::numeric,2) as p_rating from product as p join orders as o 
on o.P_ID=p.P_ID join delivery as d on d.DP_ID=o.DP_ID join rating as r on r.Or_ID=o.Or_ID group by p.category, d.dp_name) as rnk)
select * from rnk2 where ranks=(select min(ranks) from rnk2)))
select category,dp_name,p_rating from total_ranks order by category asc, p_rating desc;

-- 53. Find out how many orders each delivery partner has handled and how they are rated, by product gender .
select d.dp_name,
sum(case when p.p_gender='Men' then 1 else 0 end ) as Order_Men,
round(avg(case when p.p_gender='Men' then r.delivery_service_rating else 0 end)::numeric,2) as Rating_Men,
sum(case when p.p_gender='Women' then 1 else 0 end ) as Order_Women,
round(avg(case when p.p_gender='Women' then r.delivery_service_rating else 0 end)::numeric,2) as Rating_Women,
sum(case when p.p_gender='Unisex' then 1 else 0 end ) as Order_Unisex,
round(avg(case when p.p_gender='Unisex' then r.delivery_service_rating else 0 end)::numeric,2) as Rating_Unisex
from orders as o join product as p on p.P_ID=o.P_ID join delivery as d on d.DP_ID=o.DP_ID join rating as r 
on r.Or_ID=o.Or_ID group by d.dp_name;

-- 54. Determine which delivery partner processed the most returns, yearwise.
with orders as (select *, extract('year' from order_date) as years from orders)
select d.dp_name,
sum(case when o.years=2024 then 1 else 0 end ) as order_2024,
sum(case when o.years=2023 then 1 else 0 end ) as order_2023
from orders as o join delivery as d on d.DP_ID=o.DP_ID join return_refund as rr on rr.Or_ID=o.Or_ID
group by d.dp_name order by order_2024 desc,order_2023 desc;

-- 55. Determine the proportion of orders that each delivery partner handles per product category , along with percent cut get.
select p.category,sum(case when d.dp_name='Delhivery' then 1 else 0 end ) as order_Delhivery,
round(sum(case when d.dp_name='Delhivery' then o.qty*p.price*(1-o.discount/100)*(d.percent_cut/100) else 0 end )::numeric,2) as order_Delhivery,
sum(case when d.dp_name='Ecom Express' then 1 else 0 end ) as order_Ecom_Express,
round(sum(case when d.dp_name='Ecom Express' then o.qty*p.price*(1-o.discount/100)*(d.percent_cut/100) else 0 end )::numeric,2) as order_Ecom_Express,
sum(case when d.dp_name='Blue Dart' then 1 else 0 end ) as order_Blue_Dart,
round(sum(case when d.dp_name='Blue Dart' then o.qty*p.price*(1-o.discount/100)*(d.percent_cut/100) else 0 end )::numeric,2) as order_Blue_Dart,
sum(case when d.dp_name='Xpressbees' then 1 else 0 end ) as order_Xpressbees,
round(sum(case when d.dp_name='Xpressbees' then o.qty*p.price*(1-o.discount/100)*(d.percent_cut/100) else 0 end )::numeric,2) as order_Xpressbees,
sum(case when d.dp_name='Shadowfax' then 1 else 0 end ) as order_Shadowfax,
round(sum(case when d.dp_name='Shadowfax' then o.qty*p.price*(1-o.discount/100)*(d.percent_cut/100) else 0 end )::numeric,2) as order_Shadowfax
from product as p join orders as o on o.P_ID=p.P_ID join delivery as d on d.DP_ID=o.DP_ID group by p.category;

-- 56. Have each partner deliver for monthwise top and bottom orders, along with amount
with total_ranks as 
(select * from
(with rk1 as
(select *, row_number() over (partition by dp_name order by total_orders desc ) as ranks from
(with orders as (select *, to_char(order_date,'month') as months from orders) 
select d.dp_name,o.months , count(o.Or_ID) as total_orders, 
concat('₹ ',round(( sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100)*(avg(d.percent_cut)/100)) :: numeric,2)) as total_amount
from product as p join orders as o on o.P_ID=p.P_ID join delivery as d on d.dp_id=o.dp_id 
group by d.dp_name,o.months) as rnks)
select * from rk1 where ranks=(select min(ranks) from rk1 ))
union all
select * from
(with rk2 as
(select *, row_number() over (partition by dp_name order by total_orders asc ) as ranks from
(with orders as (select *, to_char(order_date,'month') as months from orders) 
select d.dp_name,o.months , count(o.Or_ID) as total_orders, 
concat('₹ ',round(( sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100)*(avg(d.percent_cut)/100)) :: numeric,2)) as total_amount
from product as p join orders as o on o.P_ID=p.P_ID join delivery as d on d.dp_id=o.dp_id 
group by d.dp_name,o.months) as rnks)
select * from rk2 where ranks=(select min(ranks) from rk2 )) )
select  dp_name,months,total_orders,total_amount from total_ranks order by dp_name asc, total_orders desc;

-- 57. Determine the product category and partner with the orders,rating and average price taken
with percent_ordr as 
(with delivery_al as 
(select p.category,
sum(case when d.dp_name='Delhivery' then 1 else 0 end ) as order_Delhivery,
round(avg(case when d.dp_name='Delhivery' then r.delivery_service_rating else 0 end)::numeric,2) as rating_Delhivery,
round(avg(case when d.dp_name='Delhivery' then p.price*o.qty*(1-o.discount/100)*(d.percent_cut/100) else 0 end)::numeric,2) as price_Delhivery,
sum(case when d.dp_name='Ecom Express' then 1 else 0 end ) as order_Ecom_Express,
round(avg(case when d.dp_name='Ecom Express' then r.delivery_service_rating else 0 end)::numeric,2) as rating_Ecom_Express,
round(avg(case when d.dp_name='Ecom Express' then p.price*o.qty*(1-o.discount/100)*(d.percent_cut/100) else 0 end)::numeric,2) as price_Ecom_Express,
sum(case when d.dp_name='Blue Dart' then 1 else 0 end ) as order_Blue_Dart,
round(avg(case when d.dp_name='Blue Dart' then r.delivery_service_rating else 0 end)::numeric,2) as rating_Blue_Dart,
round(avg(case when d.dp_name='Blue Dart' then p.price*o.qty*(1-o.discount/100)*(d.percent_cut/100) else 0 end)::numeric,2) as price_Blue_Dart,
sum(case when d.dp_name='Xpressbees' then 1 else 0 end ) as order_Xpressbees,
round(avg(case when d.dp_name='Xpressbees' then r.delivery_service_rating else 0 end)::numeric,2) as rating_Xpressbees,
round(avg(case when d.dp_name='Xpressbees' then p.price*o.qty*(1-o.discount/100)*(d.percent_cut/100) else 0 end)::numeric,2) as price_Xpressbees,
sum(case when d.dp_name='Shadowfax' then 1 else 0 end ) as order_Shadowfax,
round(avg(case when d.dp_name='Shadowfax' then r.delivery_service_rating else 0 end)::numeric,2) as rating_Shadowfax,
round(avg(case when d.dp_name='Shadowfax' then p.price*o.qty*(1-o.discount/100)*(d.percent_cut/100) else 0 end)::numeric,2) as price_Shadowfax
from product as p join orders as o on p.P_ID=o.P_ID join delivery as d on d.DP_ID=o.DP_ID join rating as r on r.Or_ID=o.Or_ID group by
p.category)
select *, (order_Delhivery+order_Ecom_Express+order_Blue_Dart+order_Xpressbees+order_Shadowfax) as overall_orders from delivery_al)
select category, order_Delhivery,rating_Delhivery,price_Delhivery,round( order_Delhivery/overall_orders*100::numeric,2) as "% order_Delhivery",
order_Ecom_Express,rating_Ecom_Express,price_Ecom_Express,round( order_Ecom_Express/overall_orders*100::numeric,2) as "% order_Ecom_Express",
order_Blue_Dart,rating_Blue_Dart,price_Blue_Dart,round( order_Blue_Dart/overall_orders*100::numeric,2) as "% order_Blue_Dart",
order_Xpressbees,rating_Xpressbees,price_Xpressbees,round( order_Xpressbees/overall_orders*100::numeric,2) as "% order_Xpressbees",
order_Shadowfax,rating_Shadowfax,price_Shadowfax,round( order_Shadowfax/overall_orders*100::numeric,2) as "% order_Shadowfax"
from percent_ordr ;

-- 58. Determine  delivery partners have delivered  including the total number of orders,qty, pret_cut and service rating, yearwise.
with orders as (select *, extract('year' from order_date) as years from orders)
select d.dp_name,
sum(case when years=2024 then 1 else 0 end ) as order_2024,
sum(case when years=2023 then 1 else 0 end ) as order_2023,
sum(case when years=2024 then o.qty else 0 end ) as qty_2024,
sum(case when years=2023 then o.qty else 0 end ) as qty_2023,
round(sum(case when years=2024 then o.qty*p.price*(1-o.discount/100)*(d.percent_cut/100)  else 0 end )::numeric,2) as prct_cut_2024,
round(sum(case when years=2023 then o.qty*p.price*(1-o.discount/100)*(d.percent_cut/100)  else 0 end )::numeric,2) as prct_cut_2023,
round(avg(case when years=2024 then r.delivery_service_rating else 0 end )::numeric,2)  as rating_2024,
round(avg(case when years=2023 then r.delivery_service_rating else 0 end )::numeric,2) as rating_2023
from product as p join orders as o on o.P_ID=p.P_ID join delivery as d on d.DP_ID=o.DP_ID join rating as r on r.Or_ID=o.Or_ID
group by d.dp_name order by order_2024 desc,order_2023 desc ;

-- 59. Determine the company sales , along with delivery amount provided, yearwise
with total_orders as
(with o1 as
(with orders as (select *, extract('year' from order_date) as years from orders)
select p.company_name,
sum(case when years=2024 then 1 else 0 end ) as order_2024,
sum(case when years=2023 then 1 else 0 end ) as order_2023,
round(sum(case when years=2024 then p.price*o.qty*(1-o.discount/100) else 0 end )::numeric,2)  as amount_2024,
round(sum(case when years=2023 then p.price*o.qty*(1-o.discount/100) else 0 end )::numeric,2)  as amount_2023
from orders as o join product as p on p.P_ID=o.P_ID group by p.company_name ),
o2 as
(with orders as (select *, extract('year' from order_date) as years from orders)
select p.company_name,
round(sum(case when years=2024 then p.price*o.qty*(1-o.discount/100)*(d.percent_cut/100) else 0 end )::numeric,2)  as delivery_cost_2024,
round(sum(case when years=2023 then p.price*o.qty*(1-o.discount/100)*(d.percent_cut/100) else 0 end )::numeric,2)  as delivery_cost_2023
from orders as o join product as p on p.P_ID=o.P_ID join delivery as d on d.DP_ID=o.DP_ID group by p.company_name )
select o1.company_name,o1.order_2024,o1.order_2023,o1.amount_2024,o1.amount_2023,o2.delivery_cost_2024,o2.delivery_cost_2023 from
o1 join o2 on o1.company_name=o2.company_name)
select *, amount_2024-delivery_cost_2024 as net_amount_2024,amount_2023-delivery_cost_2023 as net_amount_2023 from total_orders;

-- 60. Determine the MOM for the Delivery Partner
with mom_order as 
(select months,order_2024,lag(order_2024,1,0) over() as pre_order_2024,order_2023,lag(order_2023,1,0) over() as pre_order_2023 from 
(with orders as (select *, extract('year' from order_date) as years, extract('month' from order_date) as m, to_char(order_date,'month') as months from orders)
select months,m ,
round(sum(case when years=2024 then p.price*o.qty*(1-o.discount/100)*(d.percent_cut/100) else 0 end)::numeric,2)  as order_2024,
round(sum(case when years=2023 then p.price*o.qty*(1-o.discount/100)*(d.percent_cut/100) else 0 end)::numeric,2) as order_2023
from orders as o join product as p on p.P_ID=o.P_ID join delivery as d on d.DP_ID=o.DP_ID group by months,m 
order by m asc) as rnk)
select months,case when pre_order_2024=0 then 0 else round( (order_2024-pre_order_2024)/pre_order_2024*100::numeric,2) end as MOM_2024,
case when pre_order_2023=0 then 0 else round( (order_2023-pre_order_2023)/pre_order_2023*100::numeric,2) end as MOM_2023 from mom_order;


/* Returns & Refunds */
-- 61. 91.	Which delivery partner handles the most returned items, along with how many quantity ,yearwise
with orders as (select *,extract('year' from order_date) as years from orders)
select d.dp_name,
sum(case when years=2024 then 1 else 0 end ) as order_2024,
sum(case when years=2023 then 1 else 0 end ) as order_2023,
sum(case when years=2024 then o.qty else 0 end ) as qty_2024,
sum(case when years=2023 then o.qty else 0 end ) as qty_2023
from orders as o join return_refund as rr on rr.Or_ID=o.Or_ID join delivery as d on 
d.DP_ID=o.DP_ID group by  d.dp_name;

-- 62.  Determine, per company, the proportion of orders that were Rejected and Approved for return.
with ordr_return as 
(select p.company_name,
sum(case when rr.return_refund='Approved' then 1 else 0 end ) as Approved,
sum(case when rr.return_refund='Rejected' then 1 else 0 end ) as Rejected
from product as p join orders as o on o.P_ID=p.P_ID join return_refund as rr
on rr.Or_ID=o.Or_ID group by p.company_name)
select company_name,approved,round((approved/sum(approved) over ()*100)::numeric,2) as "% Approved",
rejected,round((rejected/sum(rejected) over ()*100)::numeric,2) as "% Rejected"
from ordr_return;

-- 63. Find out how many customers have returned more than two items.
select c.c_name,count(o.Or_ID) as total_orders
from customer as c join orders as o on 
o.C_ID=c.C_ID join return_refund as rr on rr.Or_ID=o.Or_ID where rr.return_refund='Approved'
group by c.c_name having count(o.Or_ID)>2 order by total_orders desc;

-- 64. Determine which goods have the highest rates of returns.
select *, round(p_returns/p_orders*100::numeric,5) as rate_of_return from  
(select p_name,p_orders,
case when p_returns is null then 0 else p_returns end from
(with orders_p as
(select p.p_name,count( o.Or_ID) as p_orders
from product as p join orders as o on o.P_ID=p.P_ID group by p.p_name),
returns_p as 
(select p.p_name, count( o.Or_ID) as p_returns
from product as p join orders as o on o.P_ID=p.P_ID join return_refund as rr on rr.Or_ID=o.Or_ID
group by p.p_name)
select o.p_name,o.p_orders,  r.p_returns from  orders_p as o
left join returns_p as r on o.p_name=r.p_name order by o.p_orders desc) as rnks where p_orders>p_returns) as ror order by rate_of_return desc ;

-- 65. Determine the percentage authorized return rate  for every category , product genderwise
with order_c as
(select p.category,
count(case when p.p_gender='Men' then o.Or_ID else null end ) as order_men,
count(case when p.p_gender='Women' then o.Or_ID else null end ) as order_women,
count(case when p.p_gender='Unisex' then o.Or_ID else null end ) as order_unisex
from product as p join orders as o on o.P_ID=p.P_ID group by  p.category),
return_c as
(select p.category,
count(case when p.p_gender='Men' then o.Or_ID else null end ) as return_men,
count(case when p.p_gender='Women' then o.Or_ID else null end ) as return_women,
count(case when p.p_gender='Unisex' then o.Or_ID else null end ) as return_unisex
from product as p join orders as o on o.P_ID=p.P_ID join return_refund as rr on rr.Or_ID=o.Or_ID
group by  p.category)
select o.category,o.order_men,r.return_men,round( r.return_men/o.order_men*100::numeric,2) as ror_men ,
o.order_women,r.return_women,round( (r.return_women/o.order_women*100)::numeric,2) as ror_women,
o.order_unisex,r.return_unisex ,round( r.return_unisex/o.order_unisex *100::numeric,2) as ror_unisex
from order_c as o
left join return_c as r on o.category=r.category; 

-- 66. Determine the total revenue lost as a result of company-specific refunds, yearwise.
with order_cp as
(with orders as (select *,extract('year' from order_date) as years from orders )
select p.company_name,
round(sum(case when years=2024 then o.qty*p.price*(1-o.discount/100) else 0 end)::numeric,2) as order_2024,
round(sum(case when years=2023 then o.qty*p.price*(1-o.discount/100) else 0 end)::numeric,2) as order_2023
from orders as o join product as p on p.P_ID=o.P_ID group by p.company_name),
return_cp as
(with orders as (select *,extract('year' from order_date) as years from orders )
select p.company_name,
round(sum(case when years=2024 then o.qty*p.price*(1-o.discount/100) else 0 end)::numeric,2) as return_2024,
round(sum(case when years=2023 then o.qty*p.price*(1-o.discount/100) else 0 end)::numeric,2) as return_2023
from orders as o join product as p on p.P_ID=o.P_ID join return_refund as rr on rr.Or_ID=o.Or_ID
group by p.company_name) 
select o.company_name,o.order_2024,r.return_2024,o.order_2024-r.return_2024 as loss_2024,
o.order_2023,r.return_2023,o.order_2023-r.return_2023 as loss_2023 from order_cp as o join return_cp as r
on o.company_name=r.company_name ;

-- 67. Calculate the MOM Return 
with mom_order as 
(select months,order_2024,lag(order_2024,1,0) over() as pre_order_2024,order_2023,lag(order_2023,1,0) over() as pre_order_2023 from 
(with orders as (select *, extract('year' from order_date) as years, extract('month' from order_date) as m, to_char(order_date,'month') as months from orders)
select months,m ,
round(sum(case when years=2024 then p.price*o.qty*(1-o.discount/100) else 0 end)::numeric,2)  as order_2024,
round(sum(case when years=2023 then p.price*o.qty*(1-o.discount/100) else 0 end)::numeric,2) as order_2023
from orders as o join product as p on p.P_ID=o.P_ID join delivery as d on d.DP_ID=o.DP_ID join return_refund
as rr on rr.Or_ID=o.Or_ID  group by months,m order by m asc) as rnk)
select months,case when pre_order_2024=0 then 0 else round( (order_2024-pre_order_2024)/pre_order_2024*100::numeric,2) end as MOM_return_2024,
case when pre_order_2023=0 then 0 else round( (order_2023-pre_order_2023)/pre_order_2023*100::numeric,2) end as MOM_return_2023 from mom_order;

-- 68. Find out how many returned orders each delivery partner has handled, companywise.
select p.company_name,
count(case when d.dp_name='Delhivery' then o.Or_ID else null end ) as Delhivery,
count(case when d.dp_name='Blue Dart' then o.Or_ID else null end ) as Blue_Dart,
count(case when d.dp_name='Ecom Express' then o.Or_ID else null end ) as Ecom_Express,
count(case when d.dp_name='Shadowfax' then o.Or_ID else null end ) as Shadowfax,
count(case when d.dp_name='Xpressbees' then o.Or_ID else null end ) as Xpressbees
from product as p join orders as o on o.P_ID=p.P_ID join delivery as d on d.DP_ID=o.DP_ID
join return_refund as rr on rr.Or_ID=o.Or_ID group by p.company_name;

-- 69. Determine the total revenue lost as a result of delivery partner -specific refunds, yearwise.
with order_cp as
(with orders as (select *,extract('year' from order_date) as years from orders )
select d.dp_name,
round(sum(case when years=2024 then o.qty*p.price*(1-o.discount/100)*(d.percent_cut) else 0 end)::numeric,2) as order_2024,
round(sum(case when years=2023 then o.qty*p.price*(1-o.discount/100)*(d.percent_cut) else 0 end)::numeric,2) as order_2023
from orders as o join product as p on p.P_ID=o.P_ID join delivery as d on d.DP_ID=o.DP_ID 
group by d.dp_name),
return_cp as
(with orders as (select *,extract('year' from order_date) as years from orders )
select d.dp_name,
round(sum(case when years=2024 then o.qty*p.price*(1-o.discount/100)*(d.percent_cut) else 0 end)::numeric,2) as return_2024,
round(sum(case when years=2023 then o.qty*p.price*(1-o.discount/100)*(d.percent_cut) else 0 end)::numeric,2) as return_2023
from orders as o join product as p on p.P_ID=o.P_ID join delivery as d on d.DP_ID=o.DP_ID 
join return_refund as rr on rr.Or_ID=o.Or_ID
group by d.dp_name) 
select o.dp_name,o.order_2024,r.return_2024,o.order_2024-r.return_2024 as loss_2024,
o.order_2023,r.return_2023,o.order_2023-r.return_2023 as loss_2023 from order_cp as o join return_cp as r
on o.dp_name=r.dp_name ;


/* ADVANCE ANALYSIS */
-- 1. Determine the product with the highest number of orders , total orders qty, average rating, revenue, total returns and revenue loss
with orders_p as 
(select p.p_name,count(o.Or_ID) as total_orders,sum(o.qty) as total_qty,round(avg(r.prod_rating)::numeric,2) as prod_rating,
round((sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100))::numeric,2) as revenue from product as p join orders as o on 
o.P_ID=p.P_ID join rating as r on r.Or_ID=o.Or_ID group by p.p_name),
return_p as 
(select p.p_name,count(o.Or_ID) as total_return,sum(o.qty) as total_qty_return,
round((sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100))::numeric,2) as revenue_loss from product as p join orders as o on 
o.P_ID=p.P_ID join rating as r on r.Or_ID=o.Or_ID join return_refund as rr on rr.Or_ID=o.Or_ID
group by p.p_name)
select o.p_name,o.total_orders,o.total_qty,o.prod_rating,o.revenue,r.total_return,r.total_qty_return,r.revenue_loss,o.revenue-r.revenue_loss as net_revenue
from orders_p as o join return_p as r on o.p_name=r.p_name where o.total_orders>=r.total_return order by o.total_orders desc limit 20;

-- 2. Determine the company's orders, revenue, average rating, total qty, and number of returns,total qty return , yearwise.
with order_cp as 
(with orders as (select *,extract('year' from order_date) as years from orders )
select p.company_name,
count(case when o.years=2024 then o.Or_ID  else null end ) as orders_2024,
count(case when o.years=2023 then o.Or_ID  else null end ) as orders_2023,
sum(case when o.years=2024 then o.qty else 0 end ) as qty_2024,
sum(case when o.years=2023 then o.qty  else 0 end ) as qty_2023,
round(sum(case when o.years=2024 then o.qty*p.price*(1-o.discount/100) else 0 end )::numeric,2)   as revenue_2024,
round(sum(case when o.years=2023 then o.qty*p.price*(1-o.discount/100) else 0 end )::numeric,2)  as revenue_2023,
round(avg(case when o.years=2024 then r.prod_rating else 0 end )::numeric ,2) as rating_2024,
round(avg(case when o.years=2023 then r.prod_rating else 0 end )::numeric ,2) as rating_2023 from 
product as p join orders as o on o.P_ID=p.P_ID join rating as r on r.Or_ID=o.Or_ID group by p.company_name),
return_cp as 
(with orders as (select *,extract('year' from order_date) as years from orders )
select p.company_name,
count(case when o.years=2024 then o.Or_ID  else null end ) as return_2024,
count(case when o.years=2023 then o.Or_ID  else null end ) as return_2023,
sum(case when o.years=2024 then o.qty else 0 end ) as return_qty_2024,
sum(case when o.years=2023 then o.qty  else 0 end ) as return_qty_2023,
round(sum(case when o.years=2024 then o.qty*p.price*(1-o.discount/100) else 0 end )::numeric,2)   as loss_2024,
round(sum(case when o.years=2023 then o.qty*p.price*(1-o.discount/100) else 0 end )::numeric,2)  as loss_2023 from
product as p join orders as o on o.P_ID=p.P_ID join rating as r on r.Or_ID=o.Or_ID join return_refund as rr on 
rr.Or_ID=o.Or_ID group by p.company_name)
select o.company_name,o.orders_2024,o.orders_2023,o.qty_2024,o.qty_2023,o.revenue_2024,o.revenue_2023,o.rating_2024,o.rating_2023,
r.return_2024,r.return_2023,r.return_qty_2024,r.return_qty_2023,r.loss_2024,r.loss_2023 , o.revenue_2024-r.loss_2024 as net_revenue_2024,
o.revenue_2023-r.loss_2023 as net_revenue_2023   from order_cp as o join return_cp as r
on o.company_name=r.company_name where o.orders_2024>=r.return_2024 and o.orders_2023>=r.return_2023;

-- 3. Look into the delivery partner's total orders, revenue, average rating, and number of returns.
with order_cp as 
(with orders as (select *,extract('year' from order_date) as years from orders )
select d.dp_name,
count(case when o.years=2024 then o.Or_ID  else null end ) as orders_2024,
count(case when o.years=2023 then o.Or_ID  else null end ) as orders_2023,
sum(case when o.years=2024 then o.qty else 0 end ) as qty_2024,
sum(case when o.years=2023 then o.qty  else 0 end ) as qty_2023,
round(sum(case when o.years=2024 then o.qty*p.price*(1-o.discount/100)*(d.percent_cut/100) else 0 end )::numeric,2)   as revenue_2024,
round(sum(case when o.years=2023 then o.qty*p.price*(1-o.discount/100)*(d.percent_cut/100) else 0 end )::numeric,2)  as revenue_2023,
round(avg(case when o.years=2024 then r.delivery_service_rating else 0 end )::numeric ,2) as rating_2024,
round(avg(case when o.years=2023 then r.delivery_service_rating else 0 end )::numeric ,2) as rating_2023 from 
product as p join orders as o on o.P_ID=p.P_ID join rating as r on r.Or_ID=o.Or_ID join delivery as d on d.DP_ID=o.DP_ID
group by d.dp_name),
return_cp as 
(with orders as (select *,extract('year' from order_date) as years from orders )
select d.dp_name,
count(case when o.years=2024 then o.Or_ID  else null end ) as return_2024,
count(case when o.years=2023 then o.Or_ID  else null end ) as return_2023,
sum(case when o.years=2024 then o.qty else 0 end ) as return_qty_2024,
sum(case when o.years=2023 then o.qty  else 0 end ) as return_qty_2023,
round(sum(case when o.years=2024 then o.qty*p.price*(1-o.discount/100)*(d.percent_cut/100) else 0 end )::numeric,2)   as loss_2024,
round(sum(case when o.years=2023 then o.qty*p.price*(1-o.discount/100)*(d.percent_cut/100) else 0 end )::numeric,2)  as loss_2023 from
product as p join orders as o on o.P_ID=p.P_ID join rating as r on r.Or_ID=o.Or_ID join return_refund as rr on 
rr.Or_ID=o.Or_ID join delivery as d on d.DP_ID=o.DP_ID  group by d.dp_name)
select o.dp_name,o.orders_2024,o.orders_2023,o.qty_2024,o.qty_2023,o.revenue_2024,o.revenue_2023,o.rating_2024,o.rating_2023,
r.return_2024,r.return_2023,r.return_qty_2024,r.return_qty_2023,r.loss_2024,r.loss_2023 , o.revenue_2024-r.loss_2024 as net_revenue_2024,
o.revenue_2023-r.loss_2023 as net_revenue_2023   from order_cp as o join return_cp as r
on o.dp_name=r.dp_name where o.orders_2024>=r.return_2024 and o.orders_2023>=r.return_2023;

-- 4. Obtain the company's hourly analysis, which includes the order, quantity, and revenue earned, yearwise .
with orders as 
(with ord as ( select *,extract('hour' from order_time ) as hours from orders)
select *, case when hours between 6 and 11 then 'Morning' when hours between 12 and 17 then 'Afternoon' when hours between 18 and 22 then 'Evening'
else 'Night' end as Hr_Grp, extract('year' from order_date) as years from ord) 
select o.hr_grp,
count(case when o.years=2024 then o.Or_ID else null end ) as orders_2024,
count(case when o.years=2023 then o.Or_ID else null end ) as orders_2023,
sum(case when o.years=2024 then o.qty else 0 end ) as qty_2024,
sum(case when o.years=2023 then o.qty  else 0 end ) as qty_2023,
round(sum(case when o.years=2024 then o.qty*p.price*(1-o.discount/100) else 0 end )::numeric,2)   as revenue_2024,
round(sum(case when o.years=2023 then o.qty*p.price*(1-o.discount/100) else 0 end )::numeric,2)  as revenue_2023
from orders as o join product as p on p.P_ID=o.P_ID  group by o.hr_grp;

-- 5. Obtain the company's monthly analysis, which includes the  revenue earned, yearwise
with total_order as 
(with orders as (select *, extract('months' from order_date) as m, to_char(order_date,'month') as months, 
extract('year' from order_date) as years  from orders )
select o.months,o.m, 
sum(case when o.years=2024 and p.company_name='Puma' then o.qty*p.price*(1-o.discount/100) else 0 end ) as Puma_2024,
sum(case when o.years=2023 and p.company_name='Puma' then o.qty*p.price*(1-o.discount/100) else 0 end ) as Puma_2023,
sum(case when o.years=2024 and p.company_name='Gap' then o.qty*p.price*(1-o.discount/100) else 0 end ) as Gap_2024,
sum(case when o.years=2023 and p.company_name='Gap' then o.qty*p.price*(1-o.discount/100) else 0 end ) as Gap_2023,
sum(case when o.years=2024 and p.company_name='Pantaloons' then o.qty*p.price*(1-o.discount/100) else 0 end ) as Pantaloons_2024,
sum(case when o.years=2023 and p.company_name='Pantaloons' then o.qty*p.price*(1-o.discount/100) else 0 end ) as Pantaloons_2023,
sum(case when o.years=2024 and p.company_name='Reebok' then o.qty*p.price*(1-o.discount/100) else 0 end ) as Reebok_2024,
sum(case when o.years=2023 and p.company_name='Reebok' then o.qty*p.price*(1-o.discount/100) else 0 end ) as Reebok_2023,
sum(case when o.years=2024 and p.company_name='Adidas' then o.qty*p.price*(1-o.discount/100) else 0 end ) as Adidas_2024,
sum(case when o.years=2023 and p.company_name='Adidas' then o.qty*p.price*(1-o.discount/100) else 0 end ) as Adidas_2023,
sum(case when o.years=2024 and p.company_name like 'Levi%' then o.qty*p.price*(1-o.discount/100) else 0 end ) as Levis_2024,
sum(case when o.years=2023 and p.company_name like 'Levi%' then o.qty*p.price*(1-o.discount/100) else 0 end ) as Levis_2023,
sum(case when o.years=2024 and p.company_name='H&M' then o.qty*p.price*(1-o.discount/100) else 0 end ) as H_M_2024,
sum(case when o.years=2023 and p.company_name='H&M' then o.qty*p.price*(1-o.discount/100) else 0 end ) as H_M_2023,
sum(case when o.years=2024 and p.company_name='Zara' then o.qty*p.price*(1-o.discount/100) else 0 end ) as Zara_2024,
sum(case when o.years=2023 and p.company_name='Zara' then o.qty*p.price*(1-o.discount/100) else 0 end ) as Zara_2023,
sum(case when o.years=2024 and p.company_name='Uniqlo' then o.qty*p.price*(1-o.discount/100) else 0 end ) as Uniqlo_2024,
sum(case when o.years=2023 and p.company_name='Uniqlo' then o.qty*p.price*(1-o.discount/100) else 0 end ) as Uniqlo_2023,
sum(case when o.years=2024 and p.company_name='Nike' then o.qty*p.price*(1-o.discount/100) else 0 end ) as Nike_2024,
sum(case when o.years=2023 and p.company_name='Nike' then o.qty*p.price*(1-o.discount/100) else 0 end ) as Nike_2023
from orders as o join product as p on o.P_ID=p.P_ID group by o.months , o.m order by o.m asc)
select months, round(Puma_2024::numeric,2) as Puma_2024,round(Puma_2023::numeric,2) as Puma_2023,
round(Gap_2024::numeric,2) as Gap_2024,round(Gap_2023::numeric,2) as Gap_2023,round(Pantaloons_2024::numeric,2) as Pantaloons_2024,
round(Pantaloons_2023::numeric,2) as Pantaloons_2023,round(Reebok_2024::numeric,2) as Reebok_2024,round(Reebok_2023::numeric,2) as Reebok_2023,
round(Adidas_2024::numeric,2) as Adidas_2024,round(Adidas_2023::numeric,2) as Adidas_2023,round(Levis_2024::numeric,2) as Levis_2024,
round(Levis_2023::numeric,2) as Levis_2023,round(H_M_2024::numeric,2) as H_M_2024,round(H_M_2023::numeric,2) as H_M_2023,
round(Zara_2024::numeric,2) as Zara_2024,round(Zara_2023::numeric,2) as Zara_2023,round(Uniqlo_2024::numeric,2) as Uniqlo_2024,
round(Uniqlo_2023::numeric,2) as Uniqlo_2023,round(Nike_2024::numeric,2) as Nike_2024,round(Nike_2023::numeric,2) as Nike_2023 from total_order;

-- 6. Determine which month has high income of delivery partner , yearwise
with total_revenue as 
(select * from 
(with amt_2024 as 
(with rks as 
(select *, row_number() over(partition by months order by amount_2024 desc) as ranks from
(with orders as (select *, extract('months' from order_date) as m, to_char(order_date,'month') as months, 
extract('year' from order_date) as years  from orders )
select o.months,o.m,d.dp_name as dp_name_2024 ,round((sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100)*(avg(d.percent_cut)/100))::numeric,2) as amount_2024 
from orders as o join product as p on p.P_ID=o.P_ID join delivery as d on d.DP_ID=o.DP_ID  where o.years=2024 group by o.months , 
o.m,dp_name_2024 order by m asc) as rnk order by m) 
select * from rks where ranks = (select min(ranks) from rks) ),
amt_2023 as
(with rks as 
(select *, row_number() over(partition by months order by amount_2023 desc) as ranks from
(with orders as (select *, extract('months' from order_date) as m, to_char(order_date,'month') as months, 
extract('year' from order_date) as years  from orders )
select o.months,o.m,d.dp_name as dp_name_2023,round((sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100)*(avg(d.percent_cut)/100))::numeric,2) as amount_2023 
from orders as o join product as p on p.P_ID=o.P_ID join delivery as d on d.DP_ID=o.DP_ID  where o.years=2023 group by o.months , 
o.m,dp_name_2023 order by m asc) as rnk order by m) 
select * from rks where ranks = (select min(ranks) from rks ) )
select amx24.months,amx24.m,amx24.dp_name_2024,amx24.amount_2024,amx23.dp_name_2023,amx23.amount_2023
from amt_2024 as amx24 join amt_2023 as amx23 on amx24.months=amx23.months order by amx24.m asc) union all
select * from
(with amt_2024 as 
(with rks as 
(select *, row_number() over(partition by months order by amount_2024 asc) as ranks from
(with orders as (select *, extract('months' from order_date) as m, to_char(order_date,'month') as months, 
extract('year' from order_date) as years  from orders )
select o.months,o.m,d.dp_name as dp_name_2024,round((sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100)*(avg(d.percent_cut)/100))::numeric,2) as amount_2024 
from orders as o join product as p on p.P_ID=o.P_ID join delivery as d on d.DP_ID=o.DP_ID  where o.years=2024 group by o.months , 
o.m,dp_name_2024 order by m asc) as rnk order by m) 
select * from rks where ranks = (select min(ranks) from rks) ),
amt_2023 as
(with rks as 
(select *, row_number() over(partition by months order by amount_2023 asc) as ranks from
(with orders as (select *, extract('months' from order_date) as m, to_char(order_date,'month') as months, 
extract('year' from order_date) as years  from orders )
select o.months,o.m,d.dp_name as dp_name_2023,round((sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100)*(avg(d.percent_cut)/100))::numeric,2) as amount_2023 
from orders as o join product as p on p.P_ID=o.P_ID join delivery as d on d.DP_ID=o.DP_ID  where o.years=2023 group by o.months , 
o.m,dp_name_2023 order by m asc) as rnk order by m) 
select * from rks where ranks = (select min(ranks) from rks ) )
select amx24.months,amx24.m,amx24.dp_name_2024,amx24.amount_2024,amx23.dp_name_2023,amx23.amount_2023
from amt_2024 as amx24 join amt_2023 as amx23 on amx24.months=amx23.months order by amx24.m asc))
select months,dp_name_2024,amount_2024,dp_name_2023,amount_2023 from total_revenue order by m asc;

-- 7. Determine which month has high net revenue (total_revenue-revenue_loss ) , yearwise
with total_net_revenue as
(select * from 
(with hrank_2024 as
(with rnk_2024 as
(select *,row_number() over (partition by months order by net_revenue_2024 desc ) as ranks from
(with amt_2024 as
(with orders as (select *, extract('months' from order_date) as m, to_char(order_date,'month') as months, 
extract('year' from order_date) as years  from orders )
select o.months,o.m,p.company_name as company_name_2024 ,
round((sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100))::numeric,2) as amount_2024 
from orders as o join product as p on p.P_ID=o.P_ID join delivery as d on d.DP_ID=o.DP_ID  where o.years=2024 group by o.months , 
o.m,company_name_2024 order by m asc),
amt_ret_2024 as
(with orders as (select *, extract('months' from order_date) as m, to_char(order_date,'month') as months, 
extract('year' from order_date) as years  from orders )
select o.months,o.m,p.company_name as company_name_2024 ,
round((sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100))::numeric,2) as amount_return_2024 
from orders as o join product as p on p.P_ID=o.P_ID join delivery as d on d.DP_ID=o.DP_ID join return_refund as rr on rr.Or_ID=o.Or_ID
where o.years=2024 group by o.months , o.m,company_name_2024 order by m asc)
select ah24.months,ah24.m,ah24.company_name_2024,ah24.amount_2024 , ahr24.amount_return_2024 , 
ah24.amount_2024 - ahr24.amount_return_2024 as net_revenue_2024   from amt_2024 as ah24
join  amt_ret_2024 as ahr24 on ah24.months=ahr24.months and ah24.company_name_2024=ahr24.company_name_2024 order by ah24.m asc) as rnk ) 
select * from rnk_2024 where ranks = (select min(ranks) from rnk_2024 ) order by m asc),
hrank_2023 as
(with rnk_2023 as
(select *,row_number() over (partition by months order by net_revenue_2023 desc ) as ranks from
(with amt_2023 as
(with orders as (select *, extract('months' from order_date) as m, to_char(order_date,'month') as months, 
extract('year' from order_date) as years  from orders )
select o.months,o.m,p.company_name as company_name_2023 ,
round((sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100))::numeric,2) as amount_2023 
from orders as o join product as p on p.P_ID=o.P_ID join delivery as d on d.DP_ID=o.DP_ID  where o.years=2023 group by o.months , 
o.m,company_name_2023 order by m asc),
amt_ret_2023 as
(with orders as (select *, extract('months' from order_date) as m, to_char(order_date,'month') as months, 
extract('year' from order_date) as years  from orders )
select o.months,o.m,p.company_name as company_name_2023 ,
round((sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100))::numeric,2) as amount_return_2023 
from orders as o join product as p on p.P_ID=o.P_ID join delivery as d on d.DP_ID=o.DP_ID join return_refund as rr on rr.Or_ID=o.Or_ID
where o.years=2023 group by o.months , o.m,company_name_2023 order by m asc)
select ah23.months,ah23.m,ah23.company_name_2023,ah23.amount_2023 , ahr23.amount_return_2023 , 
ah23.amount_2023 - ahr23.amount_return_2023 as net_revenue_2023   from amt_2023 as ah23
join  amt_ret_2023 as ahr23 on ah23.months=ahr23.months and ah23.company_name_2023=ahr23.company_name_2023 order by ah23.m asc) as rnk ) 
select * from rnk_2023 where ranks = (select min(ranks) from rnk_2023 ) order by m asc)
select hrk24.months,hrk24.m,hrk24.company_name_2024,hrk24.amount_2024,hrk24.amount_return_2024,hrk24.net_revenue_2024,
hrk23.company_name_2023,hrk23.amount_2023,hrk23.amount_return_2023,hrk23.net_revenue_2023 from hrank_2024 as hrk24 join
hrank_2023 as hrk23 on hrk24.months=hrk23.months) union all
select * from
(with hrank_2024 as
(with rnk_2024 as
(select *,row_number() over (partition by months order by net_revenue_2024 asc ) as ranks from
(with amt_2024 as
(with orders as (select *, extract('months' from order_date) as m, to_char(order_date,'month') as months, 
extract('year' from order_date) as years  from orders )
select o.months,o.m,p.company_name as company_name_2024 ,
round((sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100))::numeric,2) as amount_2024 
from orders as o join product as p on p.P_ID=o.P_ID join delivery as d on d.DP_ID=o.DP_ID  where o.years=2024 group by o.months , 
o.m,company_name_2024 order by m asc),
amt_ret_2024 as
(with orders as (select *, extract('months' from order_date) as m, to_char(order_date,'month') as months, 
extract('year' from order_date) as years  from orders )
select o.months,o.m,p.company_name as company_name_2024 ,
round((sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100))::numeric,2) as amount_return_2024 
from orders as o join product as p on p.P_ID=o.P_ID join delivery as d on d.DP_ID=o.DP_ID join return_refund as rr on rr.Or_ID=o.Or_ID
where o.years=2024 group by o.months , o.m,company_name_2024 order by m asc)
select ah24.months,ah24.m,ah24.company_name_2024,ah24.amount_2024 , ahr24.amount_return_2024 , 
ah24.amount_2024 - ahr24.amount_return_2024 as net_revenue_2024   from amt_2024 as ah24
join  amt_ret_2024 as ahr24 on ah24.months=ahr24.months and ah24.company_name_2024=ahr24.company_name_2024 order by ah24.m asc) as rnk ) 
select * from rnk_2024 where ranks = (select min(ranks) from rnk_2024 ) order by m asc),
hrank_2023 as
(with rnk_2023 as
(select *,row_number() over (partition by months order by net_revenue_2023 asc ) as ranks from
(with amt_2023 as
(with orders as (select *, extract('months' from order_date) as m, to_char(order_date,'month') as months, 
extract('year' from order_date) as years  from orders )
select o.months,o.m,p.company_name as company_name_2023 ,
round((sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100))::numeric,2) as amount_2023 
from orders as o join product as p on p.P_ID=o.P_ID join delivery as d on d.DP_ID=o.DP_ID  where o.years=2023 group by o.months , 
o.m,company_name_2023 order by m asc),
amt_ret_2023 as
(with orders as (select *, extract('months' from order_date) as m, to_char(order_date,'month') as months, 
extract('year' from order_date) as years  from orders )
select o.months,o.m,p.company_name as company_name_2023 ,
round((sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100))::numeric,2) as amount_return_2023 
from orders as o join product as p on p.P_ID=o.P_ID join delivery as d on d.DP_ID=o.DP_ID join return_refund as rr on rr.Or_ID=o.Or_ID
where o.years=2023 group by o.months , o.m,company_name_2023 order by m asc)
select ah23.months,ah23.m,ah23.company_name_2023,ah23.amount_2023 , ahr23.amount_return_2023 , 
ah23.amount_2023 - ahr23.amount_return_2023 as net_revenue_2023   from amt_2023 as ah23
join  amt_ret_2023 as ahr23 on ah23.months=ahr23.months and ah23.company_name_2023=ahr23.company_name_2023 order by ah23.m asc) as rnk ) 
select * from rnk_2023 where ranks = (select min(ranks) from rnk_2023 ) order by m asc)
select hrk24.months,hrk24.m,hrk24.company_name_2024,hrk24.amount_2024,hrk24.amount_return_2024,hrk24.net_revenue_2024,
hrk23.company_name_2023,hrk23.amount_2023,hrk23.amount_return_2023,hrk23.net_revenue_2023 from hrank_2024 as hrk24 join
hrank_2023 as hrk23 on hrk24.months=hrk23.months)) 
select months,company_name_2024,amount_2024,amount_return_2024,net_revenue_2024,company_name_2023,
amount_2023,amount_return_2023,net_revenue_2023 from total_net_revenue order by m asc;

-- 8. Determine the entire amount of money lost as a result of returned goods based on category quarterwise.
select * from 
(with rank_24 as
(with rnk_2024 as 
(select *, row_number() over(partition by category order by orders_2024 desc ) as ranks from
(with orders as ( select *,extract('quarter' from order_date) as q, concat('Qtr ',extract('quarter' from order_date)) as quarter,
extract('year' from order_date) as years from orders) 
select p.category,o.quarter,o.q,count(o.Or_ID) as orders_2024, round((sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100))::numeric,2) as loss_2024
from product as p join orders as o on o.P_ID=p.P_ID where o.years=2024 group by p.category,o.quarter,o.q) as rnk)
select * from rnk_2024 where ranks=(select min(ranks) from rnk_2024 )),
rank_23 as
(with rnk_2023 as 
(select *,row_number() over(partition by category order by orders_2023 desc ) as ranks from
(with orders as ( select *,extract('quarter' from order_date) as q, concat('Qtr ',extract('quarter' from order_date)) as quarter,
extract('year' from order_date) as years from orders) 
select p.category,o.quarter,o.q,count(o.Or_ID) as orders_2023, round((sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100))::numeric,2) as loss_2023
from product as p join orders as o on o.P_ID=p.P_ID where o.years=2023 group by p.category,o.quarter,o.q ) as rnk)
select * from rnk_2023 where ranks=(select min(ranks) from rnk_2023 ))
select r24.category,r24.quarter,r24.orders_2024,r24.loss_2024,r23.quarter,r23.orders_2023,r23.loss_2023 from rank_24 as r24 join rank_23 as r23
on r24.category=r23.category) union all
select * from
(with rank_24 as
(with rnk_2024 as 
(select *, row_number() over(partition by category order by orders_2024 asc ) as ranks from
(with orders as ( select *,extract('quarter' from order_date) as q, concat('Qtr ',extract('quarter' from order_date)) as quarter,
extract('year' from order_date) as years from orders) 
select p.category,o.quarter,o.q,count(o.Or_ID) as orders_2024, round((sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100))::numeric,2) as loss_2024
from product as p join orders as o on o.P_ID=p.P_ID where o.years=2024 group by p.category,o.quarter,o.q) as rnk)
select * from rnk_2024 where ranks=(select min(ranks) from rnk_2024 )),
rank_23 as
(with rnk_2023 as 
(select *,row_number() over(partition by category order by orders_2023 asc ) as ranks from
(with orders as ( select *,extract('quarter' from order_date) as q, concat('Qtr ',extract('quarter' from order_date)) as quarter,
extract('year' from order_date) as years from orders) 
select p.category,o.quarter,o.q,count(o.Or_ID) as orders_2023, round((sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100))::numeric,2) as loss_2023
from product as p join orders as o on o.P_ID=p.P_ID where o.years=2023 group by p.category,o.quarter,o.q ) as rnk)
select * from rnk_2023 where ranks=(select min(ranks) from rnk_2023 ))
select r24.category,r24.quarter,r24.orders_2024,r24.loss_2024,r23.quarter,r23.orders_2023,r23.loss_2023 from rank_24 as r24 join rank_23 as r23
on r24.category=r23.category) order by category;

-- 9. Determine each city's best-selling and worst-selling category, yearwise.
select * from 
(with rk_24 as
(with rnk_2024 as
(select *, row_number() over(partition by city order by amount_2024 desc ) as ranks from
(with orders as (select *, extract('years' from order_date) as years from orders)
select c.city,p.category as category_2024,count(o.Or_ID) as orders_2024,sum(o.qty) as qty_2024,
round((sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100))::numeric,2)  as amount_2024
from customer as c join orders as o on o.C_ID=c.C_ID join product as p on p.P_ID=o.P_ID
where o.years=2024 group by c.city,p.category) as rnk)
select * from rnk_2024 where ranks=(select min(ranks) from rnk_2024) ),
rk_23 as
(with rnk_2023 as
(select *, row_number() over(partition by city order by amount_2023 desc ) as ranks from
(with orders as (select *, extract('years' from order_date) as years from orders)
select c.city,p.category as category_2023,count(o.Or_ID) as orders_2023,sum(o.qty) as qty_2023,
round((sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100))::numeric,2)  as amount_2023
from customer as c join orders as o on o.C_ID=c.C_ID join product as p on p.P_ID=o.P_ID
where o.years=2023 group by c.city,p.category) as rnk)
select * from rnk_2023 where ranks=(select min(ranks) from rnk_2023 ))
select r24.city,r24.category_2024,r24.orders_2024,r24.qty_2024,r24.amount_2024,
r23.category_2023,r23.orders_2023,r23.qty_2023,r23.amount_2023 from rk_24 as r24 join rk_23 as r23
on r24.city=r23.city) union all
select * from 
(with rk_24 as
(with rnk_2024 as
(select *, row_number() over(partition by city order by amount_2024 asc ) as ranks from
(with orders as (select *, extract('years' from order_date) as years from orders)
select c.city,p.category as category_2024,count(o.Or_ID) as orders_2024,sum(o.qty) as qty_2024,
round((sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100))::numeric,2)  as amount_2024
from customer as c join orders as o on o.C_ID=c.C_ID join product as p on p.P_ID=o.P_ID
where o.years=2024 group by c.city,p.category) as rnk)
select * from rnk_2024 where ranks=(select min(ranks) from rnk_2024) ),
rk_23 as
(with rnk_2023 as
(select *, row_number() over(partition by city order by amount_2023 asc ) as ranks from
(with orders as (select *, extract('years' from order_date) as years from orders)
select c.city,p.category as category_2023,count(o.Or_ID) as orders_2023,sum(o.qty) as qty_2023,
round((sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100))::numeric,2)  as amount_2023
from customer as c join orders as o on o.C_ID=c.C_ID join product as p on p.P_ID=o.P_ID
where o.years=2023 group by c.city,p.category) as rnk)
select * from rnk_2023 where ranks=(select min(ranks) from rnk_2023 ))
select r24.city,r24.category_2024,r24.orders_2024,r24.qty_2024,r24.amount_2024,
r23.category_2023,r23.orders_2023,r23.qty_2023,r23.amount_2023 from rk_24 as r24 join rk_23 as r23
on r24.city=r23.city) order by city asc
 
-- 10. Determine the annual percentage of orders that were refunded, statewise on quarterly basis and determine maximum and minimum percent refund
select * from
(with hrnk_2024 as
(with rnk_2024 as 
(select *, row_number() over(partition by states order by percent_return_2024 desc ) as rnk from 
(with order_2024 as
(with orders as (select *,concat('Qtr ', extract('quarter' from order_date)) as quarter,extract('quarter' from order_date) as q,
extract('years' from order_date) as years from orders )
select c.states,o.quarter as quarter_2024,o.q as q_24, 
round((sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100))::numeric,2) as amount_2024 from orders as o join product as p on p.P_ID=o.P_ID
join customer as c on c.C_ID=o.C_ID group by c.states,quarter_2024,q_24),
return_2024 as
(with orders as (select *,concat('Qtr ', extract('quarter' from order_date)) as quarter,extract('quarter' from order_date) as q,
extract('years' from order_date) as years from orders )
select c.states,o.quarter as quarter_2024,o.q as q_24, 
round((sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100))::numeric,2) as return_2024 from orders as o join product as p on p.P_ID=o.P_ID
join customer as c on c.C_ID=o.C_ID join return_refund as rr on rr.Or_ID=o.Or_ID
group by c.states,quarter_2024,q_24) 
select o24.states,o24.quarter_2024,o24.q_24,o24.amount_2024,r24.return_2024,round(r24.return_2024/o24.amount_2024*100::numeric,2) as percent_return_2024
from order_2024 as o24 join return_2024 as r24 
on o24.states=r24.states and o24.quarter_2024=r24.quarter_2024) as rnk)
select * from rnk_2024 where rnk= (select min(rnk) from rnk_2024 )),
hrnk_2023 as
(with rnk_2023 as 
(select *, row_number() over(partition by states order by percent_return_2023 desc ) as rnk from 
(with order_2023 as
(with orders as (select *,concat('Qtr ', extract('quarter' from order_date)) as quarter,extract('quarter' from order_date) as q,
extract('years' from order_date) as years from orders )
select c.states,o.quarter as quarter_2023,o.q as q_23, 
round((sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100))::numeric,2) as amount_2023 from orders as o join product as p on p.P_ID=o.P_ID
join customer as c on c.C_ID=o.C_ID group by c.states,quarter_2023,q_23),
return_2023 as
(with orders as (select *,concat('Qtr ', extract('quarter' from order_date)) as quarter,extract('quarter' from order_date) as q,
extract('years' from order_date) as years from orders )
select c.states,o.quarter as quarter_2023,o.q as q_23, 
round((sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100))::numeric,2) as return_2023 from orders as o join product as p on p.P_ID=o.P_ID
join customer as c on c.C_ID=o.C_ID join return_refund as rr on rr.Or_ID=o.Or_ID
group by c.states,quarter_2023,q_23) 
select o23.states,o23.quarter_2023,o23.q_23,o23.amount_2023,r23.return_2023,round(r23.return_2023/o23.amount_2023*100::numeric,2) as percent_return_2023
from order_2023 as o23 join return_2023 as r23 
on o23.states=r23.states and o23.quarter_2023=r23.quarter_2023) as rnk)
select * from rnk_2023 where rnk= (select min(rnk) from rnk_2023 ))
select h24.states,h24.quarter_2024,h24.amount_2024,h24.return_2024,h24.percent_return_2024,
h23.quarter_2023,h23.amount_2023,h23.return_2023,h23.percent_return_2023
from hrnk_2024 as h24 join hrnk_2023 as h23 on h24.states=h23.states ) union all
select * from
(with hrnk_2024 as
(with rnk_2024 as 
(select *, row_number() over(partition by states order by percent_return_2024 asc ) as rnk from 
(with order_2024 as
(with orders as (select *,concat('Qtr ', extract('quarter' from order_date)) as quarter,extract('quarter' from order_date) as q,
extract('years' from order_date) as years from orders )
select c.states,o.quarter as quarter_2024,o.q as q_24, 
round((sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100))::numeric,2) as amount_2024 from orders as o join product as p on p.P_ID=o.P_ID
join customer as c on c.C_ID=o.C_ID group by c.states,quarter_2024,q_24),
return_2024 as
(with orders as (select *,concat('Qtr ', extract('quarter' from order_date)) as quarter,extract('quarter' from order_date) as q,
extract('years' from order_date) as years from orders )
select c.states,o.quarter as quarter_2024,o.q as q_24, 
round((sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100))::numeric,2) as return_2024 from orders as o join product as p on p.P_ID=o.P_ID
join customer as c on c.C_ID=o.C_ID join return_refund as rr on rr.Or_ID=o.Or_ID
group by c.states,quarter_2024,q_24) 
select o24.states,o24.quarter_2024,o24.q_24,o24.amount_2024,r24.return_2024,round(r24.return_2024/o24.amount_2024*100::numeric,2) as percent_return_2024
from order_2024 as o24 join return_2024 as r24 
on o24.states=r24.states and o24.quarter_2024=r24.quarter_2024) as rnk)
select * from rnk_2024 where rnk= (select min(rnk) from rnk_2024 )),
hrnk_2023 as
(with rnk_2023 as 
(select *, row_number() over(partition by states order by percent_return_2023 asc ) as rnk from 
(with order_2023 as
(with orders as (select *,concat('Qtr ', extract('quarter' from order_date)) as quarter,extract('quarter' from order_date) as q,
extract('years' from order_date) as years from orders )
select c.states,o.quarter as quarter_2023,o.q as q_23, 
round((sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100))::numeric,2) as amount_2023 from orders as o join product as p on p.P_ID=o.P_ID
join customer as c on c.C_ID=o.C_ID group by c.states,quarter_2023,q_23),
return_2023 as
(with orders as (select *,concat('Qtr ', extract('quarter' from order_date)) as quarter,extract('quarter' from order_date) as q,
extract('years' from order_date) as years from orders )
select c.states,o.quarter as quarter_2023,o.q as q_23, 
round((sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100))::numeric,2) as return_2023 from orders as o join product as p on p.P_ID=o.P_ID
join customer as c on c.C_ID=o.C_ID join return_refund as rr on rr.Or_ID=o.Or_ID
group by c.states,quarter_2023,q_23) 
select o23.states,o23.quarter_2023,o23.q_23,o23.amount_2023,r23.return_2023,round(r23.return_2023/o23.amount_2023*100::numeric,2) as percent_return_2023
from order_2023 as o23 join return_2023 as r23 
on o23.states=r23.states and o23.quarter_2023=r23.quarter_2023) as rnk)
select * from rnk_2023 where rnk= (select min(rnk) from rnk_2023 ))
select h24.states,h24.quarter_2024,h24.amount_2024,h24.return_2024,h24.percent_return_2024,
h23.quarter_2023,h23.amount_2023,h23.return_2023,h23.percent_return_2023
from hrnk_2024 as h24 join hrnk_2023 as h23 on h24.states=h23.states ) order by states asc;

-- 11. Determine which company sells the most along with qty and amount in each state and which sell least, yearwise.
select * from
(with hrk_2024 as
(with rnk_2024 as 
(select * , row_number() over (partition by states order by orders_2024 desc ) as ranks from 
(with orders as (select *, extract('year' from order_date) as years from orders) 
select c.states,p.company_name,count(o.Or_ID) as orders_2024,sum(o.qty) as qty_2024,
round((sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100))::numeric,2) as amount_2024
from customer as c join orders as o on o.C_ID=c.C_ID join product as p on p.P_ID=o.P_ID
where o.years=2024 group by c.states,p.company_name ) as rnk)
select * from rnk_2024 where ranks = (select min(ranks) from rnk_2024 )),
hrk_2023 as
(with rnk_2023 as 
(select * , row_number() over (partition by states order by orders_2023 desc ) as ranks from 
(with orders as (select *, extract('year' from order_date) as years from orders) 
select c.states,p.company_name,count(o.Or_ID) as orders_2023,sum(o.qty) as qty_2023,
round((sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100))::numeric,2) as amount_2023
from customer as c join orders as o on o.C_ID=c.C_ID join product as p on p.P_ID=o.P_ID
where o.years=2023 group by c.states,p.company_name ) as rnk)
select * from rnk_2023 where ranks = (select min(ranks) from rnk_2023 ))
select h24.states,h24.company_name,h24.orders_2024,h24.qty_2024,h24.amount_2024,
h23.company_name,h23.orders_2023,h23.qty_2023,h23.amount_2023 from hrk_2024 as h24 join
hrk_2023 as h23 on h24.states=h23.states) union all
select * from
(with hrk_2024 as
(with rnk_2024 as 
(select * , row_number() over (partition by states order by orders_2024 asc ) as ranks from 
(with orders as (select *, extract('year' from order_date) as years from orders) 
select c.states,p.company_name,count(o.Or_ID) as orders_2024,sum(o.qty) as qty_2024,
round((sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100))::numeric,2) as amount_2024
from customer as c join orders as o on o.C_ID=c.C_ID join product as p on p.P_ID=o.P_ID
where o.years=2024 group by c.states,p.company_name ) as rnk)
select * from rnk_2024 where ranks = (select min(ranks) from rnk_2024 )),
hrk_2023 as
(with rnk_2023 as 
(select * , row_number() over (partition by states order by orders_2023 asc ) as ranks from 
(with orders as (select *, extract('year' from order_date) as years from orders) 
select c.states,p.company_name,count(o.Or_ID) as orders_2023,sum(o.qty) as qty_2023,
round((sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100))::numeric,2) as amount_2023
from customer as c join orders as o on o.C_ID=c.C_ID join product as p on p.P_ID=o.P_ID
where o.years=2023 group by c.states,p.company_name ) as rnk)
select * from rnk_2023 where ranks = (select min(ranks) from rnk_2023 ))
select h24.states,h24.company_name,h24.orders_2024,h24.qty_2024,h24.amount_2024,
h23.company_name,h23.orders_2023,h23.qty_2023,h23.amount_2023 from hrk_2024 as h24 join
hrk_2023 as h23 on h24.states=h23.states) order by states asc;

-- 12. Determine year-by-year MOM% orders, MOM% quantity, MOM% sales, MOM% return, and MOM% revenue loss.
with MOM_2024 as
(with order_2024_mom as
(with mom_order_2024 as
(select months,order_2024,lag(order_2024,1,0) over() as pre_order_2024, qty_2024,
lag(qty_2024,1,0) over() as pre_qty_2024 , amount_2024,lag(amount_2024,1,0) over() as pre_amount_2024 from
(with orders as (select *,to_char(order_date,'month') as months ,extract('month' from order_date) as m,
extract('year' from order_date) as years from orders)
select o.months,o.m,count(o.Or_ID) as order_2024,sum(o.qty) as qty_2024, 
round((sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100))::numeric,2) as amount_2024 
from orders as o join product as p on o.P_ID=p.P_ID 
where o.years=2024  group by o.months,o.m order by o.m asc) as lgs)
select months,  round(((order_2024-pre_order_2024))::numeric,2)  as MOM_orders,
round(((qty_2024-pre_qty_2024))::numeric,2)  as MOM_qty,
round(((amount_2024-pre_amount_2024))::numeric,2)  as MOM_sales from mom_order_2024),
return_2024_mom as
(with mom_return_2024 as
(select months,order_return_2024,lag(order_return_2024,1,0) over() as pre_order_return_2024, qty_return_2024,
lag(qty_return_2024,1,0) over() as pre_qty_return_2024 , loss_2024,lag(loss_2024,1,0) over() as pre_loss_2024 from
(with orders as (select *,to_char(order_date,'month') as months ,extract('month' from order_date) as m,
extract('year' from order_date) as years from orders)
select o.months,o.m,count(o.Or_ID) as order_return_2024,sum(o.qty) as qty_return_2024, 
round((sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100))::numeric,2) as loss_2024 
from orders as o join product as p on o.P_ID=p.P_ID join return_refund as rr on rr.Or_ID=o.Or_ID
where o.years=2024  group by o.months,o.m order by o.m asc) as lgs)
select months,  round(((order_return_2024-pre_order_return_2024))::numeric,2)  as MOM_return,
round(((qty_return_2024-pre_qty_return_2024))::numeric,2)  as MOM_qty_return,
round(((loss_2024-pre_loss_2024))::numeric,2)  as MOM_loss from mom_return_2024)
select om24.months,om24.MOM_orders as MOM_orders_2024 ,om24.MOM_qty as MOM_qty_2024,om24.MOM_sales as MOM_sales_2024 ,
rm24.MOM_return as MOM_return_2024,rm24.MOM_qty_return as MOM_qty_return_2024,
rm24.MOM_loss as MOM_loss_2024 from order_2024_mom as om24 join return_2024_mom as rm24 
on om24.months=rm24.months),
MOM_2023 as
(with order_2023_mom as
(with mom_order_2023 as
(select months,order_2023,lag(order_2023,1,0) over() as pre_order_2023, qty_2023,
lag(qty_2023,1,0) over() as pre_qty_2023 , amount_2023,lag(amount_2023,1,0) over() as pre_amount_2023 from
(with orders as (select *,to_char(order_date,'month') as months ,extract('month' from order_date) as m,
extract('year' from order_date) as years from orders)
select o.months,o.m,count(o.Or_ID) as order_2023,sum(o.qty) as qty_2023, 
round((sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100))::numeric,2) as amount_2023 
from orders as o join product as p on o.P_ID=p.P_ID 
where o.years=2023  group by o.months,o.m order by o.m asc) as lgs)
select months,  round(((order_2023-pre_order_2023))::numeric,2)  as MOM_orders,
round(((qty_2023-pre_qty_2023))::numeric,2)  as MOM_qty,
round(((amount_2023-pre_amount_2023))::numeric,2)  as MOM_sales from mom_order_2023),
return_2023_mom as
(with mom_return_2023 as
(select months,order_return_2023,lag(order_return_2023,1,0) over() as pre_order_return_2023, qty_return_2023,
lag(qty_return_2023,1,0) over() as pre_qty_return_2023 , loss_2023,lag(loss_2023,1,0) over() as pre_loss_2023 from
(with orders as (select *,to_char(order_date,'month') as months ,extract('month' from order_date) as m,
extract('year' from order_date) as years from orders)
select o.months,o.m,count(o.Or_ID) as order_return_2023,sum(o.qty) as qty_return_2023, 
round((sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100))::numeric,2) as loss_2023 
from orders as o join product as p on o.P_ID=p.P_ID join return_refund as rr on rr.Or_ID=o.Or_ID
where o.years=2023  group by o.months,o.m order by o.m asc) as lgs)
select months,  round(((order_return_2023-pre_order_return_2023))::numeric,2)  as MOM_return,
round(((qty_return_2023-pre_qty_return_2023))::numeric,2)  as MOM_qty_return,
round(((loss_2023-pre_loss_2023))::numeric,2)  as MOM_loss from mom_return_2023)
select om23.months,om23.MOM_orders as MOM_orders_2023,om23.MOM_qty as MOM_qty_2023,om23.MOM_sales as MOM_sales_2023 ,
rm23.MOM_return as MOM_return_2023,rm23.MOM_qty_return as MOM_qty_return_2023,
rm23.MOM_loss as MOM_loss_2023 from order_2023_mom as om23 join return_2023_mom as rm23 
on om23.months=rm23.months)
select m24.months,m24.MOM_orders_2024,m23.MOM_orders_2023,m24.MOM_qty_2024,m23.MOM_qty_2023,
m24.MOM_sales_2024,m23.MOM_sales_2023,m24.MOM_return_2024,m23.MOM_return_2023,m24.MOM_qty_return_2024,
m23.MOM_qty_return_2023,m24.MOM_loss_2024,m23.MOM_loss_2023 from MOM_2024 as m24 join MOM_2023 as m23 on m24.months=m23.months;

-- 13. Determine the year-by-year QOQ% orders, QOQ% quantity, QOQ% sales, QOQ% return, and QOQ% revenue loss.
with QOQ_2024 as
(with order_2024_qoq as
(with qoq_order_2024 as
(select quarters,order_2024,lag(order_2024,1,0) over() as pre_order_2024, qty_2024,
lag(qty_2024,1,0) over() as pre_qty_2024 , amount_2024,lag(amount_2024,1,0) over() as pre_amount_2024 from
(with orders as (select *,concat('Qtr ',extract('quarter' from order_date)) as quarters ,extract('quarter' from order_date) as q,
extract('year' from order_date) as years from orders)
select o.quarters,o.q,count(o.Or_ID) as order_2024,sum(o.qty) as qty_2024, 
round((sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100))::numeric,2) as amount_2024 
from orders as o join product as p on o.P_ID=p.P_ID 
where o.years=2024  group by o.quarters,o.q order by o.q asc) as lgs)
select quarters,  round(((order_2024-pre_order_2024))::numeric,2)  as QOQ_orders,
round(((qty_2024-pre_qty_2024))::numeric,2)  as QOQ_qty,
round(((amount_2024-pre_amount_2024))::numeric,2)  as QOQ_sales from qoq_order_2024),
return_2024_qoq as
(with qoq_return_2024 as
(select quarters,order_return_2024,lag(order_return_2024,1,0) over() as pre_order_return_2024, qty_return_2024,
lag(qty_return_2024,1,0) over() as pre_qty_return_2024 , loss_2024,lag(loss_2024,1,0) over() as pre_loss_2024 from
(with orders as (select *,concat('Qtr ',extract('quarter' from order_date)) as quarters ,extract('quarter' from order_date) as q,
extract('year' from order_date) as years from orders)
select o.quarters,o.q,count(o.Or_ID) as order_return_2024,sum(o.qty) as qty_return_2024, 
round((sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100))::numeric,2) as loss_2024 
from orders as o join product as p on o.P_ID=p.P_ID join return_refund as rr on rr.Or_ID=o.Or_ID
where o.years=2024  group by o.quarters,o.q order by o.q asc) as lgs)
select quarters,  round(((order_return_2024-pre_order_return_2024))::numeric,2)  as QOQ_return,
round(((qty_return_2024-pre_qty_return_2024))::numeric,2)  as QOQ_qty_return,
round(((loss_2024-pre_loss_2024))::numeric,2)  as QOQ_loss from qoq_return_2024)
select oq24.quarters,oq24.QOQ_orders as QOQ_orders_2024 ,oq24.QOQ_qty as QOQ_qty_2024,oq24.QOQ_sales as QOQ_sales_2024 ,
rq24.QOQ_return as QOQ_return_2024,rq24.QOQ_qty_return as QOQ_qty_return_2024,
rq24.QOQ_loss as QOQ_loss_2024 from order_2024_qoq as oq24 join return_2024_qoq as rq24 
on oq24.quarters=rq24.quarters),
QOQ_2023 as
(with order_2023_qoq as
(with qoq_order_2023 as
(select quarters,order_2023,lag(order_2023,1,0) over() as pre_order_2023, qty_2023,
lag(qty_2023,1,0) over() as pre_qty_2023 , amount_2023,lag(amount_2023,1,0) over() as pre_amount_2023 from
(with orders as (select *,concat('Qtr ',extract('quarter' from order_date)) as quarters ,extract('quarter' from order_date) as q,
extract('year' from order_date) as years from orders)
select o.quarters,o.q,count(o.Or_ID) as order_2023,sum(o.qty) as qty_2023, 
round((sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100))::numeric,2) as amount_2023 
from orders as o join product as p on o.P_ID=p.P_ID 
where o.years=2023  group by o.quarters,o.q order by o.q asc) as lgs)
select quarters,  round(((order_2023-pre_order_2023))::numeric,2)  as QOQ_orders,
round(((qty_2023-pre_qty_2023))::numeric,2)  as QOQ_qty,
round(((amount_2023-pre_amount_2023))::numeric,2)  as QOQ_sales from qoq_order_2023),
return_2023_qoq as
(with qoq_return_2023 as
(select quarters,order_return_2023,lag(order_return_2023,1,0) over() as pre_order_return_2023, qty_return_2023,
lag(qty_return_2023,1,0) over() as pre_qty_return_2023 , loss_2023,lag(loss_2023,1,0) over() as pre_loss_2023 from
(with orders as (select *,concat('Qtr ',extract('quarter' from order_date)) as quarters ,extract('quarter' from order_date) as q,
extract('year' from order_date) as years from orders)
select o.quarters,o.q,count(o.Or_ID) as order_return_2023,sum(o.qty) as qty_return_2023, 
round((sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100))::numeric,2) as loss_2023 
from orders as o join product as p on o.P_ID=p.P_ID join return_refund as rr on rr.Or_ID=o.Or_ID
where o.years=2023  group by o.quarters,o.q order by o.q asc) as lgs)
select quarters,  round(((order_return_2023-pre_order_return_2023))::numeric,2)  as QOQ_return,
round(((qty_return_2023-pre_qty_return_2023))::numeric,2)  as QOQ_qty_return,
round(((loss_2023-pre_loss_2023))::numeric,2)  as QOQ_loss from qoq_return_2023)
select oq23.quarters,oq23.QOQ_orders as QOQ_orders_2023,oq23.QOQ_qty as QOQ_qty_2023,oq23.QOQ_sales as QOQ_sales_2023 ,
rq23.QOQ_return as QOQ_return_2023,rq23.QOQ_qty_return as QOQ_qty_return_2023,
rq23.QOQ_loss as QOQ_loss_2023 from order_2023_qoq as oq23 join return_2023_qoq as rq23 
on oq23.quarters=rq23.quarters)
select q24.quarters as Quarters ,q24.QOQ_orders_2024 as QOQ_orders_2024 ,q23.QOQ_orders_2023 as QOQ_orders_2023 ,
q24.QOQ_qty_2024 as QOQ_qty_2024,q23.QOQ_qty_2023 as QOQ_qty_2023,
q24.QOQ_sales_2024 as QOQ_sales_2024 ,q23.QOQ_sales_2023 as QOQ_sales_2023,q24.QOQ_return_2024 as QOQ_return_2024 ,
q23.QOQ_return_2023 as QOQ_return_2023,q24.QOQ_qty_return_2024 as QOQ_qty_return_2024,
q23.QOQ_qty_return_2023 as QOQ_qty_return_2023,q24.QOQ_loss_2024 as QOQ_loss_2024,
q23.QOQ_loss_2023 as QOQ_loss_2023 from QOQ_2024 as q24 join QOQ_2023 as q23 on q24.quarters=q23.quarters;

-- 14. Determine which product each company is returns the most, based on loss and which one the least.
select * from
(with o_loss_2024 as
(with rank_2024 as
(select *, row_number() over (partition by company_name order by loss_2024 desc ) as ranks from
(with orders as (select *,extract('year' from order_date) as years from orders)
select p.company_name,p.p_name,count(o.Or_ID) as order_2024,sum(o.qty) as qty_2024 ,
round((sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100))::numeric,2) as loss_2024 from product as p join orders as o
on o.P_ID=p.P_ID join return_refund as rr on rr.Or_ID=o.Or_ID where o.years=2024
group by p.company_name,p.p_name) as rnk)
select * from rank_2024 where ranks=(select min(ranks) from rank_2024)),
o_loss_2023 as
(with rank_2023 as
(select *, row_number() over (partition by company_name order by loss_2023 desc ) as ranks from
(with orders as (select *,extract('year' from order_date) as years from orders)
select p.company_name,p.p_name,count(o.Or_ID) as order_2023,sum(o.qty) as qty_2023 ,
round((sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100))::numeric,2) as loss_2023 from product as p join orders as o
on o.P_ID=p.P_ID join return_refund as rr on rr.Or_ID=o.Or_ID where o.years=2023
group by p.company_name,p.p_name) as rnk)
select * from rank_2023 where ranks=(select min(ranks) from rank_2023))
select ol24.company_name,ol24.p_name,ol24.order_2024,ol24.qty_2024,ol24.loss_2024,
ol23.order_2023,ol23.qty_2023,ol23.loss_2023 from o_loss_2024 as ol24 join o_loss_2023 as ol23
on ol24.company_name=ol23.company_name) union all
select * from
(with o_loss_2024 as
(with rank_2024 as
(select *, row_number() over (partition by company_name order by loss_2024 asc ) as ranks from
(with orders as (select *,extract('year' from order_date) as years from orders)
select p.company_name,p.p_name,count(o.Or_ID) as order_2024,sum(o.qty) as qty_2024 ,
round((sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100))::numeric,2) as loss_2024 from product as p join orders as o
on o.P_ID=p.P_ID join return_refund as rr on rr.Or_ID=o.Or_ID where o.years=2024
group by p.company_name,p.p_name) as rnk)
select * from rank_2024 where ranks=(select min(ranks) from rank_2024)),
o_loss_2023 as
(with rank_2023 as
(select *, row_number() over (partition by company_name order by loss_2023 asc ) as ranks from
(with orders as (select *,extract('year' from order_date) as years from orders)
select p.company_name,p.p_name,count(o.Or_ID) as order_2023,sum(o.qty) as qty_2023 ,
round((sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100))::numeric,2) as loss_2023 from product as p join orders as o
on o.P_ID=p.P_ID join return_refund as rr on rr.Or_ID=o.Or_ID where o.years=2023
group by p.company_name,p.p_name) as rnk)
select * from rank_2023 where ranks=(select min(ranks) from rank_2023))
select ol24.company_name,ol24.p_name,ol24.order_2024,ol24.qty_2024,ol24.loss_2024,
ol23.order_2023,ol23.qty_2023,ol23.loss_2023 from o_loss_2024 as ol24 join o_loss_2023 as ol23
on ol24.company_name=ol23.company_name) order by company_name;

-- 15. Look for consumers who, has the highest purchase (orders,qty and amount) as who has the lowest, citywise.
select * from
(with c_amt_2024 as
(with rank_2024 as 
(select * , row_number() over(partition by city order by amount_2024 desc) as ranks from
(with orders as (select *,extract('year' from order_date) as years from orders) 
select c.city,c.c_name as c_name_2024,count(o.Or_ID) as order_2024,sum(o.qty) as qty_2024,
round((sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100))::numeric,2) as amount_2024 
from customer as c join orders as o on o.C_ID=c.C_ID join product as p on p.P_ID=o.P_ID
where o.years=2024  group by c.city,c.c_name) as rnk)
select * from rank_2024 where ranks=(select min(ranks) from rank_2024 )),
c_amt_2023 as
(with rank_2023 as 
(select * , row_number() over(partition by city order by amount_2023 desc) as ranks from
(with orders as (select *,extract('year' from order_date) as years from orders) 
select c.city,c.c_name as c_name_2023,count(o.Or_ID) as order_2023,sum(o.qty) as qty_2023,
round((sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100))::numeric,2) as amount_2023 
from customer as c join orders as o on o.C_ID=c.C_ID join product as p on p.P_ID=o.P_ID
where o.years=2023  group by c.city,c.c_name) as rnk) 
select * from rank_2023 where ranks=(select min(ranks) from rank_2023 ))
select co24.city,co24.c_name_2024,co24.order_2024,co24.qty_2024,co24.amount_2024,co23.c_name_2023,
co23.order_2023,co23.qty_2023,co23.amount_2023 from c_amt_2024 as co24 join c_amt_2023 as co23
on co24.city=co23.city) union all
select * from
(with c_amt_2024 as
(with rank_2024 as 
(select * , row_number() over(partition by city order by amount_2024 asc) as ranks from
(with orders as (select *,extract('year' from order_date) as years from orders) 
select c.city,c.c_name as c_name_2024,count(o.Or_ID) as order_2024,sum(o.qty) as qty_2024,
round((sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100))::numeric,2) as amount_2024 
from customer as c join orders as o on o.C_ID=c.C_ID join product as p on p.P_ID=o.P_ID
where o.years=2024  group by c.city,c.c_name) as rnk)
select * from rank_2024 where ranks=(select min(ranks) from rank_2024 )),
c_amt_2023 as
(with rank_2023 as 
(select * , row_number() over(partition by city order by amount_2023 asc) as ranks from
(with orders as (select *,extract('year' from order_date) as years from orders) 
select c.city,c.c_name as c_name_2023,count(o.Or_ID) as order_2023,sum(o.qty) as qty_2023,
round((sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100))::numeric,2) as amount_2023 
from customer as c join orders as o on o.C_ID=c.C_ID join product as p on p.P_ID=o.P_ID
where o.years=2023  group by c.city,c.c_name) as rnk) 
select * from rank_2023 where ranks=(select min(ranks) from rank_2023 ))
select co24.city,co24.c_name_2024,co24.order_2024,co24.qty_2024,co24.amount_2024,co23.c_name_2023,
co23.order_2023,co23.qty_2023,co23.amount_2023 from c_amt_2024 as co24 join c_amt_2023 as co23
on co24.city=co23.city) order by city asc;

-- 16. Determine which state has the highest rating for delivery partners  as which the lowest , yearwise
select * from 
(with dv_2024 as
(with rnk_2024 as
(select *, row_number() over (partition by states order by delivery_service_rating_2024 desc ) as ranks from
(with orders as (select *,extract('year' from order_date) as years from orders) 
select c.states,d.dp_name as dp_name_2024, round(avg(r.delivery_service_rating)::numeric,2) as delivery_service_rating_2024
from customer as c join orders as o on c.C_ID=o.C_ID join delivery as d on d.DP_ID=o.DP_ID join rating as r on
r.Or_ID=o.Or_ID where o.years=2024 group by c.states,d.dp_name) as rnk)
select * from rnk_2024 where ranks=(select min(ranks) from rnk_2024 )),
dv_2023 as
(with rnk_2023 as
(select *, row_number() over (partition by states order by delivery_service_rating_2023 desc ) as ranks from
(with orders as (select *,extract('year' from order_date) as years from orders) 
select c.states,d.dp_name as dp_name_2023, round(avg(r.delivery_service_rating)::numeric,2) as delivery_service_rating_2023
from customer as c join orders as o on c.C_ID=o.C_ID join delivery as d on d.DP_ID=o.DP_ID join rating as r on
r.Or_ID=o.Or_ID where o.years=2023 group by c.states,d.dp_name) as rnk)
select * from rnk_2023 where ranks=(select min(ranks) from rnk_2023 ))
select dv24.states,dv24.dp_name_2024,dv24.delivery_service_rating_2024,dv23.dp_name_2023,dv23.delivery_service_rating_2023
from dv_2024 as dv24 join dv_2023 as dv23 on dv24.states=dv23.states) union all
select * from 
(with dv_2024 as
(with rnk_2024 as
(select *, row_number() over (partition by states order by delivery_service_rating_2024 asc ) as ranks from
(with orders as (select *,extract('year' from order_date) as years from orders) 
select c.states,d.dp_name as dp_name_2024, round(avg(r.delivery_service_rating)::numeric,2) as delivery_service_rating_2024
from customer as c join orders as o on c.C_ID=o.C_ID join delivery as d on d.DP_ID=o.DP_ID join rating as r on
r.Or_ID=o.Or_ID where o.years=2024 group by c.states,d.dp_name) as rnk)
select * from rnk_2024 where ranks=(select min(ranks) from rnk_2024 )),
dv_2023 as
(with rnk_2023 as
(select *, row_number() over (partition by states order by delivery_service_rating_2023 asc ) as ranks from
(with orders as (select *,extract('year' from order_date) as years from orders) 
select c.states,d.dp_name as dp_name_2023, round(avg(r.delivery_service_rating)::numeric,2) as delivery_service_rating_2023
from customer as c join orders as o on c.C_ID=o.C_ID join delivery as d on d.DP_ID=o.DP_ID join rating as r on
r.Or_ID=o.Or_ID where o.years=2023 group by c.states,d.dp_name) as rnk)
select * from rnk_2023 where ranks=(select min(ranks) from rnk_2023 ))
select dv24.states,dv24.dp_name_2024,dv24.delivery_service_rating_2024,dv23.dp_name_2023,dv23.delivery_service_rating_2023
from dv_2024 as dv24 join dv_2023 as dv23 on dv24.states=dv23.states) order by states asc;

-- 17. Find out which delivery partners  handled the brand the highest-value orders and lowest-value orders, yearwise, along with revenue generated
select * from
(with dv_2024 as 
(with rnk_2024 as 
(select *, row_number() over(partition by dp_name order by orders_2024 desc) as ranks from
(with orders as (select *,extract('year' from order_date) as years from orders)
select d.dp_name,p.company_name as company_2024,count(o.Or_ID) as orders_2024,
round((sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100)*avg(d.percent_cut))::numeric,2) as amount_2024 from
product as p join orders as o on o.P_ID=p.P_ID join delivery as d on d.DP_ID=o.DP_ID where o.years=2024 group by 
d.dp_name,p.company_name) as rnk)
select * from rnk_2024 where ranks = (select min(ranks) from rnk_2024 )),
dv_2023 as
(with rnk_2023 as 
(select *, row_number() over(partition by dp_name order by orders_2023 desc) as ranks from
(with orders as (select *,extract('year' from order_date) as years from orders)
select d.dp_name,p.company_name as company_2023,count(o.Or_ID) as orders_2023,
round((sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100)*avg(d.percent_cut))::numeric,2) as amount_2023 from
product as p join orders as o on o.P_ID=p.P_ID join delivery as d on d.DP_ID=o.DP_ID where o.years=2023 group by 
d.dp_name,p.company_name) as rnk)
select * from rnk_2023 where ranks = (select min(ranks) from rnk_2023 ))
select  d24.dp_name,d24.company_2024,d24.orders_2024,d24.amount_2024,
d23.company_2023,d23.orders_2023,d23.amount_2023 from dv_2024 as d24 join dv_2023 as d23 on
d24.dp_name=d23.dp_name) union all
select * from
(with dv_2024 as 
(with rnk_2024 as 
(select *, row_number() over(partition by dp_name order by orders_2024 asc) as ranks from
(with orders as (select *,extract('year' from order_date) as years from orders)
select d.dp_name,p.company_name as company_2024,count(o.Or_ID) as orders_2024,
round((sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100)*avg(d.percent_cut))::numeric,2) as amount_2024 from
product as p join orders as o on o.P_ID=p.P_ID join delivery as d on d.DP_ID=o.DP_ID where o.years=2024 group by 
d.dp_name,p.company_name) as rnk)
select * from rnk_2024 where ranks = (select min(ranks) from rnk_2024 )),
dv_2023 as
(with rnk_2023 as 
(select *, row_number() over(partition by dp_name order by orders_2023 asc) as ranks from
(with orders as (select *,extract('year' from order_date) as years from orders)
select d.dp_name,p.company_name as company_2023,count(o.Or_ID) as orders_2023,
round((sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100)*avg(d.percent_cut))::numeric,2) as amount_2023 from
product as p join orders as o on o.P_ID=p.P_ID join delivery as d on d.DP_ID=o.DP_ID where o.years=2023 group by 
d.dp_name,p.company_name) as rnk)
select * from rnk_2023 where ranks = (select min(ranks) from rnk_2023 ))
select  d24.dp_name,d24.company_2024,d24.orders_2024,d24.amount_2024,
d23.company_2023,d23.orders_2023,d23.amount_2023 from dv_2024 as d24 join dv_2023 as d23 on
d24.dp_name=d23.dp_name) order by dp_name

-- 18. Find out which delivery partners on product category the highest-value return and lowest-value return, yearwise, along with revenue lost
select * from
(with dv_2024 as 
(with rnk_2024 as 
(select *, row_number() over(partition by dp_name order by orders_return_2024 desc) as ranks from
(with orders as (select *,extract('year' from order_date) as years from orders)
select d.dp_name,p.category as category_2024,count(o.Or_ID) as orders_return_2024,
round((sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100)*avg(d.percent_cut))::numeric,2) as loss_2024 from
product as p join orders as o on o.P_ID=p.P_ID join delivery as d on d.DP_ID=o.DP_ID where o.years=2024 group by 
d.dp_name,p.category) as rnk)
select * from rnk_2024 where ranks = (select min(ranks) from rnk_2024 )),
dv_2023 as
(with rnk_2023 as 
(select *, row_number() over(partition by dp_name order by orders_return_2023 desc) as ranks from
(with orders as (select *,extract('year' from order_date) as years from orders)
select d.dp_name,p.category as category_2023,count(o.Or_ID) as orders_return_2023,
round((sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100)*avg(d.percent_cut))::numeric,2) as loss_2023 from
product as p join orders as o on o.P_ID=p.P_ID join delivery as d on d.DP_ID=o.DP_ID where o.years=2023 group by 
d.dp_name,p.category) as rnk)
select * from rnk_2023 where ranks = (select min(ranks) from rnk_2023 ))
select  d24.dp_name,d24.category_2024,d24.orders_return_2024,d24.loss_2024,
d23.category_2023,d23.orders_return_2023,d23.loss_2023 from dv_2024 as d24 join dv_2023 as d23 on
d24.dp_name=d23.dp_name) union all
select * from
(with dv_2024 as 
(with rnk_2024 as 
(select *, row_number() over(partition by dp_name order by orders_return_2024 asc) as ranks from
(with orders as (select *,extract('year' from order_date) as years from orders)
select d.dp_name,p.category as category_2024,count(o.Or_ID) as orders_return_2024,
round((sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100)*avg(d.percent_cut))::numeric,2) as loss_2024 from
product as p join orders as o on o.P_ID=p.P_ID join delivery as d on d.DP_ID=o.DP_ID where o.years=2024 group by 
d.dp_name,p.category) as rnk)
select * from rnk_2024 where ranks = (select min(ranks) from rnk_2024 )),
dv_2023 as
(with rnk_2023 as 
(select *, row_number() over(partition by dp_name order by orders_return_2023 asc) as ranks from
(with orders as (select *,extract('year' from order_date) as years from orders)
select d.dp_name,p.category as category_2023,count(o.Or_ID) as orders_return_2023,
round((sum(o.qty)*avg(p.price)*(1-avg(o.discount)/100)*avg(d.percent_cut))::numeric,2) as loss_2023 from
product as p join orders as o on o.P_ID=p.P_ID join delivery as d on d.DP_ID=o.DP_ID where o.years=2023 group by 
d.dp_name,p.category) as rnk)
select * from rnk_2023 where ranks = (select min(ranks) from rnk_2023 ))
select  d24.dp_name,d24.category_2024,d24.orders_return_2024,d24.loss_2024,
d23.category_2023,d23.orders_return_2023,d23.loss_2023 from dv_2024 as d24 join dv_2023 as d23 on
d24.dp_name=d23.dp_name) order by dp_name

-- 19. Determine delivery partner monthly analysis, which includes the  revenue earned, yearwise
with total_order as 
(with orders as (select *, extract('months' from order_date) as m, to_char(order_date,'month') as months, 
extract('year' from order_date) as years  from orders )
select o.months,o.m, 
sum(case when o.years=2024 and d.dp_name='Delhivery' then o.qty*p.price*(1-o.discount/100)*(d.percent_cut/100) else 0 end ) as Delhivery_2024,
sum(case when o.years=2023 and d.dp_name='Delhivery' then o.qty*p.price*(1-o.discount/100)*(d.percent_cut/100) else 0 end ) as Delhivery_2023,
sum(case when o.years=2024 and d.dp_name='Blue Dart' then o.qty*p.price*(1-o.discount/100)*(d.percent_cut/100) else 0 end ) as Blue_Dart_2024,
sum(case when o.years=2023 and d.dp_name='Blue Dart' then o.qty*p.price*(1-o.discount/100)*(d.percent_cut/100) else 0 end ) as Blue_Dart_2023,
sum(case when o.years=2024 and d.dp_name='Ecom Express' then o.qty*p.price*(1-o.discount/100)*(d.percent_cut/100) else 0 end ) as Ecom_Express_2024,
sum(case when o.years=2023 and d.dp_name='Ecom Express' then o.qty*p.price*(1-o.discount/100)*(d.percent_cut/100) else 0 end ) as Ecom_Express_2023,
sum(case when o.years=2024 and d.dp_name='Shadowfax' then o.qty*p.price*(1-o.discount/100)*(d.percent_cut/100) else 0 end ) as Shadowfax_2024,
sum(case when o.years=2023 and d.dp_name='Shadowfax' then o.qty*p.price*(1-o.discount/100)*(d.percent_cut/100) else 0 end ) as Shadowfax_2023,
sum(case when o.years=2024 and d.dp_name='Xpressbees' then o.qty*p.price*(1-o.discount/100)*(d.percent_cut/100) else 0 end ) as Xpressbees_2024,
sum(case when o.years=2023 and d.dp_name='Xpressbees' then o.qty*p.price*(1-o.discount/100)*(d.percent_cut/100) else 0 end ) as Xpressbees_2023
from orders as o join product as p on o.P_ID=p.P_ID join delivery as d on d.DP_ID=o.DP_ID
group by o.months , o.m order by o.m asc)
select months, round(Delhivery_2024::numeric,2) as Delhivery_2024,round(Delhivery_2023::numeric,2) as Delhivery_2023,
round(Blue_Dart_2024::numeric,2) as Blue_Dart_2024,round(Blue_Dart_2023::numeric,2) as Blue_Dart_2023,
round(Ecom_Express_2024::numeric,2) as Ecom_Express_2024,round(Ecom_Express_2023::numeric,2) as Ecom_Express_2023,
round(Shadowfax_2024::numeric,2) as Shadowfax_2024,round(Shadowfax_2023::numeric,2) as Shadowfax_2023,
round(Xpressbees_2024::numeric,2) as Xpressbees_2024,round(Xpressbees_2024::numeric,2) as Xpressbees_2024 from total_order;









                                                                                                                                                                                                                                         





