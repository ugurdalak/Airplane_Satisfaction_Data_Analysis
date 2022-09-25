select * from aps a;

select count(id)-count(distinct id) from aps a; --checking if IDs are unique or not 

SELECT
	gender,
	count(gender),
	count(gender)::REAL /(
	SELECT
		count(*)
	FROM
		aps)* 100 AS percentage
FROM
	aps
GROUP BY
	gender; 
-- there are 65899 female and 63981 male customers. 50.7% female and 49.3 male

select * ,
case 
	when age <=18 then 'young'
	when age <=40 then 'middle-age'
	else 'older'
end as age_group
from  aps a; 
create table dataanalysis as 
select
	count(*) as count_of_passenger,
	count(*)::real /(
	select
		count(*)
	from
		aps a2)* 100 as percentage , 
	gender,
	age_group,
	flight_class,
	customer_type,
	type_of_travel,
	satisfaction,
	round( avg(departure_delay) , 2) departure_delay ,
	round( avg(flight_distance) , 2) flight_distance ,
	round( avg(arrival_delay) , 2) arrival_delay ,
	round( avg(dep_and_arr_time_convenience) , 2) dep_and_arr_time_convenience ,
	round( avg(ease_of_online_booking) , 2) ease_of_online_booking ,
	round( avg(checkin_service) , 2) checkin_service ,
	round( avg(online_boarding) , 2) online_boarding ,
	round( avg(gate_location) , 2) gate_location ,
	round( avg(onboard_service) , 2) onboard_service ,
	round( avg(seat_comfort) , 2) seat_comfort ,
	round( avg(leg_room_service) , 2) leg_room_service ,
	round( avg(cleanliness) , 2) cleanliness ,
	round( avg(food_and_drink) , 2) food_and_drink ,
	round( avg(inflight_service) , 2) inflight_service ,
	round( avg(inflight_wifi_service) , 2) inflight_wifi_service ,
	round( avg(inflight_entertainment) , 2) inflight_entertainment ,
	round( avg(baggage_handling) , 2) baggage_handling
from
	(
	select
		* ,
		case
			when age <= 18 then 'young'
			when age <= 40 then 'middle-age'
			else 'older'
		end as age_group
	from
		aps a ) t
group by
	gender,
	age_group,
	flight_class,
	customer_type,
	type_of_travel,
	satisfaction;
--An overview for whole customers
select
	satisfaction,
	round(sum(percentage)::decimal, 1) as percentage
from
	dataanalysis d
group by
	satisfaction;
--The percentage of the customers who said they were satisfied is 43.4
select
	type_of_travel ,
	round(sum(percentage)::decimal, 1) as percentage 
from
	dataanalysis d
group by
	type_of_travel
order by 1 ;
--69% of customers chose the company for business travel. The personal-based travel percentage is almost 31%
select
	flight_class,
	round(sum(percentage)::decimal, 1) as percentage
from
	dataanalysis d
group by
	flight_class;
--47.9% of total customers flew in Business Class
--44.9% of total customers flew in Economy Class
--The Economy Plus Class is not a popular choice across customers; only 7.2% of customers flew in Economy Plus
select
	customer_type ,
	round(sum(percentage)::decimal, 1) as percentage
from
	dataanalysis d
group by
	customer_type;
--•	The 81.7 of total customers flew with the company earlier, first-time customers’ percentage is  18.3%
with agec as
(select age,row_number () over(partition by age order by age) as agecount
from aps a)
select age, count(agecount) as agecount
from agec
group by age
order by 2 desc
limit 10;
-- The top 10 repeated ages are 39,25,40,44,41,42,43,45,23,22
select
	max(age) as maxage,
	min(age) as minage,
	count(distinct age) as age_values
from
	aps a2; 
--There are 75 different age values in customers the min age is 7 and max age is 85
with agec2 as
(
select age,
	case
		when age between 7 and 20 then 'age7-18'
		when age between 21 and 30 then 'age 19-30'
		when age between 31 and 40  then 'age 31-40'
		when age between 41 and 50 then 'age 41-50'
		when age between 51 and 60 then 'age 51-60'
		else '+60'
		end	as age_bins	
		,
		row_number () over(partition by age
	order by
		age) as agecount
	from
		aps a)
select
	age_bins,
	count(agecount) as agecount
from
	agec2
group by
	age_bins
order by
	2 desc;
