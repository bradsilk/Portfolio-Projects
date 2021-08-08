USE neiss;
SET SQL_SAFE_UPDATES = 0;

-- 1.) Create table for 2020 NEISS Data Highlights:

CREATE TABLE highlights (
	product_group VARCHAR(255), 
    est_injuries INTEGER,
	all_ages INTEGER, 
    `0-4` INTEGER, 
    `5-14` INTEGER, 
    `15-24` INTEGER,
    `25-64` INTEGER,
    `65+` INTEGER,
    male INTEGER,
    female INTEGER,
    treated_and_rel INTEGER,
    hosp_and_doa INTEGER
    );
	
    -- Data inserted from CSV using Table Data Import Wizard; no errors
   
   
-- 2.) Create table for 2020 NEISS Incident Data:

CREATE TABLE incidents (
	case_number SERIAL PRIMARY KEY, 
    treatment_date VARCHAR(255),
    age INTEGER,
    sex INTEGER, 
    race INTEGER,
    body_part INTEGER,
    diagnosis INTEGER,
    disposition INTEGER,
    location INTEGER,
    fire_involvement INTEGER,
    product_1 INTEGER,
    alcohol INTEGER,
    drug INTEGER
    );
    
    -- Data inserted from CSV using Table Data Import Wizard; no errors
    
-- 3.) incidents table data cleaning and definition table creation:

# a.) Correct treatment_date format and convert to 'DATE' data type


ALTER TABLE incidents ADD (new_col DATE);

UPDATE incidents SET new_col = STR_TO_DATE(treatment_date,'%m/%d/%Y');

ALTER TABLE incidents DROP COLUMN treatment_date;

ALTER TABLE incidents RENAME COLUMN new_col TO treatment_date;

ALTER TABLE incidents 
CHANGE COLUMN treatment_date treatment_date DATE NULL DEFAULT NULL AFTER case_number;



/*  b.) According to the 2020 NEISS Coding Manual: "For children under two years old, record the age in completed months 
(e.g., code the age of infants who are four to seven weeks old as one month). To show that the age is in months instead of years, 
put a "2" in the first space of the age code. Code the age of infants who are less than one month old as one month (“201”). (Page 9)" 
 
	Alter ages to reflect the true age of those under two in years (round to two decimals): */
    

CREATE TABLE incidents2 AS
SELECT 
	i1.*,
	CASE 
		WHEN LENGTH(i1.age) = 3 AND LEFT(i1.age, 1) = 2 THEN (SELECT ROUND((RIGHT(i1.age, 2)/12),2) FROM incidents WHERE LENGTH(i1.age) = 3 AND LEFT(i1.age, 1) = 2 LIMIT 1)
        ELSE i1.age 
END AS age_altered
FROM incidents i1
JOIN incidents i2 
	ON i1.case_number = i2.case_number;

ALTER TABLE incidents2 
CHANGE COLUMN age_altered age_altered DOUBLE(10,2) NULL DEFAULT NULL AFTER age;

ALTER TABLE incidents
RENAME TO  incidents_dep;

ALTER TABLE incidents2 
RENAME TO incidents;

DROP TABLE incidents_dep;


# c.) Sex - Substitute 'M' for 1,'F' for 2, and 'NR' for 0 (Page 10):

ALTER TABLE incidents 
MODIFY sex VARCHAR(255);

UPDATE incidents 
SET sex =
    CASE 
		WHEN sex = 1 THEN 'M'
        WHEN sex = 2 THEN 'F'
        ELSE 'NR' 
	END;


/* d.) Race - Substitute 'White' for 1, 'Black' for 2, 'Other' for 3, 'Asian' for 4, 'AI/AN' (American Indian/Alaska Native) for 5, 
'NH/PI' (Native Hawaiian/Pacific Islander) for 6, and 'NS' (Not stated) for 0 (Page 11):  */

ALTER TABLE incidents 
MODIFY race VARCHAR(255);

