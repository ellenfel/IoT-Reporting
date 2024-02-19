#!/bin/bash

# Database credentials
DB_NAME="thingsboard"
DB_USER="postgres"
DB_PASS="postgres"

# SQL query
SQL=" 

DROP TABLE IF EXISTS veri;

CREATE TABLE veri
AS (	SELECT device.Id, device.name,  ts_kv.ts, ts_kv.key, ts_kv.long_v, ts_kv.dbl_v, ts_kv.str_v, ts_kv.bool_v
	FROM ts_kv JOIN device ON device.Id = ts_kv.entity_id);
	
ALTER TABLE veri ADD COLUMN merged_column varchar(255);

UPDATE veri SET merged_column = CONCAT(bool_v, ' ', long_v, ' ',dbl_v,' ',str_v);

ALTER TABLE veri DROP long_v, DROP dbl_v, DROP str_v, DROP bool_v;

ALTER TABLE veri
RENAME COLUMN key TO telemetry;

DROP TABLE IF EXISTS last_veri;

CREATE TABLE last_veri
AS ( SELECT * FROM veri JOIN ts_kv_dictionary ON veri.telemetry = ts_kv_dictionary.key_id) ;
		

ALTER TABLE last_veri DROP key_id, DROP telemetry;

SELECT id, name,  key, ts, merged_column FROM last_veri;

"
#COPY (SELECT * FROM last_veri) TO STDOUT WITH CSV HEADER;


# Execute SQL query and export the result to CSV
export PGPASSWORD=$DB_PASS
echo "$SQL" | psql -h localhost -U $DB_USER -d $DB_NAME -a -o veri.csv
echo "hey"

# Now, you can convert the CSV to XLS if desired. For example, using `ssconvert` (from Gnumeric package):
# ssconvert veri.csv veri.xls

New-SQL="
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

-- Select a 1/1000 random sample with all keys represented
SELECT id, devName, key, ts, merged_column
FROM last_veri TABLESAMPLE BERNOULLI(0.1) REPEATABLE(42)
WHERE devName <> 'UG-67';


"