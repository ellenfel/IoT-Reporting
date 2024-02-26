####################################################################
# INPUTS:                                                          #
#     reportFlag                                                   #
#     reportType                                                   #
#     day_input                                                    #
#     month_input                                                  #
#     year_input                                                   #
#                                                                  #
####################################################################

DB_NAME="energy-consumption-forecast"
DB_USER="postgres"
DB_PASS="postgres"



bash /home/ellenfel/Desktop/reporting/renew_token.sh
YOUR_JWT_TOKEN=$(cat /home/ellenfel/Desktop/reporting/jwt_token.txt)

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


while true; do
    # Renew the JWT token once an hour
    if [ $((SECONDS % 3500)) -eq 0 ]; then
        # Execute renew_token.sh to renew the token
        /home/ellenfel/Desktop/reporting/renew_token.sh
        # Read the renewed JWT token from the local text file
        YOUR_JWT_TOKEN=$(cat /home/ellenfel/Desktop/reporting/jwt_token.txt)
        echo "JWT token renewed: $YOUR_JWT_TOKEN"
    fi

    sleep 15


    #Flag - first input
    response_flag=$(curl -X 'GET' \
    'http://127.0.0.1:8080/api/plugins/telemetry/DEVICE/134d3821-25ff-11ee-9c0b-a53a7980c9e6/values/attributes?keys=reportFlag' \
    -H 'accept: application/json' \
    -H "X-Authorization: Bearer $YOUR_JWT_TOKEN"
    )

    reportFlag=$(echo "$response_flag" | jq -r '.[0].value')


    if [ "$reportFlag" = "true" ]; then #FLAG TO GENERATE REPORTS OR NOT

        # If the value is false, decide type of report
            
        echo condition-returns_true
        sleep 1

        response_type=$(curl -X 'GET' \
        'http://127.0.0.1:8080/api/plugins/telemetry/DEVICE/134d3821-25ff-11ee-9c0b-a53a7980c9e6/values/attributes?keys=type' \
        -H 'accept: application/json' \
        -H "X-Authorization: Bearer $YOUR_JWT_TOKEN"
        )

        reportType=$(echo "$response_type" | jq -r '.[0].value')
        echo $reportType
        sleep 5


        if [ "$reportType" = "false" ]; then #IS IT MONTHLY OR NOT
            
            echo type_is_monthly
            sleep 1

            #MONTH
            response_month=$(curl -X 'GET' \
            'http://127.0.0.1:8080/api/plugins/telemetry/DEVICE/134d3821-25ff-11ee-9c0b-a53a7980c9e6/values/attributes?keys=month' \
            -H 'accept: application/json' \
            -H "X-Authorization: Bearer $YOUR_JWT_TOKEN"
            )

            #YEAR
            response_year=$(curl -X 'GET' \
            'http://127.0.0.1:8080/api/plugins/telemetry/DEVICE/134d3821-25ff-11ee-9c0b-a53a7980c9e6/values/attributes?keys=year' \
            -H 'accept: application/json' \
            -H "X-Authorization: Bearer $YOUR_JWT_TOKEN"
            )


            month_input=$(echo "$response_month" | jq -r '.[0].value')
            echo $month_input 
            sleep 5

            year_input=$(echo "$response_year" | jq -r '.[0].value')
            echo $year_input
            sleep 5


            # Execute SQL query for creating last_veri table
            echo "$CREATE_LAST_VERI" | PGPASSFILE=~/.pgpass psql -h localhost -U $DB_USER -d $DB_NAME
            echo "last_veri table created successfully"

            # Create a 'reports' folder if it doesn't exist
            mkdir -p reports

            # Function to export data to CSV for a specific device
            export_csv_for_device(){
               local DEVICE_NAME="$1"
    
                # SQL query with parameters for exporting data to CSV for a specific device
                CSV_QUERY=$(cat <<EOF
                COPY (
                    WITH RECURSIVE DaySeries AS (
                        SELECT generate_series('$year_input-$month_input-01'::date, date_trunc('MONTH', '$year_input-$month_input-01'::date) + INTERVAL '1 MONTH' - INTERVAL '1 day', '1 day'::interval) AS day_of_month
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
                            TO_TIMESTAMP(ts/1000)::date >= '$year_input-$month_input-01' AND TO_TIMESTAMP(ts/1000)::date <= date_trunc('MONTH', '$year_input-$month_input-01'::date) + INTERVAL '1 MONTH' - INTERVAL '1 day'
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
                echo "$CSV_QUERY" | PGPASSFILE=~/.pgpass psql -h localhost -U $DB_USER -d $DB_NAME -A -F"," -t -o "reports/veri_energy_${DEVICE_NAME}_monthly${month_input}-${year_input}.csv"
                echo "Data exported to reports/veri_energy_${DEVICE_NAME}_monthly.csv successfully"
            }


                        veri_energy_${DEVICE_NAME}_monthly$(month_input) -$(year_input).csv

                        # Get the list of device names (excluding 'UG-67')
                        DEVICE_NAMES=$(PGPASSFILE=~/.pgpass psql -h localhost -U $DB_USER -d $DB_NAME -At -c "SELECT DISTINCT name FROM device WHERE name <> 'UG-67';")

                        # Iterate over each device name and export CSV
                        for DEVICE_NAME in $DEVICE_NAMES; do
                            export_csv_for_device "$DEVICE_NAME"
                        done

                        echo "All data exported successfully"










            


        elif [ "$reportType" = "true" ]; then

            #DAY
            response_day=$(curl -X 'GET' \
            'http://127.0.0.1:8080/api/plugins/telemetry/DEVICE/134d3821-25ff-11ee-9c0b-a53a7980c9e6/values/attributes?keys=day' \
            -H 'accept: application/json' \
            -H "X-Authorization: Bearer $YOUR_JWT_TOKEN"
            )

            #MONTH
            response_month=$(curl -X 'GET' \
            'http://127.0.0.1:8080/api/plugins/telemetry/DEVICE/134d3821-25ff-11ee-9c0b-a53a7980c9e6/values/attributes?keys=month' \
            -H 'accept: application/json' \
            -H "X-Authorization: Bearer $YOUR_JWT_TOKEN"
            )

            #YEAR
            response_year=$(curl -X 'GET' \
            'http://127.0.0.1:8080/api/plugins/telemetry/DEVICE/134d3821-25ff-11ee-9c0b-a53a7980c9e6/values/attributes?keys=year' \
            -H 'accept: application/json' \
            -H "X-Authorization: Bearer $YOUR_JWT_TOKEN"
            )

            day_input=$(echo "$response_day" | jq -r '.[0].value')
            echo $day_input 
            sleep 5

            year_input=$(echo "$response_month" | jq -r '.[0].value')
            echo $year_input
            sleep 5

            year_input=$(echo "$response_year" | jq -r '.[0].value')
            echo $year_input
            sleep 5

        else
            # If the value is not 450, sleep for 5 seconds and then try again
            echo will-check-again...
            sleep 10 

        fi


    else
        # If the value is not 450, sleep for 5 seconds and then try again
        echo will-check-again...
        sleep 10 
    fi


done