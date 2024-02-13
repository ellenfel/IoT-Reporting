WITH RECURSIVE DaySeries AS (
    SELECT generate_series('2023-12-01'::date, '2023-12-31'::date, '1 day'::interval) AS day_of_month
)
SELECT
    ds.day_of_month,
    MAX(CASE WHEN lv.key = 'Active Energy' THEN lv.merged_column END) AS energy_value,
    MAX(CASE WHEN lv.key = 'Active Power' THEN lv.merged_column END) AS power_value,
    MAX(CASE WHEN lv.key = 'frequency' THEN lv.merged_column END) AS frequency
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
        TO_TIMESTAMP(ts/1000)::date >= '2023-12-01' AND TO_TIMESTAMP(ts/1000)::date <= '2023-12-31'
) lv ON ds.day_of_month = lv.day_of_month AND rn = 1
GROUP BY
    ds.day_of_month
ORDER BY
    ds.day_of_month;
