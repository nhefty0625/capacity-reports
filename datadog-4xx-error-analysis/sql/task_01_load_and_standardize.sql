-- Task 01: Load and standardize Datadog 4XX error data
-- Loads CSV files produced by fetch_data.sh (via pup + jq)

-- Status code breakdowns
CREATE TABLE status_codes AS
SELECT * FROM read_csv_auto('data/*_status_codes.csv');

-- URL breakdowns
CREATE TABLE urls AS
SELECT * FROM read_csv_auto('data/*_urls.csv');

-- Method breakdowns
CREATE TABLE methods AS
SELECT * FROM read_csv_auto('data/*_methods.csv');

-- Export combined summary for Quarto report
COPY status_codes TO 'data/agg_summary.csv' (HEADER, DELIMITER ',');
COPY urls TO 'data/agg_urls.csv' (HEADER, DELIMITER ',');
COPY methods TO 'data/agg_methods.csv' (HEADER, DELIMITER ',');
