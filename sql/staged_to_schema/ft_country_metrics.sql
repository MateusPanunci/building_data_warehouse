INSERT INTO ft_country_metrics (
    id_country, 
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
)
SELECT 
    dc.id_country,
    2015 AS year,
    TO_NUMBER(xml_data.population),
  
    sh.happiness_score,           
    sh.gdp_per_capita,    
    sh.freedom,                   
    sh.corruption_percept,     
    sh.generosity,                
    sh.life_expectancy,    
    sh.social_support,                   
    sh.dystopia_residual,         

    -- Converting to number and replacing '.' with ','
    TO_NUMBER(REPLACE(xml_data.infant_mortality, '.', ',')),
    TO_NUMBER(REPLACE(xml_data.unemployment, '.', ',')),
    TO_NUMBER(REPLACE(xml_data.inflation, '.', ','))
FROM 
    STG_HAPPINESS sh
JOIN dim_country dc 
    ON UPPER(TRIM(dc.nm_country)) = UPPER(TRIM(sh.country_name))
LEFT JOIN (
    SELECT 
        xt.nm_country,
        xt.population,
        xt.infant_mortality,
        xt.unemployment,
        xt.inflation
    FROM 
        STG_MONDIAL_XML s,
        XMLTABLE('/mondial/country'
            PASSING s.DADOS_XML
            COLUMNS
                nm_country       VARCHAR2(120) PATH 'name[1]',
                population       VARCHAR2(50)  PATH 'population[last()]',
                infant_mortality VARCHAR2(50)  PATH 'infant_mortality',
                unemployment     VARCHAR2(50)  PATH 'unemployment',
                inflation        VARCHAR2(50)  PATH 'inflation'
        ) xt
) xml_data ON UPPER(TRIM(xml_data.nm_country)) = UPPER(TRIM(sh.country_name));