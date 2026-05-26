INSERT INTO dim_sea (id_sea, id_country, nm_sea)
SELECT 
    DIM_SEA_ID_SEA_SEQ.NEXTVAL,
    dc.id_country,
    mar.nm_sea
FROM (
    -- Subquery 1: extracts all seas and their respective country codes
    SELECT 
        xt_sea.nm_sea,
        xt_sea.countries
    FROM 
        STG_MONDIAL_XML s,
        XMLTABLE('/mondial/sea' 
            PASSING s.DADOS_XML
            COLUMNS
                nm_sea    VARCHAR2(60)  PATH 'name[1]',
                countries VARCHAR2(200) PATH '@country'
        ) xt_sea
) mar
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
                car_code   VARCHAR2(10)  PATH '@car_code',
                nm_country VARCHAR2(120) PATH 'name[1]'
        ) xt_cnt
) cxml 
    -- Checks if the country code is in the list of countries that border the sea
    ON INSTR(' ' || UPPER(TRIM(mar.countries)) || ' ', ' ' || UPPER(TRIM(cxml.car_code)) || ' ') > 0
JOIN dim_country dc 
    ON UPPER(TRIM(dc.nm_country)) = UPPER(TRIM(cxml.nm_country));