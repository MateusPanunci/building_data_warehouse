INSERT INTO dim_country (id_country, nm_country, region)
SELECT 
    DIM_COUNTRY_ID_COUNTRY_SEQ.NEXTVAL, 
    data.nm_country, 
    data.region
FROM ( 
    -- Subquery to extract country names and regions
    SELECT DISTINCT 
        xt.nm_country, 
        COALESCE(sh.region, 'N/A') as region
    FROM 
        STG_MONDIAL_XML s,
        XMLTABLE('/mondial/country'
            PASSING s.DADOS_XML
            COLUMNS
                nm_country VARCHAR2(120) PATH 'name[1]' -- Takes the first name
        ) xt
    LEFT JOIN STG_HAPPINESS sh 
        ON UPPER(TRIM(sh.COUNTRY_NAME)) = UPPER(TRIM(xt.nm_country))
    WHERE xt.nm_country IS NOT NULL
) data

