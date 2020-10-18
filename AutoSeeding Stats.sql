declare @current_utc_offset int = (select DATEDIFF(HOUR,GETUTCDATE(),GETDATE()))
declare @start_date date = GETDATE()

select
ag.name,
d.name as database_name, 
dateadd(hour, @current_utc_offset, has.start_time) start_time_local,
dateadd(hour, @current_utc_offset, has.completion_time) completion_time_local,
ar.replica_server_name,
has.operation_id,
has.is_source,
has.current_state,
has.performed_seeding,
has.failure_state,
has.failure_state_desc,
has.error_code,
has.number_of_attempts
from sys.dm_hadr_automatic_seeding has
join sys.databases d on d.group_database_id = has.ag_db_id
join sys.availability_groups ag on ag.group_id = has.ag_id
join sys.availability_replicas ar on ar.replica_id = has.ag_remote_replica_id

where start_time > @start_date
order by ag.name, d.name, has.start_time, has.completion_time


select
pss.local_database_name, 
convert(decimal(17,4),(pss.database_size_bytes / 1073741824.0)) as 'DB size GB',
convert(decimal(17,4),(pss.transferred_size_bytes / 1073741824.0)) as 'txd size GB',
convert(decimal(6,3),(1.0 * pss.transferred_size_bytes / pss.database_size_bytes * 100.0)) as '% complete',
pss.remote_machine_name,
pss.role_desc,
pss.internal_state_desc,
pss.transfer_rate_bytes_per_second,
dateadd(hour, @current_utc_offset, pss.start_time_utc) as start_time_local,
dateadd(hour, @current_utc_offset, pss.end_time_utc) as end_time_local,
dateadd(hour, @current_utc_offset, pss.estimate_time_complete_utc) as estimate_time_complete_local
from sys.dm_hadr_physical_seeding_stats pss
