/*
I believe this is code written by Tom Willwerth while he was a consultant at StraightPathSQL.

*/
--Create tables for AG synchronization processes

USE [DBA]
GO

/****** Object:  Table [dbo].[ddl_log]    Script Date: 1/14/2019 12:51:46 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ddl_log](
	[ServerName] [nvarchar](50) NULL,
	[DatabaseName] [nvarchar](255) NULL,
	[PostTime] [datetime] NULL,
	[LoginName] [nvarchar](255) NULL,
	[DB_User] [nvarchar](100) NULL,
	[SPID] [nvarchar](20) NULL,
	[Event_Type] [nvarchar](100) NULL,
	[TSQL] [nvarchar](2000) NULL
) ON [PRIMARY]
GO


USE [DBA]
GO

/****** Object:  Table [dbo].[Job_sync_Exceptions]    Script Date: 1/14/2019 12:51:51 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Job_sync_Exceptions](
	[RecID] [int] IDENTITY(1,1) NOT NULL,
	[JobName] [varchar](max) NULL,
	[DateTimeAdded] [datetime] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO


USE [DBA]
GO

/****** Object:  Table [dbo].[Job_Sync_Log]    Script Date: 1/14/2019 12:51:55 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Job_Sync_Log](
	[RecID] [int] IDENTITY(1,1) NOT NULL,
	[Servername] [varchar](255) NULL,
	[JobName] [varchar](max) NULL,
	[JobOwner] [varchar](255) NULL,
	[JobCreateDate] [datetime] NULL,
	[JobModifyDate] [datetime] NULL,
	[CaptureDateTime] [datetime] NULL,
	[TheAction] [varchar](10) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO


USE [DBA]
GO

/****** Object:  Table [dbo].[LoginSync_Log]    Script Date: 1/14/2019 12:51:59 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[LoginSync_Log](
	[RecID] [int] IDENTITY(1,1) NOT NULL,
	[ServerName] [varchar](255) NULL,
	[loginName] [varchar](255) NULL,
	[sid] [varbinary](85) NULL,
	[CreateScript] [varchar](max) NULL,
	[CaptureDateTime] [datetime] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [dbo].[LoginSync_Log] ADD  CONSTRAINT [DF_LoginSync_Log_CaptureDateTime]  DEFAULT (getdate()) FOR [CaptureDateTime]
GO



--Create stored procedures for synchronization processes

USE [DBA]
GO

/****** Object:  StoredProcedure [dbo].[CheckJobSync_New]    Script Date: 1/14/2019 12:49:23 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




-- Find Primary And set that in the first and then use secondary for the second query
--The following will be Passed in once create SP
CREATE procedure [dbo].[CheckJobSync_New]

 
 @recipients as nvarchar(max),
 @JobFreq as int = 0 


 AS   --- 

Declare @SQL nvarchar(max)
Declare @TheCount int
Declare @CurrentServer varchar(255)
Declare @LinkedServer varchar(255)
Declare @TheDiffMax int
Declare @TheCurrentDatatime Datetime
DECLARE @tableHTML  NVARCHAR(MAX) 
--Declare @recipients as nvarchar(max)
Declare @Subject as nvarchar(1000)
Declare @JobChangeTime as datetime
Declare @ServerList as table (RecID int IDENTITY (1,1),
							 ServerName varchar(255))
Declare @ServerTotal int
Declare @RecID varchar(100)
Declare @ReplicaServerList as varchar(max)


-- Get list of all the Replicas and use them to do the compare
	insert into @ServerList  (Servername)
		select distinct replica_server_name from sys.availability_replicas
				where replica_server_name <> @@SERVERNAME


set @TheCurrentDatatime = getdate()


-- Now create the Tables with the jobs for each of the servers.
-- First get how many servers (nodes) 
set @ServerTotal = (select count(*) from @ServerList) 

-- Now create tables for each server with there job Information. 

-- Create a globle temptable to use 
IF OBJECT_ID('tempdb.dbo.##TheCurrentJobs', 'U') IS NOT NULL
  DROP TABLE ##TheCurrentJobs; 
create table  ##TheCurrentJobs  (RecID int IDENTITY (1,1),
							 ServerName varchar(255),
							 JobName varchar(255),
							 JobOwner varchar(255),
							 JobCreateDate datetime,
							 JobLastModDate datetime,
							 Linked bit
							 )
-- For the the linked servers other nodes I will loop through the list and create them 

set @Recid = 1 
While @ReciD <= @ServerTotal
	begin
		-- Frist get the table name to check for and to create
		set @LinkedServer = (select Servername from @ServerList where RecID = @RecID)
						 -- Create a globle temptable to use 
		Set @SQL = 'IF OBJECT_ID(''tempdb.dbo.##TheLinkedSJobs_' + @RecID + ''', ''U'') IS NOT NULL
			DROP TABLE ##TheLinkedSJobs_' + @RecID  ; 
			print @SQL
			exec (@SQL)
		set @SQL = '	create table  ##TheLinkedSJobs_' + @RecID + '  (RecID int IDENTITY (1,1),
							 ServerName varchar(255),
							 JobName varchar(255),
							 JobOwner varchar(255),
							 JobCreateDate datetime,
							 JobLastModDate datetime,
							 Linked bit
							 )' 
			print @SQL 
			exec (@SQL)

		set @RecID = @RecID + 1
	end 


-- Only need one Diff table. 
-- Create a globle temptable to use 
IF OBJECT_ID('tempdb.dbo.##TheDiffJobs', 'U') IS NOT NULL
  DROP TABLE ##TheDiffJobs; 
create table  ##TheDiffJobs  (RecID int IDENTITY (1,1),
							 ServerName varchar(255),
							 JobName varchar(255),
							 JobOwner varchar(255),
							 JobCreateDate datetime,
							 JobLastModDate datetime,
							 Linked bit,
							 TheAction varchar(10)
							 )

--For testing
--set @Server1 = 'HQ-DBADEVSQL-01'
--set @Server2 = 'HQ-DBADEVSQL-02'

set @CurrentServer = @@SERVERNAME




--
print @CurrentServer
print @LinkedServer


--Get the Logins from CurrentServer to be able to compare
Insert into ##TheCurrentJobs (JobName,JobCreateDate,JobLastModDate,JobOwner,Linked)
SELECT 	
				[JobName] = [jobs].[name],
				jobs.date_created,
		jobs.date_modified as Last_Modified
		,(select name from master.sys.syslogins where sid = owner_sid) as JobOwner , 0
FROM	 [msdb].[dbo].[sysjobs] AS [jobs] WITh(NOLOCK)
where jobs.name not in (select JobName from dba.dbo.JOb_sync_Exceptions )
 
		

-- Now load the linked servers. 
-- Get the Logins from LinkedServer to be able to compare -- This now will loop through since there could be more than one node. 
set @ReplicaServerList = ''
set @RecID = 1 

While @RecID <= @ServerTotal
	begin
		set @LinkedServer = (select Servername from @ServerList where RecID = @RecID)
		
		set @SQL = 'insert into ##TheLinkedSJobs_' + @RecID + ' (JobName,JobCreateDate,JobLastModDate,JobOwner,Linked)
				SELECT 	
				[JobName] = [jobs].[name],
				jobs.date_created
				,jobs.date_modified as Last_Modified
				,(select name from master.sys.syslogins where sid = owner_sid) as JobOwner ,1
				FROM [' + @LinkedServer + '].[msdb].[dbo].[sysjobs] AS [jobs]  '

		print @SQL
		execute(@SQL)
		set @RecID = @RecID + 1
		set @ReplicaServerList =  @LinkedServer + ',' + @ReplicaServerList  
		print 'Did the Execute'
	end 


-- Now loop through each of the nodes and see if there is any jobs on this current server

set @RecID = 1 

While @RecID <= @ServerTotal
	begin 
		set @TheDiffMax = isnull((select max(RecID) from ##TheDiffJobs),0)

		set @LinkedServer = (select servername from @ServerList where RecID = @RecID)
		-- The Linked Server
		set @SQL = 	' insert into ##TheDiffJobs (JobName)
		select JobName from  ##TheCurrentJobs
		Except 
		select JobName from ##TheLinkedSJobs_' + @RecID + ''
		print @SQL 
		Exec (@SQL)

		--UPdate with the server name
		update ##TheDiffJobs 
		set ServerName = @LinkedServer
		where RecID > @TheDiffMax 

		set @RecID = @RecId + 1 

	end 

	
Update ##TheDiffJobs 
set ServerName = @CurrentServer
-- now update ##TheDiffJob with other information

update ##TheDiffJobs 
set JobOwner = Jobs.JobOwner, 
	JobCreateDate = jobs.JobCreateDate,
	JobLastModDate = jobs.JobLastModDate,
	TheAction = 'New'
from ##TheDiffJobs DiffJobs inner join ##TheCurrentJobs Jobs on 
	DiffJobs.JobName = jobs.JobName
	where diffjobs.ServerName = @CurrentServer
	
-- check to see if there is any jobs that have been changed in the last Time frame.
	
-- Set the time to look at
set @JobFreq = @JobFreq * -1
set @JobChangeTime = DATEADD(minute, @JobFreq, @TheCurrentDatatime)  

-- Insert into the ##Diff table 
Insert into ##TheDiffJobs (servername,JobName,JobOwner,JobCreateDate,JobLastModDate,TheAction)
select @CurrentServer,Jobname,JobOwner,JobCreateDate,JobLastModDate ,'Change'
from ##TheCurrentJobs
where JobLastModDate >= @JobChangeTime



-- Now load this to a table and then send a email with this information 

Insert into dba..Job_Sync_Log ( ServerName,JobName,CaptureDateTime,JobCreateDate,JobModifyDate,JobOwner,TheAction)
select distinct ServerName,JobDiff.JobName ,@TheCurrentDatatime, JobCreateDate , JobLastModDate ,JobOwner,TheAction
			from ##TheDiffJobs jobDiff 
-- Now send out the report 

If (select count(*) from ##TheDiffJobs) > 0 
begin 

Set  @Subject = 'Job Sync Report - A new Job has been added Or Modified' 
--set @recipients = 'mmyatt@RDX.com'

SET @tableHTML =  
    N'Please Add or Compare the Following Jobs on the following Servers: ' + @ReplicaServerList + ' ' +  
	N'<H1>Job Sync Report</H1>' +  
    N'<table border="1">' +  
    N'<tr><th>Server Name</th><th>Job Name</th>' +  
	N'<th>Job Owner</th>' +
    N'<th>Job Create Date</th><th>Job Last Modifed Date</th><th>Capture DateTime</th><th>Action</th>' +  
    CAST ( ( SELECT td = ServerName,       '',  
                    td = Jobname, '',  
                    td = JobOwner, '',  
                    td = JobCreateDate, '',  
					td = JobModifyDate, '',  
                    td = CaptureDateTime, ''  ,
					td = TheAction, ''  
              FROM DBA..Job_Sync_Log 
			  where CaptureDateTime = @TheCurrentDatatime
              FOR XML PATH('tr'), TYPE   
    ) AS NVARCHAR(MAX) ) +  
    N'</table>' ;  

EXEC msdb.dbo.sp_send_dbmail @profile_name = @profile_name, @recipients= @recipients,
    @subject = @Subject,  
    @body = @tableHTML,  
    @body_format = 'HTML' ;  
End
--sp_help_revlogin 'HUNTER-ENG\tdoctorman'
-- compare and if finds any differance then insert into table to be able to report off it. 

GO


USE [DBA]
GO

/****** Object:  StoredProcedure [dbo].[CheckLoginsSync_New]    Script Date: 1/14/2019 12:49:26 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



-- Find Primary And set that in the first and then use secondary for the second query
--The following will be Passed in once create SP
CREATE procedure [dbo].[CheckLoginsSync_New]

 @recipients as varchar(max) = 'DBA@Hunter.coom'

 AS   --- 

Declare @SQL nvarchar(max)
Declare @TheCount int
Declare @CurrentServer varchar(255)
Declare @LinkedServer varchar(255)
Declare @TheDiffMax int
Declare @TheCurrentDatatime Datetime
DECLARE @tableHTML  NVARCHAR(MAX) 
--Declare @recipients as nvarchar(max)
Declare @Subject as nvarchar(1000)
Declare @ServerList as table (RecID int IDENTITY (1,1),
							 ServerName varchar(255))
Declare @ServerTotal int
Declare @RecID varchar(100)
Declare @ReplicaServerList as varchar(max)

-- Get list of all the Replicas and use them to do the compare
	insert into @ServerList  (Servername)
	select distinct replica_server_name from sys.availability_replicas
				where replica_server_name <> @@SERVERNAME
    
	select * from @ServerList
-- First get how many servers (nodes) 
set @ServerTotal = (select count(*) from @ServerList) 
set @TheCurrentDatatime = getdate()
Print 'The Server Total:'
print @ServerTotal
print '-----'
-- Create a globle temptable to use 
IF OBJECT_ID('tempdb.dbo.##TheCurrentLogins', 'U') IS NOT NULL
  DROP TABLE ##TheCurrentLogins; 
create table  ##TheCurrentLogins  (RecID int IDENTITY (1,1),
							 LoginName varchar(255),
							 sid varbinary(85),
							 )

							 -- Create a globle temptable to use 

set @Recid = 1 
While @ReciD <= @ServerTotal
	begin
		-- Frist get the table name to check for and to create
		set @LinkedServer = (select Servername from @ServerList where RecID = @RecID)
						 -- Create a globle temptable to use 
		Set @SQL = 'IF OBJECT_ID(''tempdb.dbo.##TheLinkedSLogins_' + @RecID + ''', ''U'') IS NOT NULL
			DROP TABLE ##TheLinkedSLogins_' + @RecID  ; 
			print @SQL
			exec (@SQL)
		set @SQL = '	create table  ##TheLinkedSLogins_' + @RecID + '  (RecID int IDENTITY (1,1),
							 LoginName varchar(255),
							 sid varbinary(85),
							 )' 
			print @SQL 
			exec (@SQL)

		set @RecID = @RecID + 1
	end 

-- Create a globle temptable to use 
IF OBJECT_ID('tempdb.dbo.##TheDiffLogins', 'U') IS NOT NULL
  DROP TABLE ##TheDiffLogins; 
create table  ##TheDiffLogins  (RecID int IDENTITY (1,1),
							 ServerName varchar(255),
							 LoginName varchar(255),
							 sid varbinary(85),
							 )

--For testing
--set @Server1 = 'HQ-DBADEVSQL-01'
--set @Server2 = 'HQ-DBADEVSQL-02'

set @CurrentServer = @@SERVERNAME



---- Check to see if @Server1 or @Server2 is current or linked.
--If @Server1 = @CurrentServer 
--	begin 
--		set @LinkedServer = @Server2
--	end 
--If @Server2 = @CurrentServer
--	begin 
--		set @LinkedServer = @Server1
--	end 


--
print @CurrentServer
print @LinkedServer


--Get the Logins from CurrentServer to be able to compare
Insert into ##TheCurrentLogins (LoginName,Sid)
	SELECT name, sid FROM master.sys.syslogins 
	where name not like '##%'

-- Get the Logins from LinkedServer to be able to compare
set @RecID = 1 

While @RecID <= @ServerTotal
	begin
		set @LinkedServer = (select Servername from @ServerList where RecID = @RecID)
		
		set @SQL = 'insert into ##TheLinkedSLogins_' + @RecID + ' (LoginName,Sid)
				SELECT name, sid FROM [' + @LinkedServer + '].master.sys.syslogins where name not like ''##%'' '

		print @SQL
		execute(@SQL)
		set @RecID = @RecID + 1
		set @ReplicaServerList =  @LinkedServer + ',' + @ReplicaServerList  
		print 'Did the Execute'
	end 
	--SELECT name, sid FROM [HQ-DBADEVSQL-02].master.sys.syslogins where name not like '##%' 
	--select * from ##TheLinkedSlogins_1
--The Current server



-- The Linked Server
-- Now loop through each of the nodes and see if there is any logins on this current server

set @RecID = 1 

While @RecID <= @ServerTotal
	begin 
		set @TheDiffMax = isnull((select max(RecID) from ##TheDiffLogins),0)

		set @LinkedServer = (select servername from @ServerList where RecID = @RecID)
		-- The Linked Server
		set @SQL = 	' insert into ##TheDiffLogins (LoginName,sid)
		select LoginName,sid from  ##TheCurrentLogins
		Except 
		select LoginName,sid from ##TheLinkedSLogins_' + @RecID + ''
		print @SQL 
		Exec (@SQL)

		--UPdate with the server name
		update ##TheDiffLogins 
		set ServerName = @LinkedServer
		where RecID > @TheDiffMax 

		set @RecID = @RecId + 1 

	end 

	

-- Now load this to a table and then send a email with this information 

Insert into dba..LoginSync_Log ( ServerName,LoginName,Sid,CreateSCript,CaptureDateTime)
select ServerName,LoginName,sid ,'exec sp_help_revlogin ''' + LoginName + '''' as CreateLogin, @TheCurrentDatatime from ##TheDiffLogins

select * from ##TheDifflogins
-- Now send out the report 

If (select count(*) from ##TheDiffLogins) > 0 
begin 

Set  @Subject = 'Login Sync Report - A new login has been added' 


SET @tableHTML =  
    N'The Logins from ' + @CurrentServer + 
	N'<H1>Login Sync Report</H1>' +  
    N'<table border="1">' +  
    N'<tr><th>Apply Server </th><th>Login Name</th>' +  
    N'<th>Sid</th><th>Run on ' + @CurrentServer + '</th><th>Capture DateTime</th>' +  
    CAST ( ( SELECT td = ServerName,       '',  
                    td = LoginName, '',  
                    td = Sid, '',  
                    td = CreateScript, '',  
                    td = CaptureDateTime, ''  
              FROM DBA..LoginSync_Log 
			  where CaptureDateTime = @TheCurrentDatatime
              FOR XML PATH('tr'), TYPE   
    ) AS NVARCHAR(MAX) ) +  
    N'</table>' ;  

EXEC msdb.dbo.sp_send_dbmail @recipients= @recipients,
    @subject = @Subject,  
    @body = @tableHTML,  
    @body_format = 'HTML' ;  
End
--sp_help_revlogin 'HUNTER-ENG\tdoctorman'
-- compare and if finds any differance then insert into table to be able to report off it. 

GO



--Create SQL Agent jobs for AG synchronization processes

USE [msdb]
GO

/****** Object:  Job [Maintenance Login Sync]    Script Date: 1/14/2019 1:02:33 PM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 1/14/2019 1:02:33 PM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Maintenance Login Sync', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'This is to run once a day to send the Login Sync Report if there is any to be updated.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'HUNTER-ENG\sqlsupport', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Run Login Sync Report]    Script Date: 1/14/2019 1:02:33 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Run Login Sync Report', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'execute DBA.dbo.CheckLoginsSync_New @recipients =  ''DBA@hunter.com;mmyatt@rdx.com''', 
		@database_name=N'DBA', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Daily', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=62, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20181106, 
		@active_end_date=99991231, 
		@active_start_time=80000, 
		@active_end_time=235959, 
		@schedule_uid=N'b5f7fc27-bde7-4acf-ad0b-b94cf1791aaf'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO


USE [msdb]
GO

/****** Object:  Job [Maintenance Job Sync Check]    Script Date: 1/14/2019 1:04:26 PM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 1/14/2019 1:04:26 PM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Maintenance Job Sync Check', 
		@enabled=1, 
		@notify_level_eventlog=2, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'This job will run on each node of the Always on Cluster and It will then will run on a scheduled to check the sync status of the jobs.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'DBA', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Check the Job sync]    Script Date: 1/14/2019 1:04:26 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Check the Job sync', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXECUTE  [dbo].[CheckJobSync_New] 
   @recipients = ''DBA@hunter.com;mmyatt@RDX.com''
  ,@JobFreq = ''60''', 
		@database_name=N'DBA', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Every Hour', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=8, 
		@freq_subday_interval=1, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20181105, 
		@active_end_date=99991231, 
		@active_start_time=80000, 
		@active_end_time=180000, 
		@schedule_uid=N'a648f1e5-ab8c-4592-8bb2-28ebfa4fec50'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO


