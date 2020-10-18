
/*https://docs.microsoft.com/en-us/sql/relational-databases/performance-monitor/sql-server-database-replica?view=sql-server-2017
https://logicalread.com/sql-server-perf-counters-database-mirroring-tl01/#.WvMdkIgvyUk

Perfmon counters for monitoring the log and redo processes.
*/
/*Mirrored Write Transactions/sec

Number of transactions that were written to the primary database and then waited to commit until the log was sent to the secondary database, in the last second.

*/
SELECT cntr_value
FROM sys.dm_os_performance_counters AS Perf
WHERE perf.counter_name LIKE 'Mirrored Write Transactions/sec%'
AND Perf.Instance_Name = '_Total' 
AND Perf.object_name LIKE '%Database Replica%'


/*
Log Send Queue

Amount of log records in the log files of the primary database, in kilobytes, that has not yet been sent to the secondary replica. 
This value is sent to the secondary replica from the primary replica. 
Queue size does not include FILESTREAM files that are sent to a secondary.
*/
SELECT cntr_value
FROM sys.dm_os_performance_counters AS Perf
WHERE perf.counter_name LIKE 'Log Send Queue'
AND Perf.object_name LIKE '%Database Replica%'

/*
Recovery Queue

Amount of log records in the log files of the secondary replica that has not yet been redone.
*/
SELECT cntr_value
FROM sys.dm_os_performance_counters AS Perf
WHERE perf.counter_name LIKE 'Recovery Queue'
AND Perf.object_name LIKE '%Database Replica%'