-- When bins are created, there is no huge difference between the 4 groups: 19-30, 31-40, 41-50, and 51-60  
select max(flight_distance) as max, min(flight_distance) as min from aps a; 
select
	case
		when flight_distance between 31 and 1000 then 'till1000'
		when flight_distance between 1001 and 2000 then 'till2000'
		when flight_distance between 2001 and 3000 then 'till3000'
		when flight_distance between 3001 and 4000 then 'till4000'
		when flight_distance between 4001 and 4983 then 'till5000'
	end as distance_group,
	count(satisfaction) as nofcustomer,
	round(avg(arrival_delay)) as avg_arrival_delay_mins,
	round(avg(departure_delay)) as avg_departure_delay_mins 
from
	aps a
group by
	distance_group
order by
	1;
select flight_distance,arrival_delay,departure_delay from aps a 
order by departure_delay desc,arrival_delay desc;

--The average arrival and departure delays are similar between the distance groups. However, there are too many outliers. That's why it is meaningless to look at the relationship between the distance group and delay. 
--There is a negative relationship between the distance group and the number of customers.
with stat as
(select
	round(stddev_samp(arrival_delay),2) as stdarrival,
	round(stddev_samp(departure_delay),2) as stddeparture,
    round(avg(arrival_delay),2) as avg_arrival_delay_mins,
	round(avg(departure_delay),2) as avg_departure_delay_mins
from
	aps)
select (avg_arrival_delay_mins - stdarrival * 2) as lowerboundforarr,
(avg_arrival_delay_mins + stdarrival * 2) as upperboundforarr,
(avg_departure_delay_mins - stddeparture * 2) as lowerboundfordep,
(avg_departure_delay_mins + stddeparture * 2) as upperboundfordep
from stat;
--upper bound for arrival delay is 92.03 in %95 distribution
--upper bound for departure delay is 90.85 in %95 distribution
select count(arrival_delay) from aps a where arrival_delay > 92;
--there are 5038 values as outliers in %95 distribution
select count(departure_delay) from aps a where departure_delay > 92;
--there are 4924 values as outliers in %95 distribution

--2-First-Time Customer Analysis
create view first_time_cust as 
(select
	gender,
	age,
	type_of_travel,
	flight_class,
	flight_distance,
	departure_delay,
	arrival_delay,
	dep_and_arr_time_convenience,
	ease_of_online_booking,
	checkin_service,
	online_boarding,
	gate_location,
	onboard_service,
	seat_comfort,
	leg_room_service,
	cleanliness,
	food_and_drink,
	inflight_service,
	inflight_wifi_service,
	inflight_entertainment,
	baggage_handling,
	satisfaction
from
	aps
where
	customer_type = 'First-time')
	--------------------------------------
select
	gender,
	count(gender),
	round(count(gender)::decimal /(select count(*) from first_time_cust)* 100, 2) as percentage
from
	first_time_cust
group by
	gender;
--There are 12843 female and 10937 male customers who flew with the company for the first time. The females' percentage is 54% and the males' percentage is 46 %.
select
	satisfaction,round(count(satisfaction)::decimal/(select count(*) from first_time_cust)*100,2) as ratio
from
	first_time_cust
	group by satisfaction
--	The percentage of the first time customers who said they were satisfied is around 24 % 
select
	flight_class,
	round(count(satisfaction)::decimal/(select count(*) from first_time_cust)*100,1) as ratio
from
	first_time_cust 
group by
	flight_class;
--	57.3 % of first-time customers flew in Economy Class, which is almost 6 of 10 first-time customers flew in Economy Class.
--	38.8 % of first-time customers flew in Business Class
--	3.8 % of first-time customers flew in Economy Plus Class
with agec as
(select age,row_number () over(partition by age order by age) as agecount
from first_time_cust)
select age, count(agecount) as agecount
from agec
group by age
order by 2 desc
limit 10;
-- The top 10 repeated ages are 25,22,23,24,26,27,20,21,37,38
with agec2 as
(
select age,
	case
		when age between 7 and 20 then 'age7-18'
		when age between 21 and 30 then 'age 19-30'
		when age between 31 and 40  then 'age 31-40'
		when age between 41 and 50 then 'age 41-50'
		when age between 51 and 60 then 'age 51-60'
		else '+60'
		end	as age_bins	
		,
		row_number () over(partition by age
	order by
		age) as agecount
	from
		first_time_cust)
select
	age_bins,
	count(agecount) as agecount,
	round(count(agecount)::decimal/(select count(*) from agec2)*100,2) as ratio
from
	agec2
group by
	age_bins
order by
	2 desc;