UPDATE incidents 
SET race =
    CASE 
		WHEN race = 1 THEN 'White'
        WHEN race = 2 THEN 'Black'
        WHEN race = 3 THEN 'Other'
        WHEN race = 4 THEN 'Asian'
        WHEN race = 5 THEN 'AI/AN'
        WHEN race = 6 THEN 'NH/PI'
        WHEN race = 0 THEN 'NS' 
	END;



# e.) Body part affected (using first recorded only) - make new table (Page 20)

CREATE TABLE body_parts (
    code INTEGER PRIMARY KEY,
    body_part_affected TEXT
    );

    -- Data inserted from CSV using Table Data Import Wizard; no errors

SELECT 
	case_number,
    age,
    body_part,
    body_part_affected
FROM incidents
JOIN body_parts ON incidents.body_part = body_parts.code;
	

# f.) Diagnosis - make new table (Page 12)

CREATE TABLE diagnoses (
	code INTEGER PRIMARY KEY,
	diagnosis TEXT
    );

    -- Data inserted from CSV using Table Data Import Wizard; no errors

SELECT 
	case_number,
    age,
    incidents.diagnosis,
    diagnoses.diagnosis
FROM incidents
JOIN diagnoses ON incidents.diagnosis = diagnoses.code;


/* g.) Disposition - Substitute 'Treated or examined and released' for 1, 'Treated and transferred' (to another hospital) for 2,
'Treated and admitted for hospitalization' for 4, 'Held for observation' for 5, 'Left without being seen/against advice' for 6,
'Fatality or DOA' for 8', 'NR' (Not recorded) for 9 (Page 23): */

ALTER TABLE incidents 
MODIFY disposition VARCHAR(255);

UPDATE incidents 
SET disposition =
    CASE 
		WHEN disposition = 1 THEN 'Treated or examined and released'
        WHEN disposition = 2 THEN 'Treated and transferred'
        WHEN disposition = 4 THEN 'Treated and admitted for hospitalization'
        WHEN disposition = 5 THEN 'Held for observation'
        WHEN disposition = 6 THEN 'Left without being seen/against advice'
        WHEN disposition = 8 THEN 'Fatality or DOA' 
		WHEN disposition = 9 THEN 'NR'
	END;



# h.) Location - make new table (Page 34)

CREATE TABLE inc_location (
	code INTEGER PRIMARY KEY,
	location TEXT
    );

    # Data inserted from CSV using Table Data Import Wizard; no errors

SELECT 
	case_number,
    age,
    inj_location.location,
    incidents.location
FROM incidents
JOIN inj_location ON incidents.location = inj_location.code;



/* i.) Fire involvement - Subsitute 'No fire' for 0, 'Fire or smoke inhalation, fire dept attended' for 1, 'Fire or smoke inhalation, fire dept did not attend' for 2,
'Fire or smoke inhalation, fire dept attendance not recorded' for 3 (Page 36): */

ALTER TABLE incidents 
MODIFY fire_involvement VARCHAR(255);

UPDATE incidents 
SET fire_involvement =
    CASE 
		WHEN fire_involvement = 0 THEN 'No fire'
        WHEN fire_involvement = 1 THEN 'Fire or smoke inhalation, fire dept attended'
		WHEN fire_involvement = 2 THEN 'Fire or smoke inhalation, fire dept did not attend'
        WHEN fire_involvement = 3 THEN 'Fire or smoke inhalation, fire dept attendance not recorded'
	END;

# j.)  Primary Product -- MAKE TABLE (2020 Comparability Table Pages 1 - 76):

CREATE TABLE product (
	code INTEGER PRIMARY KEY,
    PRODUCT TEXT
    );

   # Data inserted from CSV using Table Data Import Wizard; no errors

SELECT 
	case_number,
    age,
    products.product,
    incidents.product_1
FROM incidents
JOIN products ON incidents.product_1 = products.code;

# k.) Many products have a space character and the end of their name - Remove:

UPDATE products SET product = RTRIM(product)
WHERE RIGHT(product,1) = ' ';

-- 4.) Create VIEW with incidents table and definition tables:

