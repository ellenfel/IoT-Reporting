#!/bin/sh

mosquitto_sub -v -h 127.0.0.1 -p 1883 -t 'executescript/#' | while read RAW_DATA
#mosquitto_sub -R -h 127.0.0.1 -t executescript/reporting | while read RAW_DATA
do
  sudo bash /home/nemport/IoT-Reporting/sql-script.sh
  echo "report generated:)"
done
