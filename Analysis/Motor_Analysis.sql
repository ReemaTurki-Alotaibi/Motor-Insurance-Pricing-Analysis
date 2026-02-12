-- =========================================
-- Data Cleaning + Feature Engineering + Analysis
-- =========================================

-- Pre-setting: Ensure date format matches the CSV (Month/Day/Year)
SET datestyle = 'ISO, MDY';

-- Drop the table if it already exists
DROP TABLE IF EXISTS motor_insurance_raw;

-- Create the table structure 
CREATE TABLE motor_insurance_raw (
    customer VARCHAR(20) PRIMARY KEY, -- Primary Key for indexing
    state VARCHAR(50),
    customer_lifetime_value NUMERIC,
    response VARCHAR(10),
    coverage VARCHAR(20),
    coverage_index INT,
    education VARCHAR(50),
    education_index INT,
    effective_to_date DATE,
    employment_status VARCHAR(30),
    employment_status_index INT,
    gender CHAR(1),
    income NUMERIC,
    location VARCHAR(30),
    location_index INT,
    marital_status VARCHAR(20),
    marital_status_index INT,
    monthly_premium_auto NUMERIC,
    months_since_last_claim INT,
    months_since_policy_inception INT,
    number_of_open_complaints INT,
    number_of_policies INT,
    policy_type VARCHAR(50),
    policy_type_index INT,
    policy VARCHAR(50),
    policy_index INT,
    renew_offer_type INT,
    sales_channel VARCHAR(30),
    sales_channel_index INT,
    total_claim_amount NUMERIC,
    vehicle_class VARCHAR(30),
    vehicle_class_index INT,
    vehicle_size VARCHAR(30),
    vehicle_size_index INT
);

-- [Manual Import Step: Import AutoInsuranceClaims2024.csv here]

-- Verification
SELECT COUNT(*) AS total_rows FROM motor_insurance_raw;

-- Display sample of data
SELECT customer, state, customer_lifetime_value, effective_to_date 
FROM motor_insurance_raw 
LIMIT 10;

-- Check for missing values
SELECT 
    COUNT(*) AS total_rows,
    SUM(CASE WHEN customer IS NULL THEN 1 ELSE 0 END) AS missing_customer,
    SUM(CASE WHEN total_claim_amount IS NULL THEN 1 ELSE 0 END) AS missing_claim,
    SUM(CASE WHEN state IS NULL THEN 1 ELSE 0 END) AS missing_state,
    SUM(CASE WHEN gender IS NULL THEN 1 ELSE 0 END) AS missing_gender
FROM motor_insurance_raw;

-- Feature Engineering

-- : Annual Premium
ALTER TABLE motor_insurance_raw ADD COLUMN annual_premium NUMERIC;
UPDATE motor_insurance_raw SET annual_premium = monthly_premium_auto * 12;

-- : Has Claim
ALTER TABLE motor_insurance_raw ADD COLUMN has_claim INT;
UPDATE motor_insurance_raw SET has_claim = CASE WHEN total_claim_amount > 0 THEN 1 ELSE 0 END;

-- : Income Band
ALTER TABLE motor_insurance_raw ADD COLUMN income_band VARCHAR(15);
UPDATE motor_insurance_raw SET income_band = CASE
    WHEN income <= 0 THEN 'No Income'
    WHEN income <= 30000 THEN 'Low'
    WHEN income <= 70000 THEN 'Medium'
    ELSE 'High'
END;

-- Advanced Analysis

-- : Overall Loss Ratio (using NULLIF to prevent division by zero)
SELECT SUM(total_claim_amount) / NULLIF(SUM(annual_premium), 0) AS overall_loss_ratio
FROM motor_insurance_raw;

-- : Loss Ratio by Coverage
SELECT coverage, 
       ROUND(SUM(total_claim_amount) / NULLIF(SUM(annual_premium), 0), 4) AS loss_ratio
FROM motor_insurance_raw
GROUP BY coverage
ORDER BY loss_ratio DESC;

-- : Average claim and policy count by Vehicle Class
SELECT vehicle_class, 
       ROUND(AVG(total_claim_amount), 2) AS avg_claim, 
       COUNT(*) AS policies_count
FROM motor_insurance_raw
GROUP BY vehicle_class
ORDER BY avg_claim DESC;

-- : Loss Ratio by Vehicle Class + Coverage
SELECT vehicle_class, coverage, 
       ROUND(SUM(total_claim_amount)/NULLIF(SUM(annual_premium),0),4) AS loss_ratio
FROM motor_insurance_raw
GROUP BY vehicle_class, coverage
ORDER BY loss_ratio DESC;

-- : Average annual premium and claim by Employment Status
SELECT employment_status, 
       ROUND(AVG(monthly_premium_auto * 12),2) AS avg_annual_premium,
       ROUND(AVG(total_claim_amount),2) AS avg_claim
FROM motor_insurance_raw
GROUP BY employment_status
ORDER BY avg_claim DESC;

-- : Number of policies effective by month (formatted)
SELECT TO_CHAR(effective_to_date, 'YYYY-MM') AS policy_month, 
       COUNT(*) AS policy_count
FROM motor_insurance_raw
GROUP BY policy_month
ORDER BY policy_month;

-- =========================================
-- End of SQL Phase: ready for Python modeling
-- =========================================
