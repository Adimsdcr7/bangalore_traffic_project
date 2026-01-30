CREATE DATABASE bangalore_traffic;
USE bangalore_traffic;

CREATE TABLE traffic_raw (
    traffic_date DATE,
    area_name VARCHAR(100),
    road_name VARCHAR(150),

    traffic_volume INT,
    average_speed FLOAT,
    travel_time_index FLOAT,
    congestion_level FLOAT,
    road_capacity_utilization FLOAT,

    incident_reports INT,
    environmental_impact FLOAT,

    public_transport_usage FLOAT,
    traffic_signal_compliance FLOAT,
    parking_usage FLOAT,

    pedestrian_cyclist_count INT,

    weather_conditions VARCHAR(50),
    roadwork_activity VARCHAR(10)
);

TRUNCATE traffic_raw;

SELECT COUNT(*) FROM traffic_raw;

CREATE VIEW traffic_clean AS
SELECT
    traffic_date,
    area_name,
    road_name,
    traffic_volume,
    average_speed,
    travel_time_index,
    congestion_level,
    road_capacity_utilization,
    incident_reports,
    environmental_impact,
    public_transport_usage,
    traffic_signal_compliance,
    parking_usage,
    pedestrian_cyclist_count,
    weather_conditions,
    roadwork_activity
FROM traffic_raw
WHERE traffic_date IS NOT NULL
  AND area_name IS NOT NULL
  AND road_name IS NOT NULL;
  
  -- Date coverage
SELECT
    MIN(traffic_date) AS start_date,
    MAX(traffic_date) AS end_date,
    COUNT(*) AS total_rows
FROM traffic_clean;

-- Areas covered
SELECT
    area_name,
    COUNT(*) AS records
FROM traffic_clean
GROUP BY area_name
ORDER BY records DESC;

-- Is high traffic volume always the reason for congestion?

SELECT
    area_name,
    ROUND(AVG(traffic_volume),2) AS avg_volume,
    ROUND(AVG(congestion_level),2) AS avg_congestion,
    ROUND(AVG(road_capacity_utilization),2) AS avg_capacity
FROM traffic_clean
GROUP BY area_name
ORDER BY avg_congestion DESC;


-- Are roads congested because they are full, or because incidents break flow?

SELECT
    area_name,
    ROUND(AVG(incident_reports),2) AS avg_incidents,
    ROUND(AVG(congestion_level),2) AS avg_congestion
FROM traffic_clean
GROUP BY area_name
ORDER BY avg_incidents DESC;

-- Does traffic signal compliance actually reduce congestion?

SELECT
    CASE 
        WHEN traffic_signal_compliance >= 80 THEN 'High Compliance'
        ELSE 'Low Compliance'
    END AS compliance_group,
    ROUND(AVG(congestion_level),2) AS avg_congestion,
    ROUND(AVG(average_speed),2) AS avg_speed
FROM traffic_clean
GROUP BY compliance_group;

-- Does parking usage worsen congestion more than traffic volume?

SELECT
    area_name,
    ROUND(AVG(parking_usage),2) AS avg_parking,
    ROUND(AVG(congestion_level),2) AS avg_congestion
FROM traffic_clean
GROUP BY area_name
ORDER BY avg_parking DESC;

-- Is public transport usage actually easing traffic?

SELECT
    area_name,
    ROUND(AVG(public_transport_usage),2) AS avg_pt_usage,
    ROUND(AVG(traffic_volume),2) AS avg_volume,
    ROUND(AVG(congestion_level),2) AS avg_congestion
FROM traffic_clean
GROUP BY area_name
ORDER BY avg_pt_usage DESC;


-- How much of congestion is uncontrollable (weather-driven)?

SELECT
    weather_conditions,
    ROUND(AVG(congestion_level),2) AS avg_congestion,
    ROUND(AVG(average_speed),2) AS avg_speed
FROM traffic_clean
GROUP BY weather_conditions
ORDER BY avg_congestion DESC;

-- Which roads are consistently failing, regardless of conditions?

SELECT
    area_name,
    road_name,
    COUNT(*) AS observations,
    ROUND(AVG(congestion_level),2) AS avg_congestion,
    ROUND(AVG(road_capacity_utilization),2) AS avg_capacity
FROM traffic_clean
GROUP BY area_name, road_name
HAVING avg_congestion > 80
ORDER BY avg_congestion DESC;

-- Congestion variability (stability vs volatility)

SELECT
  road_name,
  ROUND(AVG(congestion_level),2) AS avg_congestion,
  ROUND(STDDEV(congestion_level),2) AS congestion_volatility
FROM traffic_clean
GROUP BY road_name
ORDER BY avg_congestion DESC;

-- Are certain roads “always bad” compared to others in the same area?

SELECT
  area_name,
  road_name,
  ROUND(AVG(congestion_level),2) AS avg_congestion,
  ROUND(AVG(traffic_volume),2) AS avg_volume,
  ROUND(AVG(road_capacity_utilization),2) AS avg_capacity
FROM traffic_clean
GROUP BY area_name, road_name
HAVING avg_congestion > 85
ORDER BY avg_congestion DESC;

-- Are some roads congested even when they are NOT near full capacity?

-- Congestion inevitability (can policy even fix this?)
SELECT
  road_name,
  ROUND(AVG(congestion_level),2) AS avg_congestion,
  ROUND(STDDEV(congestion_level),2) AS volatility
FROM traffic_clean
GROUP BY road_name
ORDER BY avg_congestion DESC;

-- Area inequality (investment prioritization)

SELECT
  area_name,
  ROUND(AVG(congestion_level),2) AS avg_congestion,
  ROUND(AVG(road_capacity_utilization),2) AS avg_capacity
FROM traffic_clean
GROUP BY area_name
ORDER BY avg_congestion DESC;

-- Which roads are the worst within each area?

SELECT *
FROM (
    SELECT
        area_name,
        road_name,
        ROUND(AVG(congestion_level),2) AS avg_congestion,
        ROW_NUMBER() OVER (
            PARTITION BY area_name
            ORDER BY AVG(congestion_level) DESC
        ) AS rn
    FROM traffic_clean
    GROUP BY area_name, road_name
) ranked
WHERE rn = 1;

-- Which roads are consistently bad vs occasionally bad?

SELECT
    road_name,
    ROUND(AVG(congestion_level),2) AS avg_congestion,
    ROUND(STDDEV(congestion_level),2) AS volatility,
    RANK() OVER (
        ORDER BY AVG(congestion_level) DESC
    ) AS congestion_rank
FROM traffic_clean
GROUP BY road_name;


-- Which areas are above or below city average congestion?

SELECT
    area_name,
    ROUND(AVG(congestion_level),2) AS avg_congestion,
    ROUND(
        AVG(congestion_level)
        - AVG(AVG(congestion_level)) OVER (),
    2) AS deviation_from_city_avg,
    DENSE_RANK() OVER (
        ORDER BY AVG(congestion_level) DESC
    ) AS city_rank
FROM traffic_clean
GROUP BY area_name;
