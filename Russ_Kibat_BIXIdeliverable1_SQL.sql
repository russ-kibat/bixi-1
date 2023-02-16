-- Question 1 --
/* First, we will attempt to gain an overall view of the volume of usage of Bixi Bikes and what factors influence it.
    [1]The total number of trips for the year of 2016.
    [2]The total number of trips for the year of 2017.
    [3]The total number of trips for the year of 2016 broken-down by month.
    [4]The total number of trips for the year of 2017 broken-down by month.
    [5]The average number of trips a day for each year-month combination in the dataset.
    [6]Save your query results from the previous question (Q1.5) by creating a table called working_table1.*/

-- 1.1 and 1.2 --
# Count the number of trips per year
SELECT 
    YEAR(start_date) AS Year, COUNT(*) AS Num_Trips
FROM
    trips
GROUP BY Year;

-- 1.3 and 1.4 --
# extract the year/month for each trip and count the number of trips per year/month

SELECT 
    EXTRACT(YEAR_MONTH FROM start_date) AS ym,
    COUNT(start_date) AS Num_Trips
FROM
    trips
GROUP BY ym
ORDER BY ym;

-- 1.5 --
# build of the last query by also extrating the day for each trip. Count the number of trips per day and then average them from each year/month

SELECT 
    ym, AVG(daily_trips) AS AVG_daily_trips
FROM
    (SELECT 
        EXTRACT(YEAR_MONTH FROM start_date) AS ym,
            DAYOFMONTH(start_date) AS Day,
            COUNT(*) AS Daily_trips
    FROM
        trips
    GROUP BY ym , Day) AS Daily
GROUP BY ym;

-- 1.6 --
# create a table based on the previous query

CREATE TABLE working_table1 AS SELECT ym, ROUND(AVG(daily_trips), 0) AS AVG_daily_trips FROM
    (SELECT 
        EXTRACT(YEAR_MONTH FROM start_date) AS ym,
            DAYOFMONTH(start_date) AS Day,
            COUNT(*) AS Daily_trips
    FROM
        trips
    GROUP BY ym , Day) AS Daily
GROUP BY ym;

# verify table creation
SELECT 
    *
FROM
    working_table1;

-- Question 2 --
/*Unsurprisingly, the number of trips varies greatly throughout the year. How about membership status? Should we expect member and non-member to behave differently? To start investigating that, calculate:
The total number of trips in the year 2017 broken-down by membership status (member/non-member).
The fraction of total trips that were done by members for the year of 2017 broken-down by month*/

-- 2.1 --
# assign member or non-member to each trip and then count the number of member/non-member tips for 2017

SELECT 
    CASE
        WHEN is_member = 1 THEN 'MEMBER'
        ELSE 'NON-MEMBER'
    END AS M_status,
    COUNT(start_date) AS Num_Trips
FROM
    trips
WHERE
    start_date LIKE '2017%'
GROUP BY M_status
;

-- 2.2 -- 
# Subquery 'breakdown' creates a table Member and non member rides for each month. This is queried to add the column showing the percentage of rides for members and non members for the month.

SELECT 
Month,
M_status,
trip_num,
trip_num / (sum(trip_num) over (partition by Month)) as '%_rides'
from  
   (SELECT  
		MONTH(start_date) AS Month,
		CASE
			WHEN is_member = 1 THEN 'MEMBER'
			ELSE 'NON-MEMBER'
		END AS M_status,
		COUNT(*) As trip_num
		FROM
			trips
		WHERE start_date LIKE '2017%' 
		GROUP BY Month, m_status
		ORDER BY Month) as Breakdown
;

-- Question 4 --
/*It is clear now that average temperature and membership status are intertwined and influence greatly how people use Bixi bikes. Let’s try to bring this knowledge with us and learn something about station popularity.
    What are the names of the 5 most popular starting stations? Solve this problem without using a subquery.
    Solve the same question as Q4.1, but now use a subquery. Is there a difference in query run time between 4.1 and 4.2?*/
-- 4.1 --
# join the station table to the trip table and then count the number of trips per station then limit to the top 5

SELECT 
    stations.name AS start_station, COUNT(*) AS tripnum
FROM
    trips
        INNER JOIN
    stations ON trips.start_station_code = stations.code
GROUP BY start_station
ORDER BY tripnum DESC
LIMIT 5;


-- 4.2 --
# first query the trip table to determine the top of stations by station ID. Limit to 5. Then join that output to the station table.

SELECT 
    stations.name, tripnum
FROM
    (SELECT 
        start_station_code, COUNT(*) AS tripnum
    FROM
        trips
    GROUP BY start_station_code
    ORDER BY TRIPNUM DESC
    LIMIT 5) AS SUBQ
        JOIN
    stations ON SUBQ.start_station_code = STATIONS.CODE;


-- Question 5 --
/* If we break-up the hours of the day as follows:
SELECT CASE
       WHEN HOUR(start_date) BETWEEN 7 AND 11 THEN "morning"
       WHEN HOUR(start_date) BETWEEN 12 AND 16 THEN "afternoon"
       WHEN HOUR(start_date) BETWEEN 17 AND 21 THEN "evening"
       ELSE "night"
       END AS "time_of_day",
       ...
    How is the number of starts and ends distributed for the station Mackay / de Maisonneuve throughout the day?
    Explain the differences you see and discuss why the numbers are the way they are.*/

# find that station code for Mackay / de Maisonneuve

SELECT 
    *
