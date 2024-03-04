#!/bin/bash

DB_NAME="thingsboard"
DB_USER="postgres"
DB_PASS="postgres"
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


# Create a 'reports' folder if it doesn't exist
mkdir -p reports

# Function to export data to CSV for a specific device
export_csv_for_device() {
    local DEVICE_NAME="$1"
    
    # SQL query with parameters for exporting data to CSV for a specific device
    CSV_QUERY=$(cat <<EOF
    COPY (
        WITH RECURSIVE DaySeries AS (
            SELECT generate_series('$YEAR-$MONTH-01'::date, date_trunc('MONTH', '$YEAR-$MONTH-01'::date) + INTERVAL '1 MONTH' - INTERVAL '1 day', '1 day'::interval) AS day_of_month
        )
        SELECT
            ds.day_of_month,
            lv.devName AS device_name,  -- Include device_name in the SELECT clause
            COALESCE(MAX(CASE WHEN lv.key = 'Active Energy' THEN lv.merged_column END), 'No Data') AS energy_value,
            COALESCE(MAX(CASE WHEN lv.key = 'Active Power' THEN lv.merged_column END), 'No Data') AS power_value,
            COALESCE(MAX(CASE WHEN lv.key = 'Frequency' THEN lv.merged_column END), 'No Data') AS Frequency
        FROM
            DaySeries ds
        LEFT JOIN (
            SELECT
                TO_TIMESTAMP(ts/1000)::date AS day_of_month,
                devName,
                key,
                merged_column,
                ROW_NUMBER() OVER (PARTITION BY TO_TIMESTAMP(ts/1000)::date, key ORDER BY ts DESC) AS rn
            FROM
                last_veri
            WHERE
                TO_TIMESTAMP(ts/1000)::date >= '$YEAR-$MONTH-01' AND TO_TIMESTAMP(ts/1000)::date <= date_trunc('MONTH', '$YEAR-$MONTH-01'::date) + INTERVAL '1 MONTH' - INTERVAL '1 day'
                AND devName = '$DEVICE_NAME'
        ) lv ON ds.day_of_month = lv.day_of_month AND rn = 1
        GROUP BY
            ds.day_of_month, lv.devName  -- Include device_name in the GROUP BY clause
        ORDER BY
            ds.day_of_month
    )
    TO STDOUT WITH CSV HEADER;
EOF
    )

    # Execute SQL query for exporting data to CSV
    echo "$CSV_QUERY" | PGPASSFILE=~/.pgpass psql -h localhost -U $DB_USER -d $DB_NAME -A -F"," -t -o "reports/veri_energy_${DEVICE_NAME}_monthly${MONTH}-${YEAR}.csv"
    echo "Data exported to reports/veri_energy_${DEVICE_NAME}_monthly.csv successfully"
}
veri_energy_${DEVICE_NAME}_monthly$(MONTH) -$(YEAR).csv

# Get the list of device names (excluding 'UG-67')
DEVICE_NAMES=$(PGPASSFILE=~/.pgpass psql -h localhost -U $DB_USER -d $DB_NAME -At -c "SELECT DISTINCT name FROM device WHERE name <> 'UG-67';")

# Iterate over each device name and export CSV
for DEVICE_NAME in $DEVICE_NAMES; do
    export_csv_for_device "$DEVICE_NAME"
done

echo "All data exported successfully"




# SQL query with parameters for exporting data to CSV
EXPORT_TO_CSV=$(cat <<EOF
-- SQL query to export data to CSV replacing NULL with 'No Data'
COPY (
    WITH RECURSIVE DaySeries AS (
        SELECT generate_series('$YEAR-$MONTH-01'::date, date_trunc('MONTH', '$YEAR-$MONTH-01'::date) + INTERVAL '1 MONTH' - INTERVAL '1 day', '1 day'::interval) AS day_of_month
    )
    SELECT
        ds.day_of_month,
        lv.devName AS device_name,  -- Include device_name in the SELECT clause
        COALESCE(MAX(CASE WHEN lv.key = 'Active Energy' THEN lv.merged_column END), 'No Data') AS energy_value,
        COALESCE(MAX(CASE WHEN lv.key = 'Active Power' THEN lv.merged_column END), 'No Data') AS power_value,
        COALESCE(MAX(CASE WHEN lv.key = 'Frequency' THEN lv.merged_column END), 'No Data') AS Frequency
    FROM
        DaySeries ds
    LEFT JOIN (
        SELECT
            TO_TIMESTAMP(ts/1000)::date AS day_of_month,
            devName,
            key,
            merged_column,
            ROW_NUMBER() OVER (PARTITION BY TO_TIMESTAMP(ts/1000)::date, key ORDER BY ts DESC) AS rn
        FROM
            last_veri
        WHERE
            TO_TIMESTAMP(ts/1000)::date >= '$YEAR-$MONTH-01' AND TO_TIMESTAMP(ts/1000)::date <= date_trunc('MONTH', '$YEAR-$MONTH-01'::date) + INTERVAL '1 MONTH' - INTERVAL '1 day'
    ) lv ON ds.day_of_month = lv.day_of_month AND rn = 1
    GROUP BY
        ds.day_of_month, lv.devName  -- Include device_name in the GROUP BY clause
    ORDER BY
        ds.day_of_month
)
TO STDOUT WITH CSV HEADER;
EOF
)

# Execute SQL query for exporting data to CSV
echo "$EXPORT_TO_CSV" | PGPASSFILE=~/.pgpass psql -h localhost -U $DB_USER -d $DB_NAME -A -F"," -t -o veri_energy_monthly.csv
echo "Data exported to veri_energy_monthly.csv successfully"


