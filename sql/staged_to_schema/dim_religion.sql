INSERT INTO dim_religion (id_country, nm_religion)
SELECT DISTINCT 
    dc.id_country,
    COALESCE(xt.nm_religion, 'N/A') as nm_religion
FROM 
    STG_MONDIAL_XML s,
    XMLTABLE('/mondial/country' 
        PASSING s.DADOS_XML
        COLUMNS
            nm_country VARCHAR2(120) PATH 'name[1]', 
            nm_religion  VARCHAR2(120) PATH 'religion[1]'  -- Takes the religion most followed       
    ) xt
JOIN dim_country dc 
    ON UPPER(TRIM(dc.nm_country)) = UPPER(TRIM(xt.nm_country))
WHERE xt.nm_religion IS NOT NULL


