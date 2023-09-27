#!/bin/bash

# Database credentials
DB_NAME="thingsboard"
DB_USER="postgres"
DB_PASS="postgres"

# SQL query
SQL="
DROP TABLE IF EXISTS veri;
CREATE TABLE veri AS 
SELECT device.Id, device.name, ts_kv.ts, ts_kv.key, ts_kv.long_v, ts_kv.dbl_v
FROM ts_kv
JOIN device ON device.Id = ts_kv.entity_id;
COPY (SELECT * FROM veri) TO STDOUT WITH CSV HEADER;
"

# Execute SQL query and export the result to CSV
export PGPASSWORD=$DB_PASS
echo "$SQL" | psql -h localhost -U $DB_USER -d $DB_NAME -a -o veri.csv
echo "hey"

# Now, you can convert the CSV to XLS if desired. For example, using `ssconvert` (from Gnumeric package):
# ssconvert veri.csv veri.xls

