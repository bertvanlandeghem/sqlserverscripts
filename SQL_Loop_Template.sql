
IF object_id('perflog.query_performance_data_aggregation') IS NULL
EXEC ('CREATE PROCEDURE dbo.MyProcedure as select 1')
GO

ALTER PROCEDURE [dbo].[MyProcedure] 
	@debuglevel tinyint       = 1,    -- level 1 = control flow and print statements; level 2= level 1 + variable values; Level 3 = Level 2 + intermediate result sets 
	@execute    bit           = 1     -- 1 =  normal execution; 0 = only print statements
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;
    
	BEGIN TRY

        /*
            usage:

            [dbo].[MyProcedure] 

            [dbo].[MyProcedure] @debuglevel=2, @execute=0

        */

	 -- DECLARE @debuglevel tinyint       = 1    -- level 1 = control flow and print statements; level 2= level 1 + variable values; Level 3 = Level 2 + intermediate result sets 
	 -- DECLARE @execute    bit           = 1    -- 1 =  normal execution; 0 = only print statements

		IF @debuglevel >= 1 PRINT '[DEBUG1]['+ CONVERT(nvarchar(24),SYSDATETIME(),126) +'] Starting procedure [' + DB_NAME() + '].[' + OBJECT_SCHEMA_NAME(@@PROCID) + '].[' + OBJECT_NAME(@@PROCID) + '] on server ' + @@servername
		IF @debuglevel >= 1 PRINT '[DEBUG1]['+ CONVERT(nvarchar(24),SYSDATETIME(),126) +'] ' + REPLICATE('-', 100)
		IF @debuglevel >= 1 PRINT '[DEBUG1]['+ CONVERT(nvarchar(24),SYSDATETIME(),126) +'] Description goes here ...'
		IF @debuglevel >= 1 PRINT '[DEBUG1]['+ CONVERT(nvarchar(24),SYSDATETIME(),126) +'] ' + REPLICATE('-', 100)


		/*
			Create a table to hold the error messages that occur in the cursor.
		*/
		CREATE TABLE #TabErrors 
		(
			step         varchar(255), 
			ErrorMessage nvarchar(max)
		)


        /*
            Create variables and temp tables
        */
       	IF @debuglevel >= 2 PRINT '[DEBUG2]['+ CONVERT(nvarchar(24),SYSDATETIME(),126) +'] Initializing variables.'
		DECLARE @rows                  int;
        DECLARE @rows_to_do            int;

       	IF @debuglevel >= 2 PRINT '[DEBUG2]['+ CONVERT(nvarchar(24),SYSDATETIME(),126) +'] Creating temp table ''#MyTempTable''.'
    
        CREATE TABLE #MyTempTable (
	        [id]                        [int]              NOT NULL
        )
    

        /*
            Start loop
        */
    	SET @rows_to_do = 1;
        DECLARE @trancount int;
        DECLARE @error int, @message varchar(4000), @xstate int;


    	WHILE @rows_to_do > 0
    	BEGIN
    	        
     
                IF @debuglevel >= 1 PRINT '[DEBUG1]['+ CONVERT(nvarchar(24),SYSDATETIME(),126) +'] Starting batch.'
                     
                /*
                    DELETE 10k records from staging into temp table (for batched processing)
                */
    			BEGIN TRY 
    
                    SET @trancount = @@trancount;

                    IF @trancount = 0
                        BEGIN TRANSACTION
                    ELSE
                        SAVE TRANSACTION TRN_data_aggregation;

                    IF @debuglevel >= 2 PRINT '[DEBUG1]['+ CONVERT(nvarchar(24),SYSDATETIME(),126) +'] .'
    
                    /*
                        Your code goes here.
                    */



                    /*
                        End of procedure-specific code.
                    */
    		        SET @rows_to_do = @@ROWCOUNT;
    
                    IF @debuglevel >= 1 PRINT '[DEBUG1]['+ CONVERT(nvarchar(24),SYSDATETIME(),126) +'] Batch size: ' + CAST(@rows_to_do as varchar(6))

                    IF @trancount = 0   
                    COMMIT TRANSACTION;

                    IF @rows_to_do = 0 AND @debuglevel >= 1 
                    BEGIN 
                        PRINT '[DEBUG1]['+ CONVERT(nvarchar(24),SYSDATETIME(),126) +'] No more work to do. Skipping to end of loop.'''
    				    GOTO ExitLoop
                    END
    
    			END TRY
    			BEGIN CATCH

                    SELECT @error   = ERROR_NUMBER(),
                           @message = ERROR_MESSAGE(), 
                           @xstate  = XACT_STATE();
                    IF @xstate = -1
                        ROLLBACK;
                    IF @xstate = 1 and @trancount = 0
                        ROLLBACK
                    IF @xstate = 1 and @trancount > 0
                        ROLLBACK TRANSACTION TRN_data_aggregation;


    				INSERT INTO #TabErrors(step,ErrorMessage)
    					VALUES ('Describe the place where this error occurs.', @message)

    			END CATCH
           
          		--LABEL
        		ExitLoop:

                --COMMIT TRANSACTION;
              
                ---- For really big operations.
                -- CHECKPOINT;         -- if simple
                -- BACKUP LOG ... -- if full
        
                /*
                    repeat loop for next batch
                */

        END
    
        /*
            Cleaning up
        */
        IF OBJECT_ID('tempdb..#MyTempTable') IS NOT NULL
        DROP TABLE #query_performance_central_staging_temp
    
 
        /*
            Return Errors if any...
        */
    	IF OBJECT_ID('tempdb.dbo.#TabErrors', 'U') IS NOT NULL
    	BEGIN
    		IF @debuglevel >= 2 PRINT '[DEBUG2]['+ CONVERT(nvarchar(24),SYSDATETIME(),126) +'] Selecting from error table (if any).'
    
    		SELECT * FROM #TabErrors 
    		WHERE errormessage IS NOT NULL
    
    		DROP TABLE #TabErrors
    	END
    
		IF @debuglevel >= 1 PRINT '[DEBUG1]['+ CONVERT(nvarchar(24),SYSDATETIME(),126) +'] ' + REPLICATE('-', 100)
    	IF @debuglevel >= 1 PRINT '[DEBUG1]['+ CONVERT(nvarchar(24),SYSDATETIME(),126) +'] End procedure [' + DB_NAME() + '].[' + OBJECT_SCHEMA_NAME(@@PROCID) + '].[' + OBJECT_NAME(@@PROCID) + '] on server ' + @@servername
    	IF @debuglevel >= 1 PRINT '[DEBUG1]['+ CONVERT(nvarchar(24),SYSDATETIME(),126) +'] Have a good day!'
    
	END TRY
	BEGIN CATCH

		IF @@trancount > 0 ROLLBACK TRANSACTION
		;THROW --requires SQL 2012+

		RETURN 55555

	END CATCH;

END


