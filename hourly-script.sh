#!/bin/bash

DB_NAME="thingsboard"
DB_USER="postgres"
DB_PASS="postgres"
DAY=6
MONTH=12
YEAR=2023


# Set the PGPASSFILE environment variable to specify the location of the .pgpass file
export PGPASSFILE=~/.pgpass

# SQL query with parameters for creating last_veri table
CREATE_LAST_VERI=$(cat <<EOF
-- Drop existing tables if they exist
DROP TABLE IF EXISTS veri;
DROP TABLE IF EXISTS last_veri;

-- Create the veri table without the rows where device_name is 'UG-67'
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
    WHERE random() < 0.01 AND device.name <> 'UG-67'  -- Adjust the sampling percentage as needed (1% in this example) and exclude 'UG-67'
);

ALTER TABLE veri ADD COLUMN merged_column varchar(512); -- Adjust the length as needed

UPDATE veri SET merged_column = CONCAT(bool_v, ' ', long_v, ' ', dbl_v, ' ', str_v);

ALTER TABLE veri DROP COLUMN long_v, DROP COLUMN dbl_v, DROP COLUMN str_v, DROP COLUMN bool_v;

ALTER TABLE veri RENAME COLUMN key TO telemetry;

-- Create the last_veri table by joining veri with ts_kv_dictionary
CREATE TABLE last_veri AS (
    SELECT * FROM veri
    JOIN ts_kv_dictionary ON veri.telemetry = ts_kv_dictionary.key_id
);

ALTER TABLE last_veri DROP COLUMN key_id, DROP COLUMN telemetry;
EOF
)

# Execute SQL query for creating last_veri table
echo "$CREATE_LAST_VERI" | PGPASSFILE=~/.pgpass psql -h localhost -U $DB_USER -d $DB_NAME
echo "last_veri table created successfully"


# Function to export data to CSV for a specific device and day
export_csv_for_device_and_day() {
    local DEVICE_NAME="$1"

    # SQL query with parameters for exporting data to CSV for a specific device and day
    CSV_QUERY=$(cat <<EOF
    COPY (
        WITH RECURSIVE HourlySeries AS (
            SELECT generate_series('$YEAR-$MONTH-$DAY 00:00:00'::timestamp, '$YEAR-$MONTH-$DAY 23:59:59'::timestamp, '1 hour'::interval) AS hour_of_day
        )
        SELECT
            hs.hour_of_day,
            lv.devName AS device_name,
            COALESCE(MAX(CASE WHEN lv.key = 'Active Energy' THEN lv.merged_column END), 'No Data') AS energy_value,
            COALESCE(MAX(CASE WHEN lv.key = 'Active Power' THEN lv.merged_column END), 'No Data') AS power_value,
            COALESCE(MAX(CASE WHEN lv.key = 'Frequency' THEN lv.merged_column END), 'No Data') AS Frequency
        FROM
            HourlySeries hs
        LEFT JOIN (
            SELECT
                TO_TIMESTAMP(ts/1000)::timestamp AS hour_of_day,
                devName,
                key,
                merged_column,
                ROW_NUMBER() OVER (PARTITION BY TO_TIMESTAMP(ts/1000)::timestamp, key ORDER BY ts DESC) AS rn
            FROM
                last_veri
            WHERE
                TO_TIMESTAMP(ts/1000)::date = '$YEAR-$MONTH-$DAY' AND devName = '$DEVICE_NAME'
        ) lv ON hs.hour_of_day = lv.hour_of_day AND rn = 1
        GROUP BY
            hs.hour_of_day, lv.devName
        ORDER BY
            hs.hour_of_day
    )
    TO STDOUT WITH CSV HEADER;
EOF
    )

    # Execute SQL query for exporting data to CSV
    echo "$CSV_QUERY" | PGPASSFILE=~/.pgpass psql -h localhost -U $DB_USER -d $DB_NAME -A -F"," -t -o "reports/daily/veri_energy_${DEVICE_NAME}_daily_${YEAR}-${MONTH}-${DAY}.csv"
    echo "Data exported to reports/daily/veri_energy_${DEVICE_NAME}_daily_${YEAR}-${MONTH}-${DAY}.csv successfully"
}

# Create a 'reports/daily' folder if it doesn't exist
mkdir -p reports/daily

# Get the list of device names (excluding 'UG-67')
DEVICE_NAMES=$(PGPASSFILE=~/.pgpass psql -h localhost -U $DB_USER -d $DB_NAME -At -c "SELECT DISTINCT name FROM device WHERE name <> 'UG-67';")

# Iterate over each device name and export CSV for the specified day
for DEVICE_NAME in $DEVICE_NAMES; do
    export_csv_for_device_and_day "$DEVICE_NAME"
done

echo "All data exported successfully"
