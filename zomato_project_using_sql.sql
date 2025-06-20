
-- Sql Zomato Project


create database zomato;
use zomato;
drop table if exists goldusers_signup;
CREATE TABLE goldusers_signup(userid integer, gold_signup_date date); 

INSERT INTO goldusers_signup(userid, gold_signup_date) 
 VALUES (1, '2017-09-22'),
(3, '2017-04-21');

drop table if exists users;
CREATE TABLE users(userid integer, signup_date date); 

INSERT INTO users(userid, signup_date) 
 VALUES (1, '2014-09-02'),
(2, '2015-01-15'),
(3, '2014-04-11');

drop table if exists sales;
CREATE TABLE sales(userid integer, created_date date, product_id integer); 

INSERT INTO sales(userid, created_date, product_id) 
 VALUES (1, '2017-04-19', 2),
(3, '2019-12-18', 1),
(2, '2020-07-20', 3),
(1, '2019-10-23', 2),
(1, '2018-03-19', 3),
(3, '2016-12-20', 2),
(1, '2016-11-09', 1),
(1, '2016-05-20', 3),
(2, '2017-09-24', 1),
(1, '2017-03-11', 2),
(1, '2016-03-11', 1),
(3, '2016-11-10', 1),
(3, '2017-12-07', 2),
(3, '2016-12-15', 2),
(2, '2017-11-08', 2),
(2, '2018-09-10', 3);

drop table if exists product;
CREATE TABLE product(product_id integer, product_name text, price integer); 

INSERT INTO product(product_id, product_name, price) 
 VALUES
(1, 'p1', 980),
(2, 'p2', 870),
(3, 'p3', 330);

select * from sales;
select * from product;
select * from goldusers_signup;
select * from users;

-- Q1 What is the total amount each customer has spent on zomato?
select  s.userid, sum(p.price) as total_amount from sales s join product p on s.product_id = p.product_id
group by s.userid;

-- Q2 How many days each customer has visited zomato?
select userid, count(distinct created_date) as cnt from  sales group by userid;

with cte as (select sales.userid, count(sales.created_date) as e1, 
count(goldusers_signup.gold_signup_date) as e2, 
count(users.signup_date) as e3 from users left join sales using(userid) left join goldusers_signup 
using(userid) group by sales.userid) 
select userid, e1+e2+e3 as total_days_spent from cte;


-- Q3 What was the first product purchased by each customer?
select * from (
select *, rank() over(partition by userid order by created_date ) rk from sales ) a
where rk = 1;


-- Q4 Whats is the most purchased item on the menu and how many times was it purchased by all customers?
with cte as (select product_id, count(product_id) as cnt from sales 
			group by product_id 
			order by cnt desc
            limit 1),
cte2 as (select * from sales where product_id = ((select product_id from cte)))
select userid, count(product_id) as cnt from cte2 group by userid;


-- Q5 Which Item was the most popular for each customer?
with cte as (select userid, product_id, count(product_id) as cnt from sales group by userid, product_id),
cte2 as (select *, rank() over(partition by userid order by cnt desc) as rk from cte)
select * from cte2 where rk = 1;

-- Q6 Which item was purchased first by the customer when they becoame a gold member?
select * from goldusers_signup;
with cte as (select s.*, g.gold_signup_date from sales s join goldusers_signup g 
			on s.userid = g.userid and s.created_date >= g.gold_signup_date)
select * from (select *, rank() over(partition by userid order by created_date) as rk from cte) a  where rk = 1;

-- Q7 Which item was purchased by the customer just before they becoame a gold member? 
with cte as (select s.*, g.gold_signup_date from sales s join goldusers_signup g 
			on s.userid = g.userid and s.created_date <= g.gold_signup_date)
select * from (select *, rank() over(partition by userid order by created_date desc) as rk from cte) a  where rk = 1;

-- Q8 What is total orders and amount spent for each member before they become a member?

with cte as (select s.*, g.gold_signup_date from sales s join goldusers_signup g 
			on s.userid = g.userid and s.created_date < g.gold_signup_date),
cte2 as (select cte.*, p.price from cte join product as p using(product_id)) 

select userid, count(created_date) as order_perchased, sum(price) as total_amt_spent from cte2 group by userid;

-- Q9 If buying each product generates points and each product has different purchasing points for 
-- eg p1 5Rs = 1 point, for p2 10Rs = 5 points and p3 5Rs = 1 point. Calculate 
-- a). total points earned by each customer b). for which product has given more points.
-- a)
with cte as (select s.*, p.price from sales s join product p on s.product_id = p.product_id),
cte2 as (select userid, product_id, sum(price) as amount from cte group by userid, product_id order by userid ),
cte3 as(select *, case when product_id = 1 then 5
			   when  product_id = 2 then 2
               when product_id = 3 then 5
               else 0 
		  end as points
from cte2),
cte4 as (select userid, product_id, amount, round(amount/points,0) as  total_points from cte3)

select userid, sum(total_points) * 2.5 as total_points_earned from cte4 group by userid;

-- b)
with cte as (select s.*, p.price from sales s join product p on s.product_id = p.product_id),
cte2 as (select userid, product_id, sum(price) as amount from cte group by userid, product_id order by userid ),
cte3 as(select *, case when product_id = 1 then 5
			   when  product_id = 2 then 2
               when product_id = 3 then 5
               else 0 
		  end as points
from cte2),
cte4 as (select userid, product_id, amount, round(amount/points,0) as  total_points from cte3)

select product_id, sum(total_points) as total_points_earned from cte4 group by product_id order by total_points_earned desc limit 1;

-- Q10 In the first one year after customer joins gold membership (including the joining date) 
-- irrespective of what the customer has purchased they earn 5 points for every 10 Rs spent. 
-- Which customers have earned more points in that their first years?

with cte as 
(select s.*, g.gold_signup_date, p.price
from sales s join goldusers_signup g on s.userid = g.userid and s.created_date >= g.gold_signup_date 
and s.created_date <= date_add(gold_signup_date, interval 1 year)
join product p on s.product_id = p.product_id)

select userid, (price * 0.5) as total_points_earned from cte order by userid;


-- Q11 Rank all the transactions of every customer
select *, rank() over(partition by userid order by created_date) as rk from sales;


-- Q12 Rank all the transactions for each gold member and for a non-gold member return NA in the rank.
select s.*,
	case when s.created_date >= g.gold_signup_date then rank() over(partition by userid order by created_date desc) 
		 else "NA"
	end as "rank"
from sales s join goldusers_signup g using(userid);





