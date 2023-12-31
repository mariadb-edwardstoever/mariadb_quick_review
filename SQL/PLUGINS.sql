-- DISTRIBUTED WITH mariadb_quick_review by Edward Stoever for MariaDB Support
-- PLUGINS

SELECT '$RUNID' as RUN_ID 
    ,PLUGIN_NAME
    ,PLUGIN_VERSION
    ,PLUGIN_STATUS
    ,PLUGIN_TYPE
    ,PLUGIN_TYPE_VERSION
    ,PLUGIN_LIBRARY
    ,PLUGIN_LIBRARY_VERSION
    ,LOAD_OPTION
    ,PLUGIN_MATURITY
    ,PLUGIN_AUTH_VERSION
FROM information_schema.PLUGINS

