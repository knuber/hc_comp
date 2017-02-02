ALTER PROC FANALYSIS.LGDAT.IMPORT_R_INVENTORY AS
BEGIN
	
	--big letter maker: http://patorjk.com/software/taag

	DECLARE @EC BIGINT;			--error code
	DECLARE @ST DATETIME2;			--start time
	DECLARE @PR DATETIME2;			--prior start
	DECLARE @NV BIGINT;			--next sequence value
	DECLARE @S BIGINT;			--count of rows
	DECLARE @EM VARCHAR(MAX);		--error message
	DECLARE @SQL VARCHAR(MAX);		--dynamic sql holder
	DECLARE @RC BIGINT;			--return code
	DECLARE @X VARCHAR(MAX);		--cursor next item
	DECLARE @L VARCHAR(MAX);		--cursor aggregate
	DECLARE @I VARCHAR(MAX);		--oid sql
	DECLARE @H VARCHAR(MAX);		--oih sql
	DECLARE @Y INT;				--max year
	DECLARE @P INT;				--max period

/*-------------------------------------------------------------------------------------------------------------------------------------------------
  _    _               _           _                   _           _         _                      
 | |  | |             | |         | |                 | |         | |       | |                     
 | |  | |  _ __     __| |   __ _  | |_    ___         | |   ___   | |__     | |        ___     __ _ 
 | |  | | | '_ \   / _` |  / _` | | __|  / _ \    _   | |  / _ \  | '_ \    | |       / _ \   / _` |
 | |__| | | |_) | | (_| | | (_| | | |_  |  __/   | |__| | | (_) | | |_) |   | |____  | (_) | | (_| |
  \____/  | .__/   \__,_|  \__,_|  \__|  \___|    \____/   \___/  |_.__/    |______|  \___/   \__, |
          | |                                                                                  __/ |
          |_|                                                                                 |___/ 
*/-------------------------------------------------------------------------------------------------------------------------------------------------

	----------------POPULATE ERROR VARIABLES-----------------------------------------------
	SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();



	----------------GET NEXT JOB# IN SEQUNCE-----------------------------------------------
	SELECT @NV = NEXT VALUE FOR CTRL.MASTER_IMPORT;


	----------------SEE IF THERE ARE ANY GLOBAL LOCKS--------------------------------------
	IF @EC = 0 
	BEGIN
		SELECT @S = (SELECT COUNT(*) CNT FROM CTRL.IMP_JOB WHERE GLOB_LOCK = 1);
		SELECT @EC = @@ERROR;
	END


	----------------INSERT JOB TO LOG------------------------------------------------------
	IF @EC = 0
	BEGIN
		IF @S <> 0
		BEGIN
			INSERT INTO 
				CTRL.IMP_JOB 
			VALUES
				(@NV,CURRENT_USER,APP_NAME(),'IMPORT_R_INVENTORY','NOT STARTED - JOB IN PROCESS',0,GETDATE(),GETDATE(),0);
			SET @EC = @@ERROR;
			GOTO ERRH
		END
		BEGIN
			INSERT INTO 
				CTRL.IMP_JOB 
			VALUES
				(@NV,CURRENT_USER,APP_NAME(),'IMPORT_R_INVENTORY','PROCESSING',0,GETDATE(),NULL,1);
			SET @EC = @@ERROR;
		END
	END
			
	---------------@st hold the start of the beginning of processing----------------------
	SET @ST = GETDATE()
	SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED;



	SET @PR = GETDATE()
	IF @EC = 0
	BEGIN TRANSACTION INVENTORY

