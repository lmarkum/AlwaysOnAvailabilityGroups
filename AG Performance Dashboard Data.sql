/*

https://sqlperformance.com/2015/08/monitoring/availability-group-replica-sync
with some changes from Lee Markum
*/

SELECT 
	ar.replica_server_name, 
	adc.database_name, 
	ag.name AS ag_name,
	agl.[dns_name] AS ListenerName,
	agla.state_desc AS AGListenerState,
	drs.is_local, 
	drs.is_primary_replica, 
	drs.synchronization_state_desc, 
	drs.is_commit_participant, 
	drs.synchronization_health_desc, 
	drs.recovery_lsn, 
	drs.truncation_lsn, 
	drs.last_sent_lsn, 
	drs.last_sent_time, 
	drs.last_received_lsn, 
	drs.last_received_time, 
	drs.last_hardened_lsn, 
	drs.last_hardened_time, 
	drs.last_redone_lsn, 
	drs.last_redone_time, 
	drs.log_send_queue_size, 
	drs.log_send_rate, 
	drs.redo_queue_size, 
	drs.redo_rate, 
	drs.filestream_send_rate, 
	drs.end_of_log_lsn, 
	drs.last_commit_lsn, 
	drs.last_commit_time
FROM sys.dm_hadr_database_replica_states AS drs
INNER JOIN sys.availability_databases_cluster AS adc 
	ON drs.group_id = adc.group_id AND 
	drs.group_database_id = adc.group_database_id
INNER JOIN sys.availability_groups AS ag
	ON ag.group_id = drs.group_id
INNER JOIN sys.availability_replicas AS ar 
	ON drs.group_id = ar.group_id AND 
	drs.replica_id = ar.replica_id
LEFT JOIN sys.availability_group_Listeners AS agl 
	ON ag.group_id = agl.group_id
LEFT JOIN sys.availability_group_listener_ip_addresses AS agla 
	ON agl.listener_id = agla.listener_id
ORDER BY 
	ag.name, 
	ar.replica_server_name, 
	adc.database_name;


	SELECT *
	FROM sys.dm_hadr_database_replica_states

	SELECT *
	FROM sys.availability_groups

	SELECT *
	FROM sys.availability_replicas

	SELECT *
	FROM sys.dm_hadr_database_replica_states AS drs
INNER JOIN sys.availability_databases_cluster AS adc 
	ON drs.group_id = adc.group_id AND 
	drs.group_database_id = adc.group_database_id
INNER JOIN sys.availability_groups AS ag
	ON ag.group_id = drs.group_id
INNER JOIN sys.availability_replicas AS ar 
	ON drs.group_id = ar.group_id AND 
	drs.replica_id = ar.replica_id
ORDER BY 
	ag.name, 
	ar.replica_server_name, 
	adc.database_name;


	/*
	Create a View for monitoring or other purposes.
	USE DBA;

GO

CREATE OR ALTER View dbo.AGHealthStatus
AS
SELECT TOP 100 PERCENT
	ar.replica_server_name,
	drs.is_local, 
	drs.is_primary_replica,
	adc.database_name, 
	ag.name AS ag_name,
	agl.[dns_name] AS ListenerName,
	agla.state_desc AS AGListenerState,
	ar.endpoint_url,
	ar.read_only_routing_url,
	ar.availability_mode_desc,
	ar.failover_mode_desc,
	drs.database_state_desc,
	drs.is_suspended,
	drs.suspend_reason_desc,
	drs.synchronization_state_desc, 
	drs.is_commit_participant, 
	drs.synchronization_health_desc, 
	--drs.recovery_lsn, 
	--drs.truncation_lsn, 
	--drs.last_sent_lsn, 
	--drs.last_sent_time, 
	--drs.last_received_lsn, 
	--drs.last_received_time, 
	--drs.last_hardened_lsn, 
	--drs.last_hardened_time, 
	--drs.last_redone_lsn, 
	drs.last_redone_time, 
	drs.log_send_queue_size AS LogSendQueueSize_KB, 
	drs.log_send_rate AS LogSendRate_KB_per_second, 
	drs.redo_queue_size AS RedoQueueSize_KB, 
	drs.redo_rate AS RedoRate_KB_per_second, 
	--drs.filestream_send_rate, 
	--drs.end_of_log_lsn, 
	--drs.last_commit_lsn, 
	drs.last_commit_time
FROM sys.dm_hadr_database_replica_states AS drs
INNER JOIN sys.availability_databases_cluster AS adc 
	ON drs.group_id = adc.group_id AND 
	drs.group_database_id = adc.group_database_id
INNER JOIN sys.availability_groups AS ag
	ON ag.group_id = drs.group_id
INNER JOIN sys.availability_replicas AS ar 
	ON drs.group_id = ar.group_id AND 
	drs.replica_id = ar.replica_id
LEFT JOIN sys.availability_group_Listeners AS agl 
	ON ag.group_id = agl.group_id
LEFT JOIN sys.availability_group_listener_ip_addresses AS agla 
	ON agl.listener_id = agla.listener_id
ORDER BY 
	ag.name, 
	ar.replica_server_name, 
	adc.database_name;

	*/