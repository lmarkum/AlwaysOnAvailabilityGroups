USE tempdb;
DECLARE @InitialBytesSentValSQLCLSTR_2 TABLE (cntr_value BIGINT)

INSERT INTO @InitialBytesSentValSQLCLSTR_2

SELECT cntr_value
FROM sys.dm_os_performance_counters AS PC
WHERE object_name LIKE '%Availability Replica%' AND counter_name = 'Bytes Sent to Transport/sec' AND  PC.instance_name = 'AG-SQLCLSTR-2:HQ-SQLCLSTR-02\APPS';

WAITFOR DELAY '00:01:00'

DECLARE @SecondBytesSentValSQLCLSTR_2 TABLE (cntr_value BIGINT)

INSERT INTO @SecondBytesSentValSQLCLSTR_2

SELECT PC.cntr_value
FROM sys.dm_os_performance_counters AS PC
WHERE object_name LIKE '%Availability Replica%' AND counter_name = 'Bytes Sent to Transport/sec' AND  PC.instance_name = 'AG-SQLCLSTR-2:HQ-SQLCLSTR-02\APPS';

SELECT CAST((sbsv.cntr_value - ibsv.cntr_value)/1000000 AS DECIMAL(10,2)) AS MegaBytesSentOverNetwork FROM @SecondBytesSentValSQLCLSTR_2 sbsv , @InitialBytesSentValSQLCLSTR_2 ibsv

--------------------
USE tempdb;
DECLARE @InitialBytesSentValSQLCLSTR TABLE (cntr_value BIGINT)

INSERT INTO @InitialBytesSentValSQLCLSTR

SELECT cntr_value
FROM sys.dm_os_performance_counters AS PC
WHERE object_name LIKE '%Availability Replica%' AND counter_name = 'Bytes Sent to Transport/sec' AND  PC.instance_name = 'AG-SQLCLSTR:HQ-SQLCLSTR-02\APPS';

WAITFOR DELAY '00:01:00'

DECLARE @SecondBytesSentValSQLCLSTR TABLE (cntr_value BIGINT)

INSERT INTO @SecondBytesSentValSQLCLSTR

SELECT PC.cntr_value
FROM sys.dm_os_performance_counters AS PC
WHERE object_name LIKE '%Availability Replica%' AND counter_name = 'Bytes Sent to Transport/sec' AND  PC.instance_name = 'AG-SQLCLSTR:HQ-SQLCLSTR-02\APPS';

SELECT CAST((sbsv.cntr_value - ibsv.cntr_value)/1000000 AS DECIMAL(10,2)) AS MegaBytesSentOverNetwork FROM @SecondBytesSentValSQLCLSTR sbsv , @InitialBytesSentValSQLCLSTR ibsv



-------------------

USE tempdb;
DECLARE @InitialBytesSentVal_total TABLE (cntr_value BIGINT)

INSERT INTO @InitialBytesSentVal_total

SELECT cntr_value
FROM sys.dm_os_performance_counters AS PC
WHERE object_name LIKE '%Availability Replica%' AND counter_name = 'Bytes Sent to Transport/sec' AND  PC.instance_name = '_total';


WAITFOR DELAY '00:00:30'

DECLARE @SecondBytesSentVal_total TABLE (cntr_value BIGINT)

INSERT INTO @SecondBytesSentVal_total

SELECT PC.cntr_value
FROM sys.dm_os_performance_counters AS PC
WHERE object_name LIKE '%Availability Replica%' AND counter_name = 'Bytes Sent to Transport/sec' AND  PC.instance_name = '_total';


SELECT CAST((sbsv.cntr_value - ibsv.cntr_value)/1000000 AS DECIMAL(10,2)) AS TotalMegaBytesSentOverNetwork FROM @SecondBytesSentVal_total sbsv , @InitialBytesSentVal_total ibsv

