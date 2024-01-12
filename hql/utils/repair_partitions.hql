-- Repair partitions on a table.
--
-- Parameters:
--     table           -- Fully qualified table name to repair partition.
--
-- Usage:
--     spark3-sql -f repair_partitions.hql \
--         -d table=wmf.webrequest
--

MSCK REPAIR TABLE ${table};
