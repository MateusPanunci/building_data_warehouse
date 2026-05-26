INSERT INTO dim_language (id_country, nm_language)
SELECT DISTINCT 
    dc.id_country,
    COALESCE(xt.nm_language, 'N/A') as nm_language
FROM 
    STG_MONDIAL_XML s,
    XMLTABLE('/mondial/country' 
        PASSING s.DADOS_XML
        COLUMNS
            nm_country VARCHAR2(120) PATH 'name[1]', 
            nm_language  VARCHAR2(120) PATH 'language[1]' -- Takes the language most spoken      
    ) xt
JOIN dim_country dc 
    ON UPPER(TRIM(dc.nm_country)) = UPPER(TRIM(xt.nm_country))
WHERE xt.nm_language IS NOT NULL 
;