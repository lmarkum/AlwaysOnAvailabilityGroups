

SELECT *
FROM sys.dm_os_performance_counters
WHERE object_name LIKE '%Availability%' --Counter_name LIKE '%flow%'


SELECT *
FROM sys.dm_os_performance_counters AS PC
WHERE object_name LIKE '%Availability Replica%' AND counter_name = 'flow control/sec'

USE tempdb;
DECLARE @InitialBytesSentVal TABLE (cntr_value BIGINT)

INSERT INTO @InitialBytesSentVal

SELECT cntr_value
FROM sys.dm_os_performance_counters AS PC
WHERE object_name LIKE '%Availability Replica%' AND counter_name = 'Bytes Sent to Replica/sec' AND  PC.instance_name = 'AG-SQLCLSTR-2:HQ-SQLCLSTR-02\APPS';

WAITFOR DELAY '00:01:00'

DECLARE @SecondBytesSentVal TABLE (cntr_value BIGINT)

INSERT INTO @SecondBytesSentVal

SELECT PC.cntr_value
FROM sys.dm_os_performance_counters AS PC
WHERE object_name LIKE '%Availability Replica%' AND counter_name = 'Bytes Sent to Replica/sec' AND  PC.instance_name = 'AG-SQLCLSTR-2:HQ-SQLCLSTR-02\APPS';

SELECT sbsv.cntr_value - ibsv.cntr_value FROM @SecondBytesSentVal sbsv , @InitialBytesSentVal ibsv

SELECT *
FROM sys.dm_os_performance_counters AS PC
WHERE object_name LIKE '%Availability Replica%' AND counter_name = 'Bytes Sent to Replica/sec' AND  PC.instance_name = 'AG-SQLCLSTR:HQ-SQLCLSTR-02\APPS';

