FROM
    stations
WHERE
    name LIKE '%Mackay%';
    
-- 5.1 -- 
# assign a day part to each trip based on when the trip starts. Then count the number of trips that started in each day part. Join that result to the number of trips that ended in each day part.

SELECT 
    s.time_of_day, s.starts, e.ends
FROM
    (SELECT 
        COUNT(*) AS 'Starts',
            CASE
                WHEN HOUR(start_date) BETWEEN 7 AND 11 THEN 'morning'
                WHEN HOUR(start_date) BETWEEN 12 AND 16 THEN 'afternoon'
                WHEN HOUR(start_date) BETWEEN 17 AND 21 THEN 'evening'
                ELSE 'night'
            END AS 'time_of_day'
    FROM
        trips
    WHERE
        start_station_code = 6100
    GROUP BY time_of_day) AS S
        JOIN
    (SELECT 
        COUNT(*) AS 'ENDS',
            CASE
                WHEN HOUR(start_date) BETWEEN 7 AND 11 THEN 'morning'
                WHEN HOUR(start_date) BETWEEN 12 AND 16 THEN 'afternoon'
                WHEN HOUR(start_date) BETWEEN 17 AND 21 THEN 'evening'
                ELSE 'night'
            END AS 'time_of_day'
    FROM
        trips
    WHERE
        end_station_code = 6100
    GROUP BY time_of_day) AS E ON s.time_of_day = e.time_of_day;
    

 
-- Question 6 --  
/*List all stations for which at least 10% of trips are round trips. Round trips are those that start and end in the same station. This time we will only consider stations with at least 500 starting trips. (Please include answers for all steps outlined here)
	First, write a query that counts the number of starting trips per station.
    Second, write a query that counts, for each station, the number of round trips.
    Combine the above queries and calculate the fraction of round trips to the total number of starting trips for each station.
    Filter down to stations with at least 500 trips originating from them and having at least 10% of their trips as round trips.
    Where would you expect to find stations with a high fraction of round trips?*/

-- 6.1 -- 
# count the number of trips per station

SELECT 
    Start_station_Code, COUNT(*) AS trip_num
FROM
    trips
GROUP BY start_station_code;


# Create a table based on 6.1

CREATE TABLE station_trip_count (
    start_station_code INT,
    trip_num INT
) SELECT start_station_code, COUNT(*) AS trip_num FROM
    trips
GROUP BY start_station_code;

# verify table creation

SELECT 
    *
FROM
    station_trip_count;


-- 6.2 -- 
# identify and cound the number of round trips

SELECT 
    start_station_code, COUNT(*) AS num_roundtrip
FROM
    trips
WHERE
    start_station_code = end_station_code
GROUP BY start_station_code;

# create a table from 6.2

CREATE TABLE roundtrip_count (
    start_station_code INT,
    num_roundtrip INT
) SELECT start_station_code, COUNT(*) AS num_roundtrip FROM
    trips
WHERE
    start_station_code = end_station_code
GROUP BY start_station_code;

# verify table creation

SELECT 
    *
FROM
    roundtrip_count;

    
-- 6.3 -- 
# join the queries from 6.1 and 6.2 

SELECT 
    t.start_station_code,
    T.trip_num,
    R.num_roundtrip,
    R.num_roundtrip / T.trip_num AS fraction
FROM
    (SELECT 
        start_station_code, COUNT(*) AS num_roundtrip
    FROM
        trips
    WHERE
        start_station_code = end_station_code
    GROUP BY start_station_code) AS R
        INNER JOIN
    (SELECT 
        start_station_code, COUNT(*) AS trip_num
    FROM
        trips
    GROUP BY start_station_code) AS T ON T.start_station_code = R.start_station_code;

# recreate the result of 6.3 using the previously created tables

SELECT 
    s.*,
    r.num_roundtrip,
    r.num_roundtrip / s.trip_num AS fraction_roundtrip
FROM
    station_trip_count AS S
        LEFT JOIN
    roundtrip_count AS R ON S.start_Station_code = R.start_station_code;

-- 6.4 --
# rerun the query from 6.3 adding filters 

SELECT 
    t.start_station_code,
    t.trips_num,
    R.roundtrip,
    R.roundtrip / T.trips_num AS FR
FROM
    (SELECT 
        start_station_code, COUNT(*) AS roundtrip
    FROM
        trips
    WHERE
        start_station_code = end_station_code
    GROUP BY start_station_code) AS R
        INNER JOIN
    (SELECT 
        start_station_code, COUNT(*) AS trips_num
    FROM
        trips
    GROUP BY start_station_code
    HAVING trips_num > 500) AS T 
    ON T.start_station_code = R.start_station_code
WHERE
    R.roundtrip / T.trips_num >= 0.1;

# recreate 6.4 using tables from 6.1 and 6.2. Join information from the stations table to add names on coodrinates. 

SELECT 
    s.start_station_code,
    stations.name,
    stations.latitude,
    stations.longitude,
    s.trip_num,
    r.num_roundtrip,
    r.num_roundtrip / s.trip_num AS fraction_roundtrip
FROM
    station_trip_count AS S
        LEFT JOIN
    roundtrip_count AS R ON S.start_Station_code = R.start_station_code
        LEFT JOIN
    stations ON S.start_station_code = stations.code
WHERE
    s.trip_num > 500
        AND r.num_roundtrip / s.trip_num > 0.1
ORDER BY Fraction_roundtrip DESC;
    