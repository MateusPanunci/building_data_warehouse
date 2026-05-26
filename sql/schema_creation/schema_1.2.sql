 
CREATE SEQUENCE DIM_COUNTRY_ID_COUNTRY_SEQ;

CREATE TABLE dim_country (
                id_country NUMBER NOT NULL,
                nm_country VARCHAR2(120) NOT NULL,
                region VARCHAR2(60),
                CONSTRAINT DIM_COUNTRY_PK PRIMARY KEY (id_country)
);
COMMENT ON TABLE dim_country IS 'Save the Informations from Countries';
COMMENT ON COLUMN dim_country.id_country IS 'Pk from the countries';


CREATE TABLE dim_language (
                id_country NUMBER NOT NULL,
                nm_language VARCHAR2(60) NOT NULL,
                CONSTRAINT DIM_LANGUAGE_PK PRIMARY KEY (id_country, nm_language)
);
COMMENT ON TABLE dim_language IS 'Save Language names';
COMMENT ON COLUMN dim_language.id_country IS 'Pk from the countries';


CREATE TABLE dim_religion (
                id_country NUMBER NOT NULL,
                nm_religion VARCHAR2(120) NOT NULL,
                CONSTRAINT DIM_RELIGION_PK PRIMARY KEY (id_country, nm_religion)
);
COMMENT ON TABLE dim_religion IS 'Save the Religions names';
COMMENT ON COLUMN dim_religion.id_country IS 'Pk from the countries';


CREATE SEQUENCE DIM_ORGANIZATION_ID_ORGANIZ722;

CREATE TABLE dim_organization (
                id_organization NUMBER NOT NULL,
                id_country NUMBER NOT NULL,
                nm_organization VARCHAR2(120),
                CONSTRAINT DIM_ORG_OK PRIMARY KEY (id_organization, id_country)
);
COMMENT ON TABLE dim_organization IS 'Save the Organizations Informations';
COMMENT ON COLUMN dim_organization.id_organization IS 'Pk from the Organizations';
COMMENT ON COLUMN dim_organization.id_country IS 'Pk from the countries';


CREATE SEQUENCE DIM_AIRPORT_ID_AIRPORT_SEQ;

CREATE TABLE dim_airport (
                id_airport NUMBER NOT NULL,
                id_country NUMBER NOT NULL,
                nm_airport VARCHAR2(120),
                CONSTRAINT DIM_AIRPORT_PK PRIMARY KEY (id_airport)
);
COMMENT ON TABLE dim_airport IS 'Save the Airport Informations';
COMMENT ON COLUMN dim_airport.id_airport IS 'Pk from the Airports';
COMMENT ON COLUMN dim_airport.id_country IS 'Pk from the countries';


CREATE SEQUENCE DIM_SEA_ID_SEA_SEQ;

CREATE TABLE dim_sea (
                id_sea NUMBER NOT NULL,
                id_country NUMBER NOT NULL,
                nm_sea VARCHAR2(60),
                CONSTRAINT DIM_SEA_PK PRIMARY KEY (id_sea, id_country)
);
COMMENT ON TABLE dim_sea IS 'Save the Sea Informations';
COMMENT ON COLUMN dim_sea.id_sea IS 'Pk from the seas';
COMMENT ON COLUMN dim_sea.id_country IS 'Pk from the countries';


CREATE TABLE ft_country_metrics (
                id_country NUMBER NOT NULL,
                year NUMBER NOT NULL,
                population NUMBER,
                happiness_score NUMBER(10,4),
                economy_score NUMBER(10,4),
                freedom_score NUMBER(10,4),
                gov_corruption NUMBER(10,4),
                generosity_score NUMBER(10,4),
                health_score NUMBER(10,4),
                family_score NUMBER(10,4),
                dystopia_compare_score NUMBER(10,4),
                infant_mortality_pct NUMBER(10,4),
                unemployment_pct NUMBER(10,4),
                inflation_pct NUMBER(10,4),
                CONSTRAINT FT_COUNTRY_METRICS_PK PRIMARY KEY (id_country, year)
);
COMMENT ON TABLE ft_country_metrics IS 'Save socieconomic data from the countries';
COMMENT ON COLUMN ft_country_metrics.id_country IS 'Pk from the countries';
COMMENT ON COLUMN ft_country_metrics.economy_score IS 'The extent to which GDP contributes to the calculation of the Happiness Score';
COMMENT ON COLUMN ft_country_metrics.freedom_score IS 'The extent to which Freedom contributed to the calculation of the Happiness Score.';
COMMENT ON COLUMN ft_country_metrics.gov_corruption IS 'The extent to which Perception of Corruption contributes to Happiness Score.';
COMMENT ON COLUMN ft_country_metrics.health_score IS 'The extent to which Life expectancy contributed to the calculation of the Happiness Score';
COMMENT ON COLUMN ft_country_metrics.family_score IS 'The extent to which Family contributes to the calculation of the Happiness Score';
COMMENT ON COLUMN ft_country_metrics.dystopia_compare_score IS 'The extent to which Dystopia Residual contributed to the calculation of the Happiness Score. Which higher the score, better it is.';


CREATE TABLE ft_weather_metrics (
                id_country NUMBER NOT NULL,
                year NUMBER NOT NULL,
                avg_air_quality NUMBER(10,4),
                avg_precipitation NUMBER,
                CONSTRAINT FT_WEATHER_PK PRIMARY KEY (id_country, year)
);
COMMENT ON TABLE ft_weather_metrics IS 'Save historical whether mesaurements Informations from the countries (air_quality and precipition)';
COMMENT ON COLUMN ft_weather_metrics.id_country IS 'Pk from the countries';
COMMENT ON COLUMN ft_weather_metrics.avg_air_quality IS 'Air pollution, mean annual exposure (micrograms per cubic meter)';
COMMENT ON COLUMN ft_weather_metrics.avg_precipitation IS 'Average precipitation in depth (mm per year)';


ALTER TABLE ft_weather_metrics ADD CONSTRAINT FK_COUNTRY_WEATHER
FOREIGN KEY (id_country)
REFERENCES dim_country (id_country)
NOT DEFERRABLE;

ALTER TABLE ft_country_metrics ADD CONSTRAINT FK_COUNTRY_METRICS
FOREIGN KEY (id_country)
REFERENCES dim_country (id_country)
NOT DEFERRABLE;

ALTER TABLE dim_sea ADD CONSTRAINT FK_COUNTRY_SEA
FOREIGN KEY (id_country)
REFERENCES dim_country (id_country)
NOT DEFERRABLE;

ALTER TABLE dim_airport ADD CONSTRAINT FK_COUNTRY_AIRPORT
FOREIGN KEY (id_country)
REFERENCES dim_country (id_country)
NOT DEFERRABLE;

ALTER TABLE dim_organization ADD CONSTRAINT FK_COUNTRY_ORG
FOREIGN KEY (id_country)
REFERENCES dim_country (id_country)
NOT DEFERRABLE;

ALTER TABLE dim_religion ADD CONSTRAINT DIM_COUNTRY_DIM_RELIGION_FK
FOREIGN KEY (id_country)
REFERENCES dim_country (id_country)
NOT DEFERRABLE;

ALTER TABLE dim_language ADD CONSTRAINT DIM_COUNTRY_DIM_LANGUAGE_FK
FOREIGN KEY (id_country)
REFERENCES dim_country (id_country)
NOT DEFERRABLE;