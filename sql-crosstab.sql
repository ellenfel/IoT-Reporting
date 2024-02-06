DROP TABLE IF EXISTS temp_table;
CREATE EXTENSION IF NOT EXISTS tablefunc;

-- Assuming the veri table structure has columns id, devName, ts, telemetry, and merged_column

-- Create a temporary table with unique combinations of device, timestamp, and telemetry key
CREATE TEMP TABLE temp_table AS (
    SELECT DISTINCT ON (devName, ts, telemeACtry)
        devName,
        to_timestamp(ts / 1000) AS ts, -- Convert milliseconds to seconds
        telemetry,
        merged_column
    FROM veri TABLESAMPLE BERNOULLI(0.1) REPEATABLE(42)
    ORDER BY devName, ts, telemetry
);

-- Use crosstab to pivot the data
SELECT * FROM crosstab(
    'SELECT devName, ts, telemetry, COALESCE(merged_column, ''''::varchar) FROM temp_table ORDER BY 1,2,3',
    'VALUES (''rssi''), (''frequency''), (''snr'')'
) AS ct_result(devName VARCHAR, ts TIMESTAMP, rssi VARCHAR, frequency VARCHAR, snr VARCHAR)
WHERE COALESCE(rssi, frequency, snr) IS NOT NULL; -- Exclude rows with all null values

