USE [msdb]
GO

/****** Object:  Job [DBA Local Server Maintenance]    Script Date: 1/08/2018 9:14:15 ******/
IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N'DBA Local Server Maintenance')
EXEC msdb.dbo.sp_delete_job @job_name=N'DBA Local Server Maintenance', @delete_unused_schedule=1
GO

/****** Object:  Job [DBA Local Server Maintenance]    Script Date: 1/08/2018 9:14:15 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 1/08/2018 9:14:15 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
select @jobId = job_id from msdb.dbo.sysjobs where (name = N'DBA Local Server Maintenance')
if (@jobId is NULL)
BEGIN
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DBA Local Server Maintenance', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END
/****** Object:  Step [EXEC sp_cycle_errorlog]    Script Date: 1/08/2018 9:14:15 ******/
IF NOT EXISTS (SELECT * FROM msdb.dbo.sysjobsteps WHERE job_id = @jobId and step_id = 1)
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'EXEC sp_cycle_errorlog', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXEC sp_cycle_errorlog', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [EXEC sp_cycle_agent_errorlog]    Script Date: 1/08/2018 9:14:15 ******/
IF NOT EXISTS (SELECT * FROM msdb.dbo.sysjobsteps WHERE job_id = @jobId and step_id = 2)
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'EXEC sp_cycle_agent_errorlog', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXEC msdb.dbo.sp_cycle_agent_errorlog', 
		@database_name=N'msdb', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [EXEC  sp_delete_backuphistory (30 days)]    Script Date: 1/08/2018 9:14:15 ******/
IF NOT EXISTS (SELECT * FROM msdb.dbo.sysjobsteps WHERE job_id = @jobId and step_id = 3)
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'EXEC  sp_delete_backuphistory (30 days)', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'SET NOCOUNT ON

DECLARE @RetentionDays int = 30
DECLARE @CutoffDate    datetime= DATEADD(DAY,DATEDIFF(DAY,0,GETDATE()) - @RetentionDays,0)
DECLARE @PurgeDate     datetime

-- This loop will purge backup history one day at a time.
WHILE 1 = 1
BEGIN

	SET @PurgeDate = null
	
	-- Find date of oldest backup set
	SELECT @PurgeDate = DATEADD(DAY,DATEDIFF(DAY,0,MIN(backup_finish_date)) + 1 ,0)
	  FROM msdb.dbo.backupset
	 WHERE backup_finish_date <= @CutoffDate

	IF @PurgeDate IS NULL OR @PurgeDate > @CutoffDate
	BEGIN
		BREAK
	END
	
	EXEC msdb.dbo.sp_delete_backuphistory @PurgeDate

END', 
		@database_name=N'msdb', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [EXEC  sp_purge_jobhistory (30 days)]    Script Date: 1/08/2018 9:14:15 ******/
IF NOT EXISTS (SELECT * FROM msdb.dbo.sysjobsteps WHERE job_id = @jobId and step_id = 4)
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'EXEC  sp_purge_jobhistory (30 days)', 
		@step_id=4, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'SET NOCOUNT ON

DECLARE @RetentionDays int      = 30
DECLARE @CutoffDate    datetime = DATEADD(DAY,DATEDIFF(DAY,0,GETDATE()) - @RetentionDays,0)
DECLARE @CutoffDateInt int      = CONVERT(INT, CONVERT(VARCHAR, @CutoffDate, 112))
DECLARE @PurgeDate     datetime
DECLARE @PurgeDateInt  int

-- This loop will purge job history one day at a time. Won''t lock a long time when first run on a ''neglected'' server.
WHILE 1 = 1
BEGIN

	SET @PurgeDate = NULL

	-- Find date of oldest job
	SELECT @PurgeDate = DATEADD(DAY,1,
						   DATEFROMPARTS(
							  SUBSTRING(CAST(MIN(run_date) AS CHAR(8)), 1,4)
							, SUBSTRING(CAST(MIN(run_date) AS CHAR(8)), 5,2)
							, SUBSTRING(CAST(MIN(run_date) AS CHAR(8)), 7,2)
						   ))
	  FROM msdb.dbo.sysjobhistory
	 WHERE run_date <= @CutoffDateInt


	SELECT @PurgeDateInt = CONVERT(INT, CONVERT(VARCHAR, @PurgeDate, 112))

	IF @PurgeDate IS NULL OR @PurgeDate > @CutoffDate
	BEGIN
		BREAK
	END

	EXEC msdb.dbo.sp_purge_jobhistory @oldest_date = @PurgeDate

END', 
		@database_name=N'msdb', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Daily at 00:00', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20180801, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, 
		@schedule_uid=N'b00a0e22-3e5b-4ad4-88fa-f8560c5ba39f'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO


