INSERT INTO dim_airport (id_airport, id_country, nm_airport)
SELECT 
    DIM_AIRPORT_ID_AIRPORT_SEQ.NEXTVAL,
    dc.id_country,
    COALESCE(air.nm_airport, 'N/A') as nm_airport
FROM (
    -- Subquery 1: extracts all airports and their respective country codes
    SELECT 
        xt_air.country_code,
        xt_air.nm_airport
    FROM 
        STG_MONDIAL_XML s,
        XMLTABLE('/mondial/airport' 
            PASSING s.DADOS_XML
            COLUMNS
                country_code VARCHAR2(10)  PATH '@country', -- Takes the attribute country="AFG"
                nm_airport   VARCHAR2(120) PATH 'name[1]'   -- Takes the airport name 
        ) xt_air
) air
JOIN (
    -- Subquery 2: extracts all countries and their respective country codes
    SELECT 
        xt_cnt.car_code,
        xt_cnt.nm_country
    FROM 
        STG_MONDIAL_XML s,
        XMLTABLE('/mondial/country'
            PASSING s.DADOS_XML
            COLUMNS
                car_code   VARCHAR2(10)  PATH '@car_code', -- Takes car_code="GR", e.g
                nm_country VARCHAR2(120) PATH 'name[1]'
        ) xt_cnt
) cxml ON UPPER(TRIM(air.country_code)) = UPPER(TRIM(cxml.car_code))
JOIN dim_country dc 
    ON UPPER(TRIM(dc.nm_country)) = UPPER(TRIM(cxml.nm_country))
WHERE air.nm_airport IS NOT NULL;
