USE tempdb;
DECLARE @InitialFlowControlVal TABLE (cntr_value BIGINT)

INSERT INTO @InitialFlowControlVal

SELECT cntr_value
FROM sys.dm_os_performance_counters AS PC
WHERE object_name LIKE '%Availability Replica%' AND counter_name = 'Flow control/sec' AND  PC.instance_name = '_Total';

WAITFOR DELAY '00:00:10'

DECLARE @SecondFlowControlVal TABLE (cntr_value BIGINT)

INSERT INTO @SecondFlowControlVal

SELECT PC.cntr_value
FROM sys.dm_os_performance_counters AS PC
WHERE object_name LIKE '%Availability Replica%' AND counter_name = 'Flow control/sec' AND  PC.instance_name = '_Total';

SELECT (sfcv.cntr_value - ifcv.cntr_value) AS [Flow Control per Second] FROM @SecondFlowControlVal sfcv , @InitialFlowControlval ifcv
