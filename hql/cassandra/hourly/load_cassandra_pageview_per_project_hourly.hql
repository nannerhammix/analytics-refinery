-- Loading the pageview per_project hourly data to cassandra
-- Parameters:
--     destination_table     -- Cassandra table to write query output.
--     source_table          -- Fully qualified hive table to compute from.
--     year                   -- year of partition to compute from.
--     month                  -- month of partition to compute from.
--     day                    -- day of partition to compute from.
--     hour                   -- hour of partition to compute from.
--     coalesce_partitions    -- number of partitions for destination data.

-- Usage:
-- spark-sql \
-- --driver-cores 1 \
-- --master yarn \
-- --conf spark.sql.catalog.aqs=com.datastax.spark.connector.datasource.CassandraCatalog \
-- --conf spark.sql.catalog.aqs.spark.cassandra.connection.host=aqs1010-a.eqiad.wmnet:9042,aqs1011-a.eqiad.wmnet:9042,aqs1012-a.eqiad.wmnet:9042 \
-- --conf spark.sql.catalog.aqs.spark.cassandra.auth.username=aqsloader \
-- --conf spark.sql.catalog.aqs.spark.cassandra.auth.password=cassandra \
-- --conf spark.sql.catalog.aqs.spark.cassandra.output.batch.size.rows=1024 \
-- --jars /srv/deployment/analytics/refinery/artifacts/org/wikimedia/analytics/refinery/refinery-job-0.2.4-shaded.jar  \
-- --conf spark.dynamicAllocation.maxExecutors=64 \
-- --conf spark.executor.memoryOverhead=2048 \
-- --conf spark.yarn.maxAppAttempts=1 \
-- --executor-memory 8G \
-- --executor-cores 2 \
-- --driver-memory 2G \
-- --name spark_pageview_per_project_hourly \
--     -f load_cassandra_pageview_per_project_hourly.hql \
--     -d destination_table=aqs.local_group_default_T_pageviews_per_project_v2.data \
--     -d source_table=wmf.projectview_hourly  \
--     -d coalesce_partitions=6 \
--     -d year=2022 \
--     -d month=07 \
--     -d day=01  \
--     -d hour=0 \

INSERT INTO ${destination_table}
SELECT
/*+ COALESCE(${coalesce_partitions}) */
    'analytics.wikimedia.org' as _domain,
    COALESCE(regexp_replace(project, ' ', '-'), 'all-projects') as project,
    COALESCE(regexp_replace(access_method, ' ', '-'), 'all-access') as access,
    COALESCE(agent_type, 'all-agents') as agent,
    'hourly' as granularity,
    CONCAT(LPAD(year, 4, '0'), LPAD(month, 2, '0'), LPAD(day, 2, '0'), LPAD(hour, 2, '0')) as timestamp,
    '13814000-1dd2-11b2-8080-808080808080' as _tid,
    SUM(view_count) as v
FROM
    ${source_table}
WHERE
    year = ${year}
    AND month = ${month}
    AND day = ${day}
    AND hour = ${hour}
GROUP BY
    project,
    access_method,
    agent_type,
    year,
    month,
    day,
    hour
GROUPING SETS (
    (
        project,
        access_method,
        agent_type,
        year,
        month,
        day,
        hour
    ),(
        project,
        agent_type,
        year,
        month,
        day,
        hour
    ),(
        project,
        access_method,
        year,
        month,
        day,
        hour
    ),(
        project,
        year,
        month,
        day,
        hour
    ),(
        access_method,
        agent_type,
        year,
        month,
        day,
        hour
    ),(
        agent_type,
        year,
        month,
        day,
        hour
    ),(
        access_method,
        year,
        month,
        day,
        hour
    ),(
        year,
        month,
        day,
        hour
    )
)