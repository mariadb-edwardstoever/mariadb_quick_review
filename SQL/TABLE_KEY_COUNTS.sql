-- DISTRIBUTED WITH mariadb_quick_review by Edward Stoever for MariaDB Support
-- TABLE_KEY_COUNTS
-- RUN ONE TIME

    SELECT C.`TABLE_SCHEMA`, C.`TABLE_NAME`, T.`ENGINE`,
    IF(SUM(case when C.COLUMN_KEY = 'PRI' then 1 else 0 END)>=1,1,0) AS `PRIMARY_KEY_COUNT`,
    SUM(case when C.COLUMN_KEY = 'UNI' then 1 else 0 END) AS `UNIQUE_KEY_COUNT`,
    SUM(case when C.COLUMN_KEY = 'MUL' then 1 else 0 END) AS `NON_UNIQUE_KEY_COUNT`,
    T.`ROW_FORMAT`, T.`TABLE_ROWS`, T.`AVG_ROW_LENGTH`
    FROM information_schema.`COLUMNS` C
    INNER JOIN information_schema.`TABLES` T
    ON (C.`TABLE_SCHEMA`=T.`TABLE_SCHEMA` AND C.`TABLE_NAME`=T.`TABLE_NAME`)
    WHERE C.`TABLE_SCHEMA` NOT IN ('information_schema','performance_schema','sys','mysql','mariadb_review')
    AND T.TABLE_TYPE='BASE TABLE'
    AND T.`ENGINE` != 'Columnstore'
    GROUP BY C.`TABLE_SCHEMA`, C.`TABLE_NAME`
    ORDER BY TABLE_SCHEMA, TABLE_NAME

