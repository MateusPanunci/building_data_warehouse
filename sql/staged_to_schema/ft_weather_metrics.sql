INSERT INTO ft_weather_metrics (id_country, year, avg_air_quality, avg_precipitation)
SELECT 
    dc.id_country,
    combined.clean_year AS year,
    MAX(combined.air_val) AS avg_air_quality,
    MAX(combined.rain_val) AS avg_precipitation
FROM (
    SELECT 
        jt.country_name,
        TO_NUMBER(jt.year) AS clean_year,
    
       -- Converting to number and replacing '.' with ','    
        CASE WHEN UPPER(TRIM(jt.indicator_id)) = 'EN.ATM.PM25.MC.M3' THEN TO_NUMBER(REPLACE(jt.metric_value, '.', ',')) END AS air_val,
        CASE WHEN UPPER(TRIM(jt.indicator_id)) = 'AG.LND.PRCP.MM'   THEN TO_NUMBER(REPLACE(jt.metric_value, '.', ',')) END AS rain_val
    FROM 
        -- Extracting data from JSON
        STG_WORLD_BANK s,
        JSON_TABLE(s.DADOS_JSON, '$[*]' -- Go through all elements of the JSON array and transform each one in a line into a virtual table 
            COLUMNS (
                indicator_id VARCHAR2(50)  PATH '$.indicator.id',
                country_name VARCHAR2(120) PATH '$.country.value',
                year         VARCHAR2(4)   PATH '$.date',
                metric_value VARCHAR2(50)  PATH '$.value'
            )
        ) jt
    WHERE UPPER(TRIM(jt.indicator_id)) IN ('EN.ATM.PM25.MC.M3', 'AG.LND.PRCP.MM')
      AND jt.metric_value IS NOT NULL
) combined
JOIN dim_country dc 
    ON UPPER(TRIM(dc.nm_country)) = UPPER(TRIM(combined.country_name))
GROUP BY 
    dc.id_country, 
    combined.clean_year;