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