CREATE VIEW v_incidents AS
SELECT 
	case_number,
    treatment_date,
    age_altered,
    sex,
    race,
    body_parts.body_part_affected,
    diagnoses.diagnosis,
    disposition,
    inj_location.location,
    fire_involvement,
    products.product,
    alcohol,
    drug
FROM incidents
JOIN body_parts
	ON incidents.body_part = body_parts.code
JOIN diagnoses
	ON incidents.diagnosis = diagnoses.code
JOIN inj_location 
	ON incidents.location = inj_location.code
JOIN products 
	ON incidents.product_1 = products.code;


-- 5.) Dealing with missing values

-- a.) Checking for missing values in the view:

SELECT * FROM v_incidents WHERE case_number IS NULL OR case_number = '';
SELECT * FROM v_incidents WHERE treatment_date IS NULL OR treatment_date = '';
SELECT * FROM v_incidents WHERE age_altered IS NULL OR age_altered = '';
	-- 28 rows with missing age detected (0.000095 % of all rows) - replace with mean or median age values depending on distribution shape
	-- Distribution visualized in Python; see NEISSAgeDistCheck.ipynb
SELECT * FROM v_incidents WHERE race IS NULL OR race = '';
SELECT * FROM v_incidents WHERE body_part IS NULL OR body_part = '';
SELECT * FROM v_incidents WHERE diagnosis IS NULL OR diagnosis = '';
SELECT * FROM v_incidents WHERE disposition IS NULL OR disposition = '';
SELECT * FROM v_incidents WHERE location IS NULL OR location = '';
	-- No missing values, however there are 104015 0's ("Unknown or not recorded"); keep as is and keep 0's in mind in analysis
SELECT * FROM v_incidents WHERE fire_involvement IS NULL OR fire_involvement = '';
SELECT * FROM v_incidents WHERE primary_product IS NULL OR primary_product = '';
SELECT * FROM v_incidents WHERE alcohol IS NULL OR alcohol = '' AND alcohol != 0;
SELECT * FROM v_incidents WHERE drug IS NULL OR drug = '' AND drug != 0;

-- b.) Filling in missing values for age - Since age_altered is not normally distributed (positively skewed), use the median value as a replacement:

UPDATE incidents SET age_altered = (
	-- MEDIAN FUNCTION*
	SELECT AVG(dd.age_altered) as median_val
	FROM (
	SELECT d.age_altered, @rownum:=@rownum+1 as `row_number`, @total_rows:=@rownum
	  FROM incidents d, (SELECT @rownum:=0) r
	  WHERE d.age_altered is NOT NULL
	  ORDER BY d.age_altered
	) as dd
	WHERE dd.row_number IN ( FLOOR((@total_rows+1)/2), FLOOR((@total_rows+2)/2) )
)
WHERE age_altered IS NULL;

	# *Credit: https://stackoverflow.com/questions/1291152/simple-way-to-calculate-median-with-mysql

-- 6.) Answering questions about the data:

# a.) Top 10 most common products listed:

SELECT 
	product,
    COUNT(product)
FROM v_incidents
GROUP BY product
ORDER BY COUNT(product) DESC
LIMIT 10;


# b.) Most common product injury by age

SELECT * FROM (
SELECT
	age_altered,
    product,
    COUNT(product),
    RANK() OVER (PARTITION BY age_altered ORDER BY COUNT(product) DESC) AS age_group_rank
FROM v_incidents
GROUP BY age_altered, product
ORDER BY age_altered, COUNT(product) DESC
) a 
WHERE age_group_rank = 1;


/* Quick analysis: Infants and children 1 month to 5 years old were most commonly injured by beds or bedframes.
Children from the age of 6-12 were most commonly injured by bicycles or accessories, and teens by basketball-related
incidents. Injuries related to stairs or steps were the most common category for adults aged 19 to 60, after which
floor-related injuries (likely falls) are the most numerous. */
	
# c.) Are firework injuries more common in July than other months?

SELECT 
	MID(treatment_date, 6,2) AS month,
    product,
    COUNT(product)
