-- ============================================================
-- Oracle Instance Health Check
-- Author : Manoj
-- Purpose: Quick instance status overview for daily DBA check
-- Usage  : sqlplus / as sysdba @instance_health.sql
-- ============================================================

SET LINESIZE 200
SET PAGESIZE 50
SET FEEDBACK OFF

PROMPT ============================================================
PROMPT  INSTANCE STATUS
PROMPT ============================================================
SELECT
    instance_name,
    host_name,
    version,
    status,
    database_status,
    to_char(startup_time,'DD-MON-YYYY HH24:MI') AS startup_time
FROM v$instance;

PROMPT ============================================================
PROMPT  TABLESPACE USAGE
PROMPT ============================================================
SELECT
    df.tablespace_name,
    round(df.totalspace_mb,0)       AS total_mb,
    round(df.totalspace_mb
          - fs.freespace_mb, 0)     AS used_mb,
    round(fs.freespace_mb,0)        AS free_mb,
    round((1 - fs.freespace_mb
          / df.totalspace_mb)*100,1) AS pct_used
FROM
    (SELECT tablespace_name,
            sum(bytes)/1048576 AS totalspace_mb
     FROM dba_data_files
     GROUP BY tablespace_name) df,
    (SELECT tablespace_name,
            sum(bytes)/1048576 AS freespace_mb
     FROM dba_free_space
     GROUP BY tablespace_name) fs
WHERE df.tablespace_name = fs.tablespace_name
ORDER BY pct_used DESC;

PROMPT ============================================================
PROMPT  TOP 5 WAIT EVENTS (last 1 hour from ASH)
PROMPT ============================================================
SELECT * FROM (
    SELECT
        event,
        count(*) AS ash_samples,
        round(count(*)*100/sum(count(*)) over(),1) AS pct
    FROM v$active_session_history
    WHERE sample_time >= sysdate - 1/24
      AND event IS NOT NULL
    GROUP BY event
    ORDER BY ash_samples DESC
) WHERE rownum <= 5;

PROMPT ============================================================
PROMPT  SESSIONS SUMMARY
PROMPT ============================================================
SELECT
    status,
    type,
    count(*) AS session_count
FROM v$session
GROUP BY status, type
ORDER BY status, type;

SET FEEDBACK ON
