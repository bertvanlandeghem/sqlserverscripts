-- Requires fnGetNthWeekdayOfPeriod
-- Does not (yet) contain any error handling

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Get the type of backup and its related retention time based on a given date (usually used with GETDATE(), today)

CREATE OR ALTER FUNCTION dbo.fnGetBackupInput
(
    @theDate DATETIME
)
RETURNS @backupInput TABLE 
(
    BackupDate date               NOT NULL
  , BackupScheduleType varchar(7) NOT NULL
  , BackupType char(4)            NOT NULL
  , RetainDays int                NOT NULL
)
AS 
BEGIN

    /* Examples

        SELECT * FROM  dbo.fnGetBackupInput('2019-01-05')
        SELECT * FROM  dbo.fnGetBackupInput('2019-05-04')
        SELECT * FROM  dbo.fnGetBackupInput('2019-05-11')
        SELECT * FROM  dbo.fnGetBackupInput(GETDATE()   )

        SELECT BackupCommand     = '
            EXECUTE [dbo].[DatabaseBackup] 
               @Databases  = ''USER_DATABASES''
              ,@Directory  = ''\\backupserver\backupshare''
              ,@BackupType = ' + BackupType + '
              ,@RetainDays = ' + CAST(RetainDays AS varchar(11)) + '
              ,@LogToTable = ''Y''
              ,@Execute    = ''Y'';'
        FROM  dbo.fnGetBackupInput('2019-01-05')


        SELECT BackupDate
             , BackupScheduleType
             , BackupType
             , RetainDays
        FROM (VALUES ('2019-01-05'),('2019-05-04'),('2019-05-11'),('2019-05-22') ) as MyDates([Date])
        CROSS APPLY  dbo.fnGetBackupInput([Date])

    */

    DECLARE @FullBackupWeekday TINYINT = 6,
            @theNth SMALLINT = 1
    
    INSERT @backupInput
    SELECT theDate            = CAST(@theDate as date)
         , BackupScheduleType = CASE WHEN dbo.fnGetNthWeekdayOfPeriod(@theDate, @FullBackupWeekday, 1, 'Y')  = @theDate -- First saturday of the year
                                     THEN 'Yearly'
                                     WHEN dbo.fnGetNthWeekdayOfPeriod(@theDate, @FullBackupWeekday, 1, 'M')  = @theDate -- first Saturday of the month
                                      AND NOT dbo.fnGetNthWeekdayOfPeriod(@theDate, @FullBackupWeekday, 1, 'Y')  = @theDate -- but not first Saturday of the year
                                     THEN 'Monthly'
                                     WHEN  /*[DateFirstIndependentWeekday] =*/ 1 + DATEDIFF(DAY,DATEADD(WEEK, DATEDIFF(WEEK, 0, @theDate), '19000101'),@theDate) = @FullBackupWeekday 
                                     THEN 'Weekly'
                                     ELSE 'Daily'
                                END
         , BackupType         = CASE WHEN /*[DateFirstIndependentWeekday] =*/ 1 + DATEDIFF(DAY,DATEADD(WEEK, DATEDIFF(WEEK, 0, @theDate), '19000101'),@theDate) = @FullBackupWeekday 
                                     THEN 'FULL' 
                                     ELSE 'DIFF' 
                                END
         , RetainDays         = CASE WHEN dbo.fnGetNthWeekdayOfPeriod(@theDate, @FullBackupWeekday, @theNth, 'Y')  = @theDate  
                                     THEN /* Yearly, keep 3 years          */ DATEDIFF(DAY, @theDate, ( DATEADD(YEAR , 3,@theDate ) ))
                                     WHEN dbo.fnGetNthWeekdayOfPeriod(@theDate, @FullBackupWeekday, 1, 'M')  = @theDate -- first Saturday of the month
                                      AND NOT dbo.fnGetNthWeekdayOfPeriod(@theDate, @FullBackupWeekday, 1, 'Y')  = @theDate -- but not first Saturday of the year
                                     THEN /* Monthly, keep 1 year          */ DATEDIFF(DAY, @theDate, ( DATEADD(YEAR , 1 ,@theDate ) ))
                                     WHEN /*[DateFirstIndependentWeekday] =*/ 1 + DATEDIFF(DAY,DATEADD(WEEK, DATEDIFF(WEEK, 0, @theDate), '19000101'),@theDate) = @FullBackupWeekday 
                                     THEN /* Weekly, keep 3 months         */ DATEDIFF(DAY, @theDate, ( DATEADD(MONTH, 3, @theDate )  ))
                                     ELSE /* Daily, keep 1 months          */ DATEDIFF(DAY, @theDate, ( DATEADD(MONTH, 1, @theDate ) ))
                                END
    
    RETURN
END
GO

