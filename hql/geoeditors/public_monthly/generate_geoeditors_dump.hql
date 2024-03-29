-- Query data from the geoeditors public monthly table to be published as a TSV flat file
--
-- Usage:
--     spark-sql -f generate_geoeditors_dump.hql \
--               -d source_table=wmf.geoeditors_public_monthly \
--               -d destination_directory=/wmf/tmp/analytics/geoeditors_public_monthly \
--               -d month=2019-07
--
-- The schema of the file output:
-- `wiki_db`           string    COMMENT 'The wiki database this group of editors worked in',
-- `country_name`      string    COMMENT 'The country this group of editors is geolocated to, including unknown',
-- `activity_level`    string    COMMENT 'How many edits this group of editors performed, can be "5 to 99", or "100 or more"',
-- `editors_floor`     bigint    COMMENT 'At least this many editors at this activity level'
-- `editors_ceil`      bigint    COMMENT 'At most this many editors at this activity level'
--
-- Note: This SQL script only works on Spark 3.X.

INSERT OVERWRITE DIRECTORY "${destination_directory}"
USING CSV
OPTIONS ('header' 'false', 'compression' 'none', 'delimiter' '\t')

    SELECT
    /*+ COALESCE(1) */
        wiki_db,
        country_name,
        activity_level,
        CAST((editors_ceil - 9) AS string),
        CAST(editors_ceil AS string)
    FROM ${source_table}
    WHERE month = '${month}'
;