/*****************************************************************************/
/* Summary: Proof of concept code for a wrapper stored procedure             */
/*          around Ola Hallengren's MaintenanceSolution stored               */
/*          procedures so that the command lines can be built dynamically    */
/*          by the backup jobs.                                              */
/*          Uses STING_AGG() => SQL 2017+                                    */
/* By Bert Van Landeghem 2019-02-20                                          */
/*****************************************************************************/
SET NOCOUNT ON;

/*****************************************************************************/
/* Test data                                                                 */
/*****************************************************************************/
CREATE TABLE #MaintenanceSolutionParameters
(   
    [Command] varchar(128),
    [Parameter] varchar(128),
    [Value] varchar(128)
);

-- following code can come from source control
INSERT INTO #MaintenanceSolutionParameters
VALUES ('master.dbo.DatabaseBackup', '@Directory', NULL)
     , ('master.dbo.DatabaseBackup', '@BackupType', 'FULL')
     , ('master.dbo.DatabaseBackup', '@Compress', 'Y')
     , ('master.dbo.DatabaseBackup', '@ChangeBackupType', 'Y')     
     , ('master.dbo.DatabaseBackup', '@Execute', 'N')     
     , ('master.dbo.DatabaseBackup', '@LogToTable', 'Y')     
     , ('master.dbo.DatabaseBackup', '@Databases', '-ALL_DATABASES')
     , ('master.dbo.DatabaseBackup', '@Databases', 'SYSTEM_DATABASES')
     , ('master.dbo.DatabaseBackup', '@Databases', '-TestExclude')
     , ('master.dbo.DatabaseBackup', '@Databases', 'TestInclude')
     , ('master.dbo.DatabaseBackup', '@Databases', 'SortTestInclude')

     , ('master.dbo.IndexOptimize', '@Databases', 'ALL_DATABASES')
     , ('master.dbo.IndexOptimize', '@Databases', '-SYSTEM_DATABASES');


/*****************************************************************************/
/* Build the command line                                                    */
/*****************************************************************************/
DECLARE @CommandLine nvarchar(max);

;WITH CTE AS (
  -- Concatenation per [Parameter] 
      SELECT [Command]
           , [Parameter] = [Parameter] + ' = ''' + STRING_AGG( [Value] , ',') WITHIN GROUP (ORDER BY [Value] ASC) + ''''
        FROM #MaintenanceSolutionParameters
       WHERE [Command] = 'master.dbo.DatabaseBackup'
    GROUP BY [Command]
           , [Parameter]
  )
-- Concatenation per [Command].
  SELECT @CommandLine = CONCAT_WS(' ',[Command], STRING_AGG([Parameter], ', '))
    FROM CTE 
GROUP BY [Command];


/*****************************************************************************/
/* Cleanup                                                                   */
/*****************************************************************************/
DROP TABLE #MaintenanceSolutionParameters;


/*****************************************************************************/
/* Execute                                                                   */
/*****************************************************************************/
PRINT @CommandLine;
--EXEC sp_executesql @CommandLine;

GO