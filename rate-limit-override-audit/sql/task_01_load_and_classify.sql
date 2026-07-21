-- Task 01: Load elevated accounts and classify by concern level
-- Cross-references with HVAPI and plan tier from DIM_INSTANCE_PRODUCTS

-- Load raw elevated accounts
CREATE TABLE raw_elevated AS
SELECT *
FROM read_csv_auto('data/elevated_accounts.csv', header=true);

-- Load product features (HVAPI addon + support plan tier)
CREATE TABLE raw_products AS
SELECT *
FROM read_csv_auto('data/product_features.csv', header=true);

-- Load sandbox flags
CREATE TABLE raw_sandboxes AS
SELECT *
FROM read_csv_auto('data/sandbox_accounts.csv', header=true);

-- Pivot to one row per account with HVAPI flag and plan tier
CREATE TABLE account_features AS
SELECT
    INSTANCE_ACCOUNT_ID,
    MAX(CASE WHEN PRODUCT_NAME = 'high_volume_api' THEN 1 ELSE 0 END) AS has_hvapi,
    MAX(CASE WHEN PRODUCT_NAME = 'support' THEN PLAN_TYPE_NAME ELSE NULL END) AS support_plan
FROM raw_products
GROUP BY INSTANCE_ACCOUNT_ID;

-- Join and classify
CREATE TABLE classified_accounts AS
SELECT
    e.INSTANCE_ACCOUNT_ID,
    e.INSTANCE_ACCOUNT_SUBDOMAIN,
    e.INSTANCE_ACCOUNT_POD_ID,
    e.SUBSCRIPTION_RATE_LIMIT,
    e.TICKETS_UPDATE_LIMIT,
    e.PER_TICKET_UPDATES_LIMIT,
    e.INFLIGHT_JOBS_LIMIT,
    e.INCREMENTAL_EXPORTS_LIMIT,
    e.SUBSCRIPTION_RATE_USED,
    e.TICKETS_UPDATE_USED,
    e.ERRORS_429_COUNT,
    COALESCE(f.has_hvapi, 0) AS has_hvapi,
    COALESCE(f.support_plan, 'Unknown') AS support_plan,
    CASE WHEN s.INSTANCE_ACCOUNT_ID IS NOT NULL THEN 1 ELSE 0 END AS is_sandbox,
    CASE
        WHEN f.has_hvapi = 1 THEN 'Enterprise (HVAPI)'
        WHEN f.support_plan = 'Enterprise' THEN 'Enterprise (no HVAPI)'
        WHEN f.support_plan = 'Professional' THEN 'Professional'
        WHEN f.support_plan = 'Team' THEN 'Team'
        ELSE COALESCE(f.support_plan, 'Unknown')
    END AS plan_tier,
    -- Concern level classification
    CASE
        -- HIGH: above HVAPI standard on any dimension
        WHEN e.SUBSCRIPTION_RATE_LIMIT > 2500
          OR e.TICKETS_UPDATE_LIMIT > 300
          OR e.PER_TICKET_UPDATES_LIMIT > 30
          OR e.INFLIGHT_JOBS_LIMIT > 30
          OR e.INCREMENTAL_EXPORTS_LIMIT > 30
          THEN 'HIGH'
        -- MEDIUM: at HVAPI level (2500 global or 300 threshold) but without HVAPI addon
        WHEN (e.SUBSCRIPTION_RATE_LIMIT = 2500 OR e.TICKETS_UPDATE_LIMIT = 300)
          AND COALESCE(f.has_hvapi, 0) = 0
          THEN 'MEDIUM'
        -- NORMAL: elevated but within plan entitlement
        ELSE 'NORMAL'
    END AS concern_level
FROM raw_elevated e
LEFT JOIN account_features f ON e.INSTANCE_ACCOUNT_ID = f.INSTANCE_ACCOUNT_ID
LEFT JOIN raw_sandboxes s ON e.INSTANCE_ACCOUNT_ID = s.INSTANCE_ACCOUNT_ID;

-- Summary by concern level and plan tier (non-sandbox)
CREATE TABLE agg_concern_summary AS
SELECT
    concern_level,
    plan_tier,
    COUNT(*) AS num_accounts,
    MAX(SUBSCRIPTION_RATE_LIMIT) AS max_global_api,
    MAX(TICKETS_UPDATE_LIMIT) AS max_ticket_threshold,
    MAX(PER_TICKET_UPDATES_LIMIT) AS max_per_ticket,
    MAX(INFLIGHT_JOBS_LIMIT) AS max_bulk_jobs,
    MAX(INCREMENTAL_EXPORTS_LIMIT) AS max_incremental
FROM classified_accounts
WHERE is_sandbox = 0
GROUP BY concern_level, plan_tier
ORDER BY
    CASE concern_level WHEN 'HIGH' THEN 1 WHEN 'MEDIUM' THEN 2 ELSE 3 END,
    num_accounts DESC;

-- Export HIGH concern accounts (non-sandbox only)
COPY (
    SELECT *
    FROM classified_accounts
    WHERE concern_level = 'HIGH' AND is_sandbox = 0
    ORDER BY SUBSCRIPTION_RATE_LIMIT DESC NULLS LAST,
             TICKETS_UPDATE_LIMIT DESC NULLS LAST
) TO 'data/high_concern.csv' (HEADER, DELIMITER ',');

-- Export MEDIUM concern accounts (non-sandbox only)
COPY (
    SELECT *
    FROM classified_accounts
    WHERE concern_level = 'MEDIUM' AND is_sandbox = 0
    ORDER BY SUBSCRIPTION_RATE_LIMIT DESC NULLS LAST,
             TICKETS_UPDATE_LIMIT DESC NULLS LAST
) TO 'data/medium_concern.csv' (HEADER, DELIMITER ',');

-- Export summary
COPY agg_concern_summary TO 'data/agg_concern_summary.csv' (HEADER, DELIMITER ',');

-- Export sandbox accounts separately
COPY (
    SELECT *
    FROM classified_accounts
    WHERE is_sandbox = 1
    ORDER BY
        CASE concern_level WHEN 'HIGH' THEN 1 WHEN 'MEDIUM' THEN 2 ELSE 3 END,
        SUBSCRIPTION_RATE_LIMIT DESC NULLS LAST
) TO 'data/sandbox_elevated.csv' (HEADER, DELIMITER ',');

-- Export all classified (non-sandbox) for the report
COPY (
    SELECT *
    FROM classified_accounts
    WHERE is_sandbox = 0
    ORDER BY
        CASE concern_level WHEN 'HIGH' THEN 1 WHEN 'MEDIUM' THEN 2 ELSE 3 END,
        SUBSCRIPTION_RATE_LIMIT DESC NULLS LAST
) TO 'data/agg_all_classified.csv' (HEADER, DELIMITER ',');
