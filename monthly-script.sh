DB_NAME="energy-consumption-forecast"
DB_USER="postgres"
DB_PASS="postgres"
MONTH=11
YEAR=2023

# Calculate the last day of the month using PostgreSQL functions
LAST_DAY=$(psql -h localhost -U $DB_USER -d $DB_NAME -t -c "SELECT date_trunc('MONTH', '$YEAR-$MONTH-01'::date) + INTERVAL '1 MONTH' - INTERVAL '1 day';")

# Set the PGPASSFILE environment variable to specify the location of the .pgpass file
export PGPASSFILE=~/.pgpass

# SQL query with parameters
SQL=$(cat <<EOF
WITH RECURSIVE DaySeries AS (
    SELECT generate_series('$YEAR-$MONTH-01'::date, '$LAST_DAY'::date, '1 day'::interval) AS day_of_month
)
SELECT
    ds.day_of_month,
    MAX(CASE WHEN lv.key = 'Active Energy' THEN lv.merged_column END) AS energy_value,
    MAX(CASE WHEN lv.key = 'Active Power' THEN lv.merged_column END) AS power_value,
    MAX(CASE WHEN lv.key = 'Frequency' THEN lv.merged_column END) AS Frequency
FROM
    DaySeries ds
LEFT JOIN (
    SELECT
        TO_TIMESTAMP(ts/1000)::date AS day_of_month,
        key,
        merged_column,
        ROW_NUMBER() OVER (PARTITION BY TO_TIMESTAMP(ts/1000)::date, key ORDER BY ts DESC) AS rn
    FROM
        last_veri
    WHERE
        TO_TIMESTAMP(ts/1000)::date >= '$YEAR-$MONTH-01' AND TO_TIMESTAMP(ts/1000)::date <= '$LAST_DAY'
) lv ON ds.day_of_month = lv.day_of_month AND rn = 1
GROUP BY
    ds.day_of_month
ORDER BY
    ds.day_of_month;
EOF
)

# Execute SQL query and export the result to CSV with the modified filename
echo "$SQL" | PGPASSFILE=~/.pgpass psql -h localhost -U $DB_USER -d $DB_NAME -a -o veri_energy_monthly.csv
echo "completed"
