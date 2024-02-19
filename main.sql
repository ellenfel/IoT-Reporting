-- Drop existing tables if they exist
DROP TABLE IF EXISTS veri;
DROP TABLE IF EXISTS last_veri;


-- Create the veri table
CREATE TABLE veri AS (
    SELECT
        device.Id,
        device.name AS devName,
        ts_kv.ts,
        ts_kv.key,
        ts_kv.long_v,
        ts_kv.dbl_v,
        ts_kv.str_v,
        ts_kv.bool_v
    FROM ts_kv
    JOIN device ON device.Id = ts_kv.entity_id
    TABLESAMPLE SYSTEM (1)  -- Adjust the sampling percentage as needed (1% in this example)

);

ALTER TABLE veri ADD COLUMN merged_column varchar(512); -- Adjust the length as needed

UPDATE veri SET merged_column = CONCAT(bool_v, ' ', long_v, ' ', dbl_v, ' ', str_v);

ALTER TABLE veri DROP COLUMN long_v, DROP COLUMN dbl_v, DROP COLUMN str_v, DROP COLUMN bool_v;

ALTER TABLE veri RENAME COLUMN key TO telemetry;

DROP TABLE IF EXISTS last_veri;

CREATE TABLE last_veri AS (
    SELECT * FROM veri
    JOIN ts_kv_dictionary ON veri.telemetry = ts_kv_dictionary.key_id
);

ALTER TABLE last_veri DROP COLUMN key_id, DROP COLUMN telemetry;

-- Select Relevant Columns from `last_veri` Table with Filtering and Formatting
SELECT
    to_timestamp(ts / 1000) AS ts,
    devName,
    key,
    merged_column
FROM last_veri
WHERE devName <> 'UG-67';