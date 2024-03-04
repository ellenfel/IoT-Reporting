#!/bin/bash

# Database credentials
DB_NAME="thingsboard"
DB_USER="postgres"
DB_PASS="postgres"

# SQL query
SQL=" 

WITH LastVeriWithRowNumber AS (
    SELECT
        devname,
        TO_TIMESTAMP(ts / 1000) AS formatted_ts,
        merged_column,
        ROW_NUMBER() OVER (PARTITION BY devname ORDER BY ts DESC) AS row_num
    FROM last_veri
    WHERE key = 'Active Energy'
)
SELECT
    devname,
    TO_CHAR(formatted_ts, 'DD/MM/YYYY') AS formatted_date,
    merged_column
FROM LastVeriWithRowNumber
WHERE row_num = 1;



"
#COPY (SELECT * FROM last_veri) TO STDOUT WITH CSV HEADER;


# Execute SQL query and export the result to CSV
export PGPASSWORD=$DB_PASS
echo "$SQL" | psql -h localhost -U $DB_USER -d $DB_NAME -a -o veri_energy.csv
echo "hey" 

# Now, you can convert the CSV to XLS if desired. For example, using `ssconvert` (from Gnumeric package):
# ssconvert veri.csv veri.xls