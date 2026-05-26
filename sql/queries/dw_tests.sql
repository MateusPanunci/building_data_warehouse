SELECT table_name 
FROM user_tables
ORDER BY table_name;


SELECT * FROM STG_HAPPINESS ORDER BY RANK_GERAL;

SELECT COUNTRY_NAME FROM STG_HAPINESS
WHERE HAPINESS_SCORE > 6.1
ORDER BY RANK_GERAL;

SELECT * FROM STG_MONDIAL_XML;

SELECT 
    x.iata, 
    x.pais, 
    x.nome_aeroporto,
    x.lat      AS lat,
    x.lon      AS lon,
    x.elevacao AS elevacao
FROM STG_MONDIAL_XML s,
     XMLTable('/mondial/airport'
         PASSING s.dados_xml
         COLUMNS
             iata           VARCHAR2(10)  PATH '@iatacode',
             pais           VARCHAR2(10)  PATH '@country',
             nome_aeroporto VARCHAR2(200) PATH 'name',
             lat            VARCHAR2(30)  PATH 'latitude',
             lon            VARCHAR2(30)  PATH 'longitude',
             elevacao       VARCHAR2(30)  PATH 'elevation'
     ) x;

