-- Extracts one day of formatted sampled webrequest to be loaded in Druid
--
-- Usage:
--     spark-sql -f generate_daily_druid_webrequests.hql \
--         -d source_table=wmf.webrequest \
--         -d destination_table=tmp_daily_druid_webrequests_2023_01_01 \
--         -d destination_directory=/wmf/tmp/druid/daily_json_webrequests \
--         -d coalesce_partitions=64 \
--         -d year=2023 \
--         -d month=1 \
--         -d day=1
--


DROP TABLE IF EXISTS ${destination_table};


CREATE TABLE IF NOT EXISTS ${destination_table} (
    `dt`                         string,
    `webrequest_source`          string,
    `hostname`                   string,
    `time_firstbyte`             string,
    `aggregated_time_firstbyte`  double,
    `ip`                         string,
    `http_status`                string,
    `cache_status`               string,
    `response_size`              string,
    `aggregated_response_size`   bigint,
    `http_method`                string,
    `uri_host`                   string,
    `uri_path`                   string,
    `uri_query`                  string,
    `content_type`               string,
    `referer`                    string,
    `user_agent`                 string,
    `client_port`                string,
    `x_cache`                    string,
    `continent`                  string,
    `country_code`               string,
    `isp`                        string,
    `as_number`                  string,
    `is_pageview`                boolean,
    `is_debug`                   boolean,
    `tls_version`                string,
    `tls_key_exchange`           string,
    `tls_auth`                   string,
    `tls_cipher`                 string,
    `is_from_public_cloud`       boolean,
    `requestctl`                 string,
    `hits`                       bigint
)
USING PARQUET
OPTIONS ('compression'='gzip')
LOCATION '${destination_directory}';


WITH filtered_data AS (
    SELECT
        dt,
        webrequest_source,
        hostname,
        time_firstbyte,
        time_firstbyte as aggregated_time_firstbyte,
        ip,
        http_status,
        cache_status,
        response_size,
        response_size as aggregated_response_size,
        http_method,
        uri_host,
        uri_path,
        uri_query,
        content_type,
        referer,
        user_agent,
        x_analytics_map['client_port'] as client_port,
        x_cache,
        geocoded_data['continent'] as continent,
        geocoded_data['country_code'] as country_code,
        isp_data['isp'] as isp,
        isp_data['autonomous_system_number'] as as_number,
        is_pageview,
        coalesce(x_analytics_map['debug'], '0') = '1' as is_debug,
        tls_map['vers'] as tls_version,
        tls_map['keyx'] as tls_key_exchange,
        tls_map['auth'] as tls_auth,
        tls_map['ciph'] as tls_cipher,
        coalesce(x_analytics_map['public_cloud'], '0') = '1' as is_from_public_cloud,
        x_analytics_map['requestctl'] as requestctl,
        count(1) as hits
    FROM ${source_table}
    WHERE year = ${year}
        AND month = ${month}
        AND day = ${day}
        AND dt IS NOT NULL
        AND dt != '-'
    GROUP BY
        dt,
        webrequest_source,
        hostname,
        time_firstbyte,
        aggregated_time_firstbyte,
        ip,
        http_status,
        cache_status,
        response_size,
        aggregated_response_size,
        http_method,
        uri_host,
        uri_path,
        uri_query,
        content_type,
        referer,
        user_agent,
        x_analytics_map['client_port'],
        x_cache,
        geocoded_data['continent'],
        geocoded_data['country_code'],
        isp_data['isp'],
        isp_data['autonomous_system_number'],
        is_pageview,
        coalesce(x_analytics_map['debug'], '0') = '1',
        tls_map['vers'],
        tls_map['keyx'],
        tls_map['auth'],
        tls_map['ciph'],
        x_analytics_map['requestctl'],
        coalesce(x_analytics_map['public_cloud'], '0') = '1'
)

INSERT OVERWRITE TABLE ${destination_table}
SELECT /*+ COALESCE(${coalesce_partitions}) */ *
FROM filtered_data TABLESAMPLE (BUCKET 1 OUT OF 128);