-- 3-	Survey Index Segmentation Analysis
--There are 14 different survey indexes to be asked to customers
--I segmented these 14 different indexes to 3 different parts:
----	Pre-Flight Indexes: Ease of Online Booking, Check-in Service, Online Boarding, Gate Location, On-Board Service
----	In-Flight Indexes: Seat Comfort, Leg Room Service, Cleanliness, Food and Drink, In-flight service, In-Flight Wifi Service, In Flight Entertainment 
----	After-Flight Indexes: Departure and Arrival Time Convenience, Baggage Handling
--Pre-Flight Indexes:
select
    flight_class,
    satisfaction,
	round(avg(ease_of_online_booking),1) as avg_ease_of_online_booking,
	round(avg(checkin_service),1) as avg_checkin_service,
	round(avg(online_boarding),1) as avg_online_boarding, 
	round(avg(gate_location),1) as avg_gate_location,
	round(avg(onboard_service),1) as avg_onboard_service 
from
	aps a 
group by flight_class,satisfaction;
--In-Flight Indexes:
select
    flight_class,
    satisfaction,
	round(avg(seat_comfort),1) as seat_comfort,
	round(avg(leg_room_service),1) as leg_room_s,
	round(avg(cleanliness),1) as cleanliness, 
	round(avg(food_and_drink),1) as food_and_drink, 
	round(avg(inflight_service),3) as if_service,
	round(avg(onboard_service),1) as if_wifi_service,
	round(avg(onboard_service),1) as if_entertainment
from
	aps a 
group by flight_class,satisfaction;

--After-Flight indexes:
select
    flight_class,
    satisfaction,
	round(avg(baggage_handling),1) as baggage_handling,
	round(avg(dep_and_arr_time_convenience),1) as dep_and_arr_timecon
from
	aps a 
group by flight_class,satisfaction;
--Flight-Class&Distance 

select
	case
		when flight_distance between 31 and 1000 then '0030-1000'
		when flight_distance between 1001 and 2000 then '1001-2000'
		when flight_distance between 2001 and 3000 then '2001-3000'
		when flight_distance between 3001 and 4000 then '3001-4000'
		when flight_distance between 4001 and 4983 then '4001-5000'
	end as distance_group,
	flight_class,
	round(avg(flight_distance),0) as avg_distance,
	count(*) as count
from
	aps a
group by distance_group,flight_class
order by 1 asc,4 desc;

--Flight class&Type of travel
select
	flight_class,type_of_travel,count(*) as nofcustomers
	from
	aps a 
group by flight_class,type_of_travel
order by 1,3 desc;

--Customer Consistency for Arrival&Departure Delay Index 
with rate_of_inconsistent_customers as
(select distinct (select
	count(*) as inconsistent_customers_count
from
	aps a
where
	departure_delay = 0
	and arrival_delay = 0
	and dep_and_arr_time_convenience != 5
	and dep_and_arr_time_convenience != 0) as inconsistent_customers_count,
(select
	count(*)
from
	aps
where
	dep_and_arr_time_convenience != 0) as total_cust_count_wo_irrelevant
from aps)
select inconsistent_customers_count::real/total_cust_count_wo_irrelevant*100 as ratio from rate_of_inconsistent_customers;
--There are 43008 customers who didn't face with any delay, but still they don't have fully satisfaction in terms of time convenience
--The inconsistent customers are approximately 35% of total customers without irrelevant ones
--Checking Average for all indexes
create view total_average as
(
select
    id,age,gender,type_of_travel,customer_type,flight_class,satisfaction,
    round((select avg(x) from unnest(array[dep_and_arr_time_convenience , ease_of_online_booking , checkin_service , online_boarding , gate_location , onboard_service , seat_comfort , leg_room_service , cleanliness , food_and_drink , inflight_service , inflight_wifi_service , inflight_entertainment , baggage_handling]) as x),2) as avg_satisfaction_score
from
   aps);
  
select count(*) from total_average where avg_satisfaction_score=5;
--There are 7 customers who rated all indexes as 5
select case
		when age between 7 and 20 then 'age 07-18'
		when age between 21 and 30 then 'age 19-30'
		when age between 31 and 40  then 'age 31-40'
		when age between 41 and 50 then 'age 41-50'
		when age between 51 and 60 then 'age 51-60'
		else 'age 60+'
		end	as age_bins	, count(age) as nofcustomers, min(avg_satisfaction_score),max(avg_satisfaction_score)
from total_average ta 
group by age_bins
order by 2 desc ;
select flight_class, count(flight_class) as nofcustomers, min(avg_satisfaction_score),max(avg_satisfaction_score)
from total_average ta
group by flight_class;