FROM v_incidents
WHERE product LIKE 'Firework%'
GROUP BY product, month
ORDER BY COUNT(product) DESC;
    
# Answer: yes; 278 fireworks related injuries occured in July, followed by 50 in June and 27 in January


# d.) Count of all knee injuries per month

SELECT 
	SUM(CASE WHEN MONTH(treatment_date) = 1 AND body_part_affected = 'Knee' THEN 1 ELSE 0 END) AS January,
    SUM(CASE WHEN MONTH(treatment_date) = 2 AND body_part_affected = 'Knee' THEN 1 ELSE 0 END) AS February,
    SUM(CASE WHEN MONTH(treatment_date) = 3 AND body_part_affected = 'Knee' THEN 1 ELSE 0 END) AS March,
    SUM(CASE WHEN MONTH(treatment_date) = 4 AND body_part_affected = 'Knee' THEN 1 ELSE 0 END) AS April,
    SUM(CASE WHEN MONTH(treatment_date) = 5 AND body_part_affected = 'Knee' THEN 1 ELSE 0 END) AS May,
    SUM(CASE WHEN MONTH(treatment_date) = 6 AND body_part_affected = 'Knee' THEN 1 ELSE 0 END) AS June,
    SUM(CASE WHEN MONTH(treatment_date) = 7 AND body_part_affected = 'Knee' THEN 1 ELSE 0 END) AS July,
    SUM(CASE WHEN MONTH(treatment_date) = 8 AND body_part_affected = 'Knee' THEN 1 ELSE 0 END) AS August,
    SUM(CASE WHEN MONTH(treatment_date) = 9 AND body_part_affected = 'Knee' THEN 1 ELSE 0 END) AS September,
	SUM(CASE WHEN MONTH(treatment_date) = 10 AND body_part_affected = 'Knee' THEN 1 ELSE 0 END) AS October,
	SUM(CASE WHEN MONTH(treatment_date) = 11 AND body_part_affected = 'Knee' THEN 1 ELSE 0 END) AS November,
    SUM(CASE WHEN MONTH(treatment_date) = 12 AND body_part_affected = 'Knee' THEN 1 ELSE 0 END) AS December,
    SUM(CASE WHEN body_part_affected = 'Knee' THEN 1 ELSE 0 END) AS Total
FROM v_incidents;


# e.) Running total of injuries over 2020

WITH injury_counts (treatment_date, injury_count) AS (
	SELECT 
		treatment_date,
		COUNT(treatment_date) AS injury_count
	FROM v_incidents
	GROUP BY treatment_date
	ORDER BY treatment_date)
SELECT 
	treatment_date,
    injury_count,
	SUM(injury_count) OVER (ORDER BY treatment_date) 
FROM injury_counts;


/* f.) Most common diagnosis resulting from an injury by 'Floors or flooring materials' in an incident involving alcohol, 
split by gender: */ 

SELECT 
	(SELECT 
		diagnosis 
	FROM v_incidents
	WHERE product = 'Floors or flooring materials' AND alcohol = 1 AND sex= 'M'
	GROUP BY diagnosis
	ORDER BY COUNT(diagnosis) DESC
	LIMIT 1) AS male,
	(SELECT 
		diagnosis 
	FROM v_incidents
	WHERE product = 'Floors or flooring materials' AND alcohol = 1 AND sex= 'F'
	GROUP BY diagnosis
	ORDER BY COUNT(diagnosis) DESC
	LIMIT 1) AS female
FROM v_incidents
GROUP BY male, female;

	#Internal organ injury is the most common diagnosis for both males and females in this case

# g.) Find the number of days that elapsed between the first and third bottle opener injuries:

SELECT 
	product,
	treatment_date,
    DAYOFYEAR(treatment_date),
	LEAD(DAYOFYEAR(treatment_date),2) OVER (ORDER BY DAYOFYEAR(treatment_date)) - DAYOFYEAR(treatment_date) AS days_elapsed
FROM v_incidents
WHERE product = 'Bottle openers'
ORDER BY treatment_date;

	# 172 days elapsed (2020-07-04 -> 2020-12-23)