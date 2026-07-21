-- Task 01: Load and standardize customer rate limit data
-- Loads raw CSVs from data/ and creates clean tables

CREATE TABLE raw_rate_limits AS
SELECT *
FROM read_csv_auto('data/rate_limited_customers.csv', header=true);

-- Summary by tickets_update_limit tier
CREATE TABLE agg_summary AS
SELECT
    CASE
        WHEN tickets_update_limit < 1000 THEN '< 1,000'
        WHEN tickets_update_limit < 2000 THEN '1,000 - 1,999'
        WHEN tickets_update_limit < 3000 THEN '2,000 - 2,999'
        WHEN tickets_update_limit < 4000 THEN '3,000 - 3,999'
        ELSE '4,000 - 4,999'
    END AS category,
    COUNT(*) AS count,
    SUM(errors_429_count) AS total_429_errors,
    ROUND(AVG(tickets_update_used), 0) AS avg_tickets_used
FROM raw_rate_limits
GROUP BY category
ORDER BY count DESC;

-- Export aggregated data for the report
COPY agg_summary TO 'data/agg_summary.csv' (HEADER, DELIMITER ',');

-- Export full detail for download (lowercase columns for OJS compatibility)
COPY (
  SELECT
    INSTANCE_ACCOUNT_ID AS instance_account_id,
    INSTANCE_ACCOUNT_NAME AS instance_account_name,
    CREATED_TIMESTAMP AS created_timestamp,
    TICKETS_UPDATE_LIMIT AS tickets_update_limit,
    TICKETS_UPDATE_USED AS tickets_update_used,
    ERRORS_429_COUNT AS errors_429_count
  FROM raw_rate_limits
  ORDER BY ERRORS_429_COUNT DESC
) TO 'data/agg_detail.csv' (HEADER, DELIMITER ',');
