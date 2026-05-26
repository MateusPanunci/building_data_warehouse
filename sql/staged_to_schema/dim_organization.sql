INSERT INTO dim_organization (id_organization, id_country, nm_organization)
SELECT 
    DIM_ORGANIZATION_ID_ORGANIZ722.NEXTVAL,
    dc.id_country,
    org.nm_organization
FROM (
    -- Subquery 1: Extract the Organization and combine all member country codes into a single space-separated string
    SELECT 
        xt_org.nm_organization,
        xt_org.countries
    FROM 
        STG_MONDIAL_XML s,
        XMLTABLE('/mondial/organization' 
            PASSING s.DADOS_XML
            COLUMNS
                nm_organization VARCHAR2(120)  PATH 'name[1]',
                -- string-join aggregates codes from multiple <members> tags, separating them with a space
                countries       VARCHAR2(4000) PATH 'string-join(members/@country, " ")'
        ) xt_org
) org
JOIN (
    -- Subquery 2: Extract countries and their corresponding codes from the XML structure
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
    -- Match records by checking if the country code is contained within the large member list string
    ON INSTR(' ' || UPPER(TRIM(org.countries)) || ' ', ' ' || UPPER(TRIM(cxml.car_code)) || ' ') > 0
JOIN dim_country dc 
    ON UPPER(TRIM(dc.nm_country)) = UPPER(TRIM(cxml.nm_country));

