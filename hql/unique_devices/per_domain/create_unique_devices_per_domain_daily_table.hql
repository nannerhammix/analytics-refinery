-- Create table statement for unique devices per domain daily table.
--
-- Usage
--     spark-sql -f create_unique_devices_per_domain_daily_table.hql \
--         --database wmf \
--         -d location=/wmf/data/wmf/unique_devices/per_domain/daily


CREATE EXTERNAL TABLE IF NOT EXISTS `unique_devices_per_domain_daily`(
    `domain`                 string  COMMENT 'The lower cased domain defining a project (en.wikipedia.org for instance)',
    `country`                string  COMMENT 'Country name of the accessing agents (computed using maxmind GeoIP database)',
    `country_code`           string  COMMENT '2 letter country code',
    `uniques_underestimate`  int     COMMENT 'Under estimation of unique devices seen based on last access cookie, and the nocookies header',
    `uniques_offset`         int     COMMENT 'Unique devices offset computed as 1-action sessions without cookies',
    `uniques_estimate`       int     COMMENT 'Estimate of unique devices seen as uniques_underestimate plus offset'
)
PARTITIONED BY (
    `year`              int     COMMENT 'Unpadded year of requests',
    `month`             int     COMMENT 'Unpadded month of requests',
    `day`               int     COMMENT 'Unpadded day of requests'
)
STORED AS PARQUET
LOCATION '${location}'
;
