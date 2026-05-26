-------------- BASIC QUERYS -------------


-- Average happiness_score by region
SELECT
    c.REGION AS region,
    ROUND(AVG(f.HAPPINESS_SCORE), 3) AS avg_happiness,
    COUNT(*) AS country_count
FROM FT_COUNTRY_METRICS f
JOIN DIM_COUNTRY c ON c.ID_COUNTRY = f.ID_COUNTRY
WHERE f.HAPPINESS_SCORE IS NOT NULL
GROUP BY c.REGION
ORDER BY avg_happiness DESC;


-- Average unemployment and inflation by region
SELECT
    c.REGION AS region,
    ROUND(AVG(COALESCE(f.UNEMPLOYMENT_PCT, 0)), 2) AS avg_unemployment,
    ROUND(AVG(COALESCE(f.INFLATION_PCT, 0)), 2) AS avg_inflation,
    COUNT(*) AS country_count,
    -- Count how many countries had null data before COALESCE
    SUM(CASE WHEN f.UNEMPLOYMENT_PCT IS NULL THEN 1 ELSE 0 END) AS null_unemployment_count,
    SUM(CASE WHEN f.INFLATION_PCT IS NULL THEN 1 ELSE 0 END) AS null_inflation_count
FROM FT_COUNTRY_METRICS f
JOIN DIM_COUNTRY c ON c.ID_COUNTRY = f.ID_COUNTRY
GROUP BY c.REGION
ORDER BY avg_unemployment DESC;


-- Religion domimant more common by region
SELECT 
    c.region AS region,
    r.NM_RELIGION AS dominant_religion,
    COUNT(r.NM_RELIGION) AS religion_count,
    DENSE_RANK() OVER (PARTITION BY c.region ORDER BY COUNT(r.NM_RELIGION) DESC) AS ranking
FROM 
    DIM_RELIGION r
JOIN DIM_COUNTRY c ON c.ID_COUNTRY = r.ID_COUNTRY
GROUP BY c.region, r.NM_RELIGION
ORDER BY c.region, r.NM_RELIGION;

-- Investigating countries with "N/A"
SELECT 
    c.NM_COUNTRY AS country_name,
    c.REGION AS region_status,
    r.NM_RELIGION AS religion
FROM 
    DIM_COUNTRY c
JOIN 
    DIM_RELIGION r ON c.ID_COUNTRY = r.ID_COUNTRY
WHERE 
    c.REGION = 'N/A' OR c.REGION IS NULL
ORDER BY 
    r.NM_RELIGION, c.NM_COUNTRY;


----------------- QUERYS WITH CASE and COALESCE ----------------

-- Classification of contries by hapiness score
SELECT 
    c.NM_COUNTRY AS country,
    CASE WHEN f.happiness_score > 7 THEN 'Happy'
         WHEN f.happiness_score > 5 THEN 'Medium'
         ELSE 'Unhappy' END AS happiness_level,
    f.happiness_score as happiness_score
FROM FT_COUNTRY_METRICS f
JOIN DIM_COUNTRY c ON c.ID_COUNTRY = f.ID_COUNTRY
;


-- Replacement and counting of nulls of inflation and unemployment by average of the region (+window function)
WITH region_avg AS (
    SELECT
        c.NM_COUNTRY AS country,
        c.REGION AS region,    
        f.inflation_pct AS raw_inflation_pct,
        f.unemployment_pct AS raw_unemployment_pct,
        AVG(f.inflation_pct) OVER(PARTITION BY c.region) AS avg_region_inflation,
        AVG(f.unemployment_pct) OVER(PARTITION BY c.region) AS avg_region_unemployment
    FROM 
        FT_COUNTRY_METRICS f
    JOIN DIM_COUNTRY c ON c.ID_COUNTRY = f.ID_COUNTRY
)
SELECT 
    ra.country,
    ra.region,
    ROUND(COALESCE(ra.raw_inflation_pct, ra.avg_region_inflation), 3) AS inflation_pct,
    ROUND(COALESCE(ra.raw_unemployment_pct, ra.avg_region_unemployment), 3) AS unemployment_pct,
    CASE WHEN ra.raw_inflation_pct IS NULL THEN 1 ELSE 0 END AS inflation_was_null,
    CASE WHEN ra.raw_unemployment_pct IS NULL THEN 1 ELSE 0 END AS unemployment_was_null
FROM 
    region_avg ra
;

------------------ QUERYS WITH ROLLUP AND CUBE -------------

-- ROLLUP of mean of precipitation and air_quality by country -> region 
SELECT 
    c.NM_COUNTRY AS country,
    c.REGION AS region,
    ROUND(AVG(fwm.AVG_AIR_QUALITY), 2) AS avg_air_quality,
    ROUND(AVG(fwm.AVG_PRECIPITATION), 2) AS avg_precipitation
FROM 
    ft_weather_metrics fwm
JOIN DIM_COUNTRY c ON c.ID_COUNTRY = fwm.ID_COUNTRY
GROUP BY ROLLUP(c.NM_COUNTRY, c.REGION)
;
    

-- CUBE mean of precipitation and air_quality by country <-> region
SELECT 
    c.NM_COUNTRY AS country,
    c.REGION AS region,
    ROUND(AVG(fwm.AVG_AIR_QUALITY), 2) AS avg_air_quality,
    ROUND(AVG(fwm.AVG_PRECIPITATION), 2) AS avg_precipitation
FROM 
    ft_weather_metrics fwm
JOIN DIM_COUNTRY c ON c.ID_COUNTRY = fwm.ID_COUNTRY
GROUP BY CUBE(c.NM_COUNTRY, c.REGION)
;


-------------- QUERYS WITH WINDOW FUNCTIONS -------------

-- RANK by hapiness inside each region
SELECT
    c.REGION AS region,
    c.NM_COUNTRY AS country,
    f.HAPPINESS_SCORE AS happiness_score,
    rank() OVER (PARTITION BY c.REGION ORDER BY f.HAPPINESS_SCORE DESC) AS regional_rank,
    rank() OVER (ORDER BY f.HAPPINESS_SCORE DESC) AS global_rank
FROM 
    FT_COUNTRY_METRICS f 
JOIN DIM_COUNTRY c ON c.ID_COUNTRY = f.ID_COUNTRY
ORDER by c.region, f.happiness_score DESC
;


-- Porcentage of happiness_score of each country in relation to the average of the region (see how many % above/below the average)
SELECT 
    c.NM_COUNTRY AS country,
    c.REGION AS region,
    f.happiness_score,
    ROUND((f.happiness_score / AVG(f.happiness_score) OVER (PARTITION BY c.REGION)) * 100, 2) AS percent_of_regional_avg
FROM 
    FT_COUNTRY_METRICS f
JOIN DIM_COUNTRY c ON c.ID_COUNTRY = f.ID_COUNTRY
;

-- Cumulative count of airports by region and by country
SELECT DISTINCT
    c.nm_country,
    c.REGION AS region,
    count(a.id_airport) OVER (PARTITION BY c.nm_country ORDER BY c.nm_country) AS airports_country_count,
    count(a.id_airport) OVER (PARTITION BY c.REGION ORDER BY c.region) AS airports_region_count
FROM 
    DIM_AIRPORT a
LEFT JOIN DIM_COUNTRY c ON c.ID_COUNTRY = a.ID_COUNTRY
;
    

-------------- QUERYS WITH VIEW -------------

-- VIEW: Consolidated view of country + all metrics
CREATE VIEW vw_country_metrics(
    country_name,
    year, 
    population, 
    happiness_score, 
    economy_score, 
    freedom_score, 
    gov_corruption, 
    generosity_score, 
    health_score, 
    family_score, 
    dystopia_compare_score, 
    infant_mortality_pct, 
    unemployment_pct, 
    inflation_pct
) AS 
SELECT 
    dc.nm_country,
    cm.year,
    cm.population,
    cm.happiness_score,           
    cm.economy_score,    
    cm.freedom_score,                   
    cm.gov_corruption,     
    cm.generosity_score,                
    cm.health_score,    
    cm.family_score,                   
    cm.dystopia_compare_score,   
    cm.infant_mortality_pct,
    cm.unemployment_pct,
    cm.inflation_pct
FROM 
    ft_country_metrics cm
LEFT JOIN dim_country dc ON cm.id_country = dc.id_country
;

-- Testing the view
SELECT * 
FROM VW_COUNTRY_METRICS
;


-- MATERIALIZED VIEW: mean of indicators by region
-- Used for accelerating OLAP queries of drill-down
CREATE MATERIALIZED VIEW mv_region_metrics 
    BUILD IMMEDIATE 
    REFRESH COMPLETE ON DEMAND
    ENABLE QUERY REWRITE
    AS SELECT
        dc.region,
        ROUND(AVG(cm.population), 0) AS avg_population,
        ROUND(AVG(cm.happiness_score), 2) AS avg_happiness,
        ROUND(AVG(cm.economy_score), 2) AS avg_gdp,
        ROUND(AVG(cm.freedom_score), 2) AS avg_freedom,        
        ROUND(AVG(cm.gov_corruption), 2) AS avg_corruption_percept,     
        ROUND(AVG(cm.generosity_score), 4) AS avg_generosity,        
        ROUND(AVG(cm.health_score), 2) AS avg_life_expectancy, 
        ROUND(AVG(cm.family_score), 2) AS avg_family_score,             
        ROUND(AVG(cm.dystopia_compare_score), 2) AS avg_dystopia_score
    FROM 
        ft_country_metrics cm
    LEFT JOIN dim_country dc ON cm.id_country = dc.id_country
    GROUP BY dc.region;

SELECT * 
FROM mv_region_metrics;

----------------------  XML QUERIES ---------------------

-- List UN member countries (org-UN)
SELECT x.country_name, x.memberships
FROM STG_MONDIAL_XML m,
     XMLTABLE(
         '$c//country[contains(string(@memberships), "org-UN")]'
         PASSING m.dados_xml AS "c"
         COLUMNS 
             country_name VARCHAR2(100) PATH 'name[1]',
             memberships  VARCHAR2(500) PATH 'string(@memberships)'
     ) x;



-- Ranking by number of organizations in a country
WITH RankedOrganizationCountries AS (
    SELECT x.country_name,
           REGEXP_COUNT(x.memberships, '[^ ]+') AS num_organizations,
           RANK() OVER (ORDER BY REGEXP_COUNT(x.memberships, '[^ ]+') DESC) AS ranking -- counts a sequence without spaces between
    FROM STG_MONDIAL_XML m,
         XMLTABLE(
             '$doc//country[contains(@memberships, "org-UN")]'
             PASSING m.dados_xml AS "doc"
             COLUMNS 
                 country_name VARCHAR2(100)  PATH 'name[1]',
                 memberships  VARCHAR2(4000) PATH '@memberships'
         ) x
)
SELECT * 
FROM RankedOrganizationCountries
WHERE country_name = 'Brazil'
;

-- Return name and government of countries with unemployment > 20%
SELECT x.country_name, 
       x.government, 
       x.unemployment
FROM STG_MONDIAL_XML m,
     XMLTABLE(
         '$doc//country'
         PASSING m.dados_xml AS "doc"
         COLUMNS 
             country_name VARCHAR2(100) PATH 'name[1]',
             government   VARCHAR2(100) PATH 'government[1]',
             unemployment VARCHAR2(50)  PATH 'unemployment[1]' -- VARCHAR FOR NULL HANDLING (if was number, would occur error)
     ) x
WHERE TO_NUMBER( -- Attempts to convert to null
        x.unemployment DEFAULT NULL ON CONVERSION ERROR, -- HANDLING DIRT AND NULLS! -> CONVERTS TO NULL
        '999.999', 
        'NLS_NUMERIC_CHARACTERS=''.,''' -- AMERICAN STYLE OF DECIMAL
      ) > 20
ORDER BY TO_NUMBER(
        x.unemployment DEFAULT NULL ON CONVERSION ERROR, 
        '999.999', 
        'NLS_NUMERIC_CHARACTERS=''.,'''
      ) DESC
;


-- XMLSerialize: export query result as formatted XML (the first 5 of the XML)
SELECT XMLSERIALIZE(
           CONTENT XMLQUERY(
               '<world_data>
                {
                  for $c in $doc//country[position() <= 5]
                  return 
                    <country>
                      <name>{$c/name/text()}</name>
                      <government>{$c/government/text()}</government>
                    </country>
                }
                </world_data>'
               PASSING m.dados_xml AS "doc"
               RETURNING CONTENT
           ) AS CLOB INDENT SIZE = 2 -- Using CLOB for large XML, just like in python (load_xml.py)
       ) AS formatted_xml
FROM STG_MONDIAL_XML m
;



----------------------  JSON QUERIES (not working)---------------------

-- List countries with air_quality > 100
SELECT 
    jt.country_name,
    ROUND(TO_NUMBER(jt.air_quality DEFAULT NULL ON CONVERSION ERROR, '999999999.999999999999999', 'NLS_NUMERIC_CHARACTERS=''.,'''), 2) AS air_quality_round,
    jt.year
FROM 
  STG_WORLD_BANK swb,
  JSON_TABLE(
      swb.DADOS_JSON,
      '$[*]' -- Go through all elements of the JSON array and transform each one in a line into a virtual table 
      COLUMNS(
        country_name VARCHAR2(120) PATH '$.country.value',
        air_quality VARCHAR2(50)  PATH '$.value',
        year         VARCHAR2(4)   PATH '$.date'
      ) 
  ) jt
WHERE swb.FONTE like '%worldbankAirQualityCountries.json%'
  AND
  ROUND(TO_NUMBER(jt.air_quality DEFAULT NULL ON CONVERSION ERROR, '999999999.999999999999999', 'NLS_NUMERIC_CHARACTERS=''.,'''), 2) > 100
  AND jt.year = '2015';


-- Do the average of precipition by country between 2005 and 2015
SELECT
    jt.country_name,
    -- Dont have any number decimal in precipition(mm) value in json
    ROUND(AVG(TO_NUMBER(jt.precipitation DEFAULT NULL ON CONVERSION ERROR, '99999', 'NLS_NUMERIC_CHARACTERS=''.,''')), 2) AS air_precipitation_round 
FROM 
   STG_WORLD_BANK swb,
   JSON_TABLE(
        swb.DADOS_JSON,
        '$[*]'
    COLUMNS(
       country_name VARCHAR2(120) PATH '$.country.value',
       year         VARCHAR2(4)   PATH '$.date',
       precipitation VARCHAR2(50)  PATH '$.value'
    )
) jt
WHERE swb.FONTE like '%worldbankPrecipitationCountries.json%'
    and
    TO_NUMBER(jt.year DEFAULT NULL ON CONVERSION ERROR, '9999', 'NLS_NUMERIC_CHARACTERS=''.,''') BETWEEN 2005 AND 2015
GROUP BY
    jt.country_name
;