/*-------------------------------------------------------------------------------------------------------------------------------------------------------------------
  _____    _____    _____   _______   _______   
 |_   _|  / ____|  / ____| |__   __| |__   __|  
   | |   | |      | (___      | |       | |     
   | |   | |       \___ \     | |       | |     
  _| |_  | |____   ____) |    | |       | |     
 |_____|  \_____| |_____/     |_|       |_|   
*/-------------------------------------------------------------------------------------------------------------------------------------------------------------------
	

		
		----------------------BUILD SELECT------------------------------
		IF @EC = 0
		BEGIN	
			SELECT CMD INTO #SICSTT FROM dbo.BUILD_DB2_SELECT('LGDAT','ICSTT') OPTION (MAXRECURSION 1000);
			SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
		END
	
		----------------------BUILD SQL---------------------------------
		IF @EC = 0
		BEGIN
			SET @SQL = 
				(SELECT CMD FROM #SICSTT) + 
				+ ' WHERE JHRCID >= '''
				+ (SELECT MAX(JHRCID) FROM LGDAT.ICSTT)
				+ ''' AND JHCTYP = ''S''';
			SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
		END
	
		----------------------CREATE A TABLE COPY-----------------------
		IF @EC = 0
		BEGIN
			SELECT * INTO #ICSTT FROM LGDAT.ICSTT WHERE 0=1;
			SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
		END
	
		----------------------EXECUTE SQL-------------------------------
		IF @EC = 0
		BEGIN
			INSERT INTO #ICSTT EXECUTE(@SQL) AT CMS;
			SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
		END
	
		----------------------BUILD MERGE-------------------------------
		IF @EC = 0
		BEGIN
			SELECT * INTO #MICSTT FROM BUILD_MERGE_SMASH('LGDAT','ICSTT','#ICSTT') OPTION (MAXRECURSION 1000);
			SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
		END

		----------------------EXTRACT MERGE FROMT TABLE-----------------
		IF @EC = 0
		BEGIN
			SET @SQL = (SELECT CMD FROM #MICSTT);
			SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
		END
	
		----------------------EXECUTE MERGE-----------------------------
		IF @EC = 0
		BEGIN
			EXECUTE(@SQL);
			SELECT @RC = @@ROWCOUNT;
			SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
		END
	
		----------------------DROP TEMP TABLES--------------------------
		IF @EC = 0
		BEGIN
			DROP TABLE #ICSTT;
			DROP TABLE #MICSTT;
			DROP TABLE #SICSTT;
			SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
		END

		----------------------PRINT STATUS------------------------------
		IF @EC = 0 
		BEGIN
			PRINT 'ICSTT PROCESSED CORRECTLY';
			INSERT INTO CTRL.IMP_DET VALUES (@NV, 'IMPORT_ICSTT', @EC, @PR, GETDATE());
			SET @PR = GETDATE();
			PRINT cast(DATEDIFF(MS,@PR,GETDATE()) as varchar(max)) + ' ms';
		END
		ELSE 
		BEGIN
			PRINT 'ICSTT PROCESSING ISSUE: ' + @EM
			ROLLBACK TRANSACTION PRODUCTION;
			INSERT INTO CTRL.IMP_DET VALUES (@NV, 'IMPORT_ICSTT', @EC, @PR, GETDATE());
			GOTO ERRH
		END

/*-----------------------------------------------------------------------------------------------------------------------
   _____   _______   _  __  _______ 
  / ____| |__   __| | |/ / |__   __|
 | (___      | |    | ' /     | |   
  \___ \     | |    |  <      | |   
  ____) |    | |    | . \     | |   
 |_____/     |_|    |_|\_\    |_|   

*/-----------------------------------------------------------------------------------------------------------------------                          
		
		IF @EC = 0
		BEGIN	
			SELECT * INTO #STKT FROM LGDAT.STKT WHERE 0=1;
			SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
		END;

		----------------------------BUILD SELECT STATEMENT----------------------------
	
		IF @EC = 0
		BEGIN
			SELECT CMD INTO #SSTKT FROM dbo.BUILD_DB2_SELECT('LGDAT','STKT') OPTION (MAXRECURSION 1000);
			SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
		END;

		----------------------------GRAB INCREMENTAL RECORDS--------------------------
	
		IF @EC = 0
		BEGIN
			--BUILD SELECT
			SET @SQL = 
				(SELECT CMD FROM #SSTKT) 
				+ ' WHERE BYTRAN >= ' 
				+ (SELECT CAST(MAX(BYTRAN) AS VARCHAR(255)) FROM LGDAT.STKT);
			SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
		END;

	
		IF @EC = 0
		BEGIN
			--EXECUTE SELECT BUILD PREVIOUSLY
			INSERT INTO #STKT EXECUTE (@SQL) AT CMS;
			SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
		END;

		----------------------------BUILD MERGE STATEMENT----------------------------
	
		IF @EC = 0
		BEGIN
			SET @SQL = (SELECT CMD FROM dbo.BUILD_MERGE_SMASH('LGDAT','STKT','#STKT') X);
			SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
		END;

		---------------------------EXECUTE MERGE--------------------------------------

	
		IF @EC = 0
		BEGIN
			EXECUTE (@SQL);
			SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
		END;

		---------------DROP TEMP TABLE-----------------------
	

		---------------DROP TEMP TABLE-----------------------
		IF @EC = 0
		BEGIN
			DROP TABLE #STKT;
			DROP TABLE #SSTKT;
			SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
		END;

		IF @EC = 0 
		BEGIN
			PRINT 'STKT PROCESSED CORRECTLY';
			INSERT INTO CTRL.IMP_DET VALUES (@NV, 'IMPORT_STKT', @EC, @PR, GETDATE());
			SET @PR = GETDATE();
			PRINT cast(DATEDIFF(MS,@PR,GETDATE()) as varchar(max)) + ' ms';
		END
		ELSE 
		BEGIN
			PRINT 'STKT PROCESSING ISSUE: ' + @EM
			ROLLBACK TRANSACTION PRODUCTION;
			INSERT INTO CTRL.IMP_DET VALUES (@NV, 'IMPORT_STKT', @EC, @PR, GETDATE());
			GOTO ERRH
		END

	IF @EC = 0
		COMMIT TRANSACTION INVENTORY;


/*-------------------------------------------------------------------------------------------------------------------------------------------------
  _    _               _           _                   _           _         _                      
 | |  | |             | |         | |                 | |         | |       | |                     
 | |  | |  _ __     __| |   __ _  | |_    ___         | |   ___   | |__     | |        ___     __ _ 
 | |  | | | '_ \   / _` |  / _` | | __|  / _ \    _   | |  / _ \  | '_ \    | |       / _ \   / _` |
 | |__| | | |_) | | (_| | | (_| | | |_  |  __/   | |__| | | (_) | | |_) |   | |____  | (_) | | (_| |
  \____/  | .__/   \__,_|  \__,_|  \__|  \___|    \____/   \___/  |_.__/    |______|  \___/   \__, |
          | |                                                                                  __/ |
          |_|                                                                                 |___/ 
*/-------------------------------------------------------------------------------------------------------------------------------------------------


	ERRH:
	IF @EC = 0
	BEGIN
		IF @S <> 0 
		BEGIN
			PRINT 'IMPORT NOT STARTED'
			PRINT cast(DATEDIFF(MS,@ST,GETDATE()) as varchar(max)) + ' ms';
			UPDATE CTRL.IMP_JOB SET 
				RET_CODE = @EC, 
				ED = GETDATE(),
				GLOB_LOCK = 0
			WHERE 
				ID = @NV
		END
		IF @S = 0 
		BEGIN
			PRINT 'TOTAL IMPORT SUCCESS';
			PRINT cast(DATEDIFF(MS,@ST,GETDATE()) as varchar(max)) + ' ms';
			UPDATE CTRL.IMP_JOB SET 
				STAT = 'COMPLETE', 
				RET_CODE = @EC, 
				ED = GETDATE(),
				GLOB_LOCK = 0
			WHERE 
				ID = @NV
		END
	END

	IF @EC <> 0
	BEGIN
		IF @S <> 0 
		BEGIN
			PRINT 'IMPORT NOT STARTED'
			PRINT cast(DATEDIFF(MS,@ST,GETDATE()) as varchar(max)) + ' ms';
			UPDATE CTRL.IMP_JOB SET 
				RET_CODE = @EC, 
				ED = GETDATE(),
				GLOB_LOCK = 0
			WHERE 
				ID = @NV
		END
		IF @S = 0
		BEGIN
			PRINT 'IMPORT FAILURE, CODE: ' + CAST(@EC AS VARCHAR(MAX));
			PRINT cast(DATEDIFF(MS,@ST,GETDATE()) as varchar(max)) + ' ms';
			UPDATE CTRL.IMP_JOB SET 
				STAT = 'FAIL', 
				RET_CODE = @EC, 
				ED = GETDATE(),
				GLOB_LOCK = 1
			WHERE 
				ID = @NV
		END
	END

END





GO


