# reporting-IosPhere

curl -X 'GET'   'http://127.0.0.1:8080/api/plugins/telemetry/DEVICE/134d3821-25ff-11ee-9c0b-a53a7980c9e6/values/timeseries?keys=power'   -H 'accept: application/json'   -H 'X-Authorization: Bearer $YOUR_JWT_TOKEN'


1 - get-token.sh  -> after executed outputs following:                      
        {"token":"$YOUR_JWT_TOKEN", "refreshToken":"$YOUR_JWT_REFRESH_TOKEN"}

2 - get-tel.sh -> check for user inputs, should work as a microservice
        once trigerred it executes sql-script.sh 
        It should take new jwt token as a input 

3 - sql-script.sh -> executes a sql script & generates the report as csv
        This shoul also take user input key and device primarilly


main_script.sh works as it is now.


WITH LastVeriWithRowNumber AS (
    SELECT
        id,
        name,
        key,
        ts,
        merged_column,
        ROW_NUMBER() OVER (PARTITION BY name ORDER BY ts DESC) AS row_num
    FROM last_veri
)
SELECT
    id,
    name,
    key,
    ts,
    merged_column
FROM LastVeriWithRowNumber
WHERE row_num = 1;
