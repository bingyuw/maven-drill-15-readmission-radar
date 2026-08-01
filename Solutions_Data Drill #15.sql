CREATE DATABASE inpatient_admissions;
USE inpatient_admissions;

CREATE TABLE patient_records (
	admission_id VARCHAR(50) PRIMARY KEY,
    patient_id VARCHAR(50) NOT NULL,
    admission_date DATE NOT NULL,
    discharge_date DATE
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/15_inpatient_admissions.csv'
INTO TABLE patient_records 
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

-- Confirm the total number of rows
SELECT COUNT(*) FROM patient_records; 

-- Data Quality Check: Identify any records with missing dates
-- If any rows are returned, those records may need to be investigated
-- or excluded from the analysis.
SELECT admission_id, admission_date, discharge_date 
FROM patient_records
WHERE admission_date IS NULL OR discharge_date IS NULL;

-- Solution: Self-Join
-- Join the table with itself to find the corresponding 
-- readmission date for each discharge date.
--
-- Two conditions need to be met when joining:
-- 		1. admission date needs to be later than the discharge date
-- 		2. admission date needs to be within the 30-day period of the discharge date
--
-- Selection of result: Only the earliest admission date immediately 
-- following the discharge date will be counted as the readmission.

WITH cte AS (
	SELECT pr1.patient_id, 
    pr1.discharge_date AS index_discharge,
	MIN(pr2.admission_date) AS readmission_date 
	FROM patient_records pr1
	LEFT JOIN patient_records pr2
		ON pr1.patient_id = pr2.patient_id 
		AND pr2.admission_date > pr1.discharge_date
		AND DATEDIFF(pr2.admission_date, pr1.discharge_date) <= 30
	GROUP BY pr1.patient_id, pr1.discharge_date)
SELECT ROUND(COUNT(readmission_date)/COUNT(*)*100,0) AS thirty_day_readmission_rate 
FROM cte;  
