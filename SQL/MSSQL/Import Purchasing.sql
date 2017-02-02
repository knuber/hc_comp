
ALTER PROC [LGDAT].[IMPORT_R_PURCH] AS
BEGIN
	
	--big letter maker: http://patorjk.com/software/taag

	DECLARE @EC BIGINT;				--error code
	DECLARE @ST DATETIME2;			--start time
	DECLARE @PR DATETIME2;			--prior start
	DECLARE @NV BIGINT;				--next sequence value
	DECLARE @S BIGINT;				--count of rows
	DECLARE @EM VARCHAR(MAX);		--error message
	DECLARE @SQL VARCHAR(MAX);		--dynamic sql holder
	DECLARE @RC BIGINT;				--return code
	DECLARE @X VARCHAR(MAX);		--cursor next item
	DECLARE @L VARCHAR(MAX);		--cursor aggregate
	DECLARE @Y INT;					--max year
	DECLARE @P INT;					--max period
	DECLARE @V1 VARCHAR(MAX);		--AVTTX# min
	DECLARE @V2 VARCHAR(MAX);		--AVTTX# max

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
						(@NV,CURRENT_USER,APP_NAME(),'IMPORT_R_PURCH','NOT STARTED - JOB IN PROCESS',0,GETDATE(),GETDATE(),0);
					SET @EC = @@ERROR;
					GOTO ERRH
				END
				BEGIN
					INSERT INTO 
						CTRL.IMP_JOB 
					VALUES
						(@NV,CURRENT_USER,APP_NAME(),'IMPORT_R_PURCH','PROCESSING',0,GETDATE(),NULL,1);
					SET @EC = @@ERROR;
				END
		END
			
	---------------@st hold the start of the beginning of processing----------------------
	IF @EC = 0
	BEGIN
		SET @ST = GETDATE();
		SET @PR = GETDATE();
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END;

	SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
	BEGIN TRANSACTION PURCH;

/*-------------------------------------------------------------------------------------------------------------------------------------------------------------------
           __      __  _______  __   __
     /\     \ \    / / |__   __| \ \ / /
    /  \     \ \  / /     | |     \ V / 
   / /\ \     \ \/ /      | |      > <  
  / ____ \     \  /       | |     / . \ 
 /_/    \_\     \/        |_|    /_/ \_\
                                        
*/-------------------------------------------------------------------------------------------------------------------------------------------------------------------
	
	---------------Generate SQL select----------------------------------------------------
	IF @EC = 0
	BEGIN	
		SELECT CMD INTO #SA FROM dbo.BUILD_DB2_SELECT('LGDAT','AVTX') OPTION (MAXRECURSION 1000);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	---------------Grab the current max avttx# as new min---------------------------------
	IF @EC = 0
	BEGIN
		SELECT @V1 = (SELECT CAST(MAX(AVTTX#) AS VARCHAR(MAX)) FROM LGDAT.AVTX)
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	---------------Add where clause to SELECT---------------------------------------------
	IF @EC = 0
	BEGIN
		SET @SQL = 
			(SELECT CMD FROM #SA) + 
			+' WHERE AVTTX# >= ' 
			+ @V1
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	
	---------------Create table copy for work table---------------------------------------
	IF @EC = 0
	BEGIN
		SELECT * INTO #XA FROM LGDAT.AVTX WHERE 0=1;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	---------------Execute SQL into table copy--------------------------------------------
	IF @EC = 0
	BEGIN
		INSERT INTO #XA EXECUTE(@SQL) AT CMS;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	---------------Grab max avttx# for range----------------------------------------------
	IF @EC = 0
	BEGIN
		SELECT @V2 = (SELECT CAST(MAX(AVTTX#) AS VARCHAR(MAX)) FROM #XA);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	---------------Build merge statement--------------------------------------------------
	IF @EC = 0
	BEGIN
		SELECT * INTO #MA FROM BUILD_MERGE_SMASH('LGDAT','AVTX','#XA') OPTION (MAXRECURSION 1000);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	---------------Insert merge to scalar variable----------------------------------------
	IF @EC = 0
	BEGIN
		SET @SQL = (SELECT CMD FROM #MA);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	
	---------------Execute merge statement------------------------------------------------
	IF @EC = 0
	BEGIN
		EXECUTE(@SQL);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	---------------Drop temp tables-------------------------------------------------------
	IF @EC = 0
	BEGIN
		DROP TABLE #XA;
		DROP TABLE #SA;
		DROP TABLE #MA;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	---------------Write to details log---------------------------------------------------
	IF @EC = 0 
	BEGIN
		PRINT 'AVTX PROCESSED CORRECTLY';
		INSERT INTO CTRL.IMP_DET VALUES (@NV, 'IMPORT_AVTX', @EC, @PR, GETDATE());
		SET @PR = GETDATE();
		PRINT cast(DATEDIFF(MS,@PR,GETDATE()) as varchar(max)) + ' ms';
	END
	ELSE 
	BEGIN
		PRINT 'AVTX PROCESSING ISSUE: ' + @EM
		ROLLBACK TRANSACTION PURCH;
		INSERT INTO CTRL.IMP_DET VALUES (@NV, 'IMPORT_AVTX', @EC, @PR, GETDATE());
		GOTO ERRH
	END

/*-------------------------------------------------------------------------------------------------------------------------------------------------
 __      __   _____   _    _   _____  
 \ \    / /  / ____| | |  | | |  __ \ 
  \ \  / /  | |      | |__| | | |__) |
   \ \/ /   | |      |  __  | |  _  / 
    \  /    | |____  | |  | | | | \ \ 
     \/      \_____| |_|  |_| |_|  \_\
                                      
*/-------------------------------------------------------------------------------------------------------------------------------------------------

	---------------Build select statement-------------------------------------------------
	IF @EC = 0
	BEGIN	
		SELECT CMD INTO #SV FROM dbo.BUILD_DB2_SELECT('LGDAT','VCHR') OPTION (MAXRECURSION 1000);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	
	---------------Build where clause-----------------------------------------------------
	IF @EC = 0
	BEGIN
		SET @SQL = 
			(SELECT CMD FROM #SV)
			+ ' INNER JOIN (SELECT DISTINCT AVTCO#, AVTVH# FROM LGDAT.AVTX WHERE AVTTX# >= '
			+ @V1
			+ ') X ON X.AVTCO# = IDCOM# AND X.AVTVH# = IDVCH#'
		--SELECT @SQL;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	---------------Build table copy-------------------------------------------------------
	IF @EC = 0
	BEGIN
		SELECT * INTO #XV FROM LGDAT.VCHR WHERE 0=1;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	---------------Execute select into copy-----------------------------------------------
	IF @EC = 0
	BEGIN
		INSERT INTO #XV EXECUTE(@SQL) AT CMS
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	---------------Build merge statement--------------------------------------------------
	IF @EC = 0
	BEGIN
		SELECT CMD INTO #MV FROM dbo.BUILD_MERGE_SMASH('LGDAT','VCHR','#XV');
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	---------------Move statement to scalar variable--------------------------------------
	IF @EC = 0
	BEGIN
		SET @SQL = (SELECT CMD FROM #MV);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	---------------Execute merge statement------------------------------------------------
	IF @EC = 0
	BEGIN
		EXECUTE(@SQL);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	---------------Drop temp tables-------------------------------------------------------
	IF @EC = 0
	BEGIN
		DROP TABLE #SV
		DROP TABLE #MV
		DROP TABLE #XV
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	---------------Write to details log---------------------------------------------------
	IF @EC = 0 
	BEGIN
		PRINT 'VCHR PROCESSED CORRECTLY';
		INSERT INTO CTRL.IMP_DET VALUES (@NV, 'IMPORT_VCHR', @EC, @PR, GETDATE());
		SET @PR = GETDATE();
		PRINT cast(DATEDIFF(MS,@PR,GETDATE()) as varchar(max)) + ' ms';
	END
	ELSE 
	BEGIN
		PRINT 'VCHR PROCESSING ISSUE: ' + @EM
		ROLLBACK TRANSACTION PURCH;
		INSERT INTO CTRL.IMP_DET VALUES (@NV, 'IMPORT_VCHR', @EC, @PR, GETDATE());
		GOTO ERRH
	END

/*-------------------------------------------------------------------------------------------------------------------------------------------------
   ____    _____    ______   _   _ 
  / __ \  |  __ \  |  ____| | \ | |
 | |  | | | |__) | | |__    |  \| |
 | |  | | |  ___/  |  __|   | . ` |
 | |__| | | |      | |____  | |\  |
  \____/  |_|      |______| |_| \_|
                                   
*/-------------------------------------------------------------------------------------------------------------------------------------------------

	---------------Build select statement-------------------------------------------------
	IF @EC = 0
	BEGIN	
		SELECT CMD INTO #SO FROM dbo.BUILD_DB2_SELECT('LGDAT','OPEN') OPTION (MAXRECURSION 1000);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	
	---------------Build where clause-----------------------------------------------------
	IF @EC = 0
	BEGIN
		SET @SQL = 
			(SELECT CMD FROM #SO) + 
			+ ' INNER JOIN (SELECT DISTINCT AVTCO#, AVTVH# FROM LGDAT.AVTX WHERE AVTTX# >= '
			+ @V1
			+ ') X ON X.AVTCO# = FHCOM# AND X.AVTVH# = FHVCH#';
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	
	---------------Create table copy------------------------------------------------------
	IF @EC = 0
	BEGIN
		SELECT * INTO #XO FROM LGDAT.[OPEN] WHERE 0=1;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	
	---------------Execute select into copy-----------------------------------------------
	IF @EC = 0
	BEGIN
		INSERT INTO #XO EXECUTE(@SQL) AT CMS;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	---------------Build merge statement--------------------------------------------------
	IF @EC = 0
	BEGIN
		SELECT REPLACE(CMD,'.OPEN','.[OPEN]') CMD INTO #MO FROM BUILD_MERGE_SMASH('LGDAT','OPEN','#XO') OPTION (MAXRECURSION 1000);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	---------------move merge statement to scalar variable--------------------------------
	IF @EC = 0
	BEGIN
		SET @SQL = (SELECT CMD FROM #MO);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	
	---------------Execute merge statement------------------------------------------------
	IF @EC = 0
	BEGIN
		EXECUTE(@SQL);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	
	---------------Drop temp tables-------------------------------------------------------
	IF @EC = 0
	BEGIN
		DROP TABLE #XO;
		DROP TABLE #MO;
		DROP TABLE #SO;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	---------------Write to details log---------------------------------------------------
	IF @EC = 0 
	BEGIN
		PRINT 'OPEN PROCESSED CORRECTLY';
		INSERT INTO CTRL.IMP_DET VALUES (@NV, 'IMPORT_OPEN', @EC, @PR, GETDATE());
		SET @PR = GETDATE();
		PRINT cast(DATEDIFF(MS,@PR,GETDATE()) as varchar(max)) + ' ms';
	END
	ELSE 
	BEGIN
		PRINT 'OPEN PROCESSING ISSUE: ' + @EM
		ROLLBACK TRANSACTION PURCH;
		INSERT INTO CTRL.IMP_DET VALUES (@NV, 'IMPORT_OPEN', @EC, @PR, GETDATE());
		GOTO ERRH
	END

/*-------------------------------------------------------------------------------------------------------------------------------------------------
   _____   _    _    ____    _____  
  / ____| | |  | |  / __ \  |  __ \ 
 | |      | |__| | | |  | | | |__) |
 | |      |  __  | | |  | | |  _  / 
 | |____  | |  | | | |__| | | | \ \ 
  \_____| |_|  |_|  \___\_\ |_|  \_\
                                                               
*/-------------------------------------------------------------------------------------------------------------------------------------------------

	---------------Create initial select--------------------------------------------------
	IF @EC = 0
	BEGIN	
		SELECT CMD INTO #SR FROM dbo.BUILD_DB2_SELECT('LGDAT','CHQR') OPTION (MAXRECURSION 1000);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	
	---------------Build where clause-----------------------------------------------------
	IF @EC = 0
	BEGIN
		SET @SQL = 
			(SELECT CMD FROM #SR)
			+ ' INNER JOIN (SELECT DISTINCT	AVTCO#, AVTCHB,	AVTCHQ FROM LGDAT.AVTX WHERE AVTTX# >= '
			+ @V1
			+ ') X ON X.AVTCO# = IGCOM# AND X.AVTCHB = IGBNK# AND X.AVTCHQ = IGCHQ#';
		--SELECT @SQL
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	---------------Create table copy------------------------------------------------------
	IF @EC = 0
	BEGIN
		SELECT * INTO #XR FROM LGDAT.CHQR WHERE 0=1;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	---------------Execute select---------------------------------------------------------
	IF @EC = 0
	BEGIN
		INSERT INTO #XR EXECUTE(@SQL) AT CMS
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	---------------Build merge statement--------------------------------------------------
	IF @EC = 0
	BEGIN
		SELECT CMD INTO #MR FROM dbo.BUILD_MERGE_SMASH('LGDAT','CHQR','#XR');
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	---------------Move merge to scalar variable------------------------------------------
	IF @EC = 0
	BEGIN
		SET @SQL = (SELECT CMD FROM #MR);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	---------------Execute merge----------------------------------------------------------
	IF @EC = 0
	BEGIN
		EXECUTE(@SQL);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	---------------Drop temp tables-------------------------------------------------------
	IF @EC = 0
	BEGIN
		DROP TABLE #SR
		DROP TABLE #MR
		DROP TABLE #XR
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	---------------Write to details log---------------------------------------------------
	IF @EC = 0 
	BEGIN
		PRINT 'CHQR PROCESSED CORRECTLY';
		INSERT INTO CTRL.IMP_DET VALUES (@NV, 'IMPORT_CHQR', @EC, @PR, GETDATE());
		SET @PR = GETDATE();
		PRINT cast(DATEDIFF(MS,@PR,GETDATE()) as varchar(max)) + ' ms';
	END
	ELSE 
	BEGIN
		PRINT 'CHQR PROCESSING ISSUE: ' + @EM
		ROLLBACK TRANSACTION PURCH;
		INSERT INTO CTRL.IMP_DET VALUES (@NV, 'IMPORT_CHQR', @EC, @PR, GETDATE());
		GOTO ERRH
	END

/*-------------------------------------------------------------------------------------------------------------------------------------------------
  _____     ____    __  __  __      __             _____  
 |  __ \   / __ \  |  \/  | \ \    / /     /\     |  __ \ 
 | |__) | | |  | | | \  / |  \ \  / /     /  \    | |__) |
 |  ___/  | |  | | | |\/| |   \ \/ /     / /\ \   |  _  / 
 | |      | |__| | | |  | |    \  /     / ____ \  | | \ \ 
 |_|       \____/  |_|  |_|     \/     /_/    \_\ |_|  \_\
                                                          
*/-------------------------------------------------------------------------------------------------------------------------------------------------
	
	---------------Build initial select---------------------------------------------------
	IF @EC = 0
	BEGIN	
		SELECT CMD INTO #SM FROM dbo.BUILD_DB2_SELECT('LGDAT','POMVAR') OPTION (MAXRECURSION 1000);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	---------------Add where clause-------------------------------------------------------
	IF @EC = 0
	BEGIN
		SET @SQL = 
			(SELECT CMD FROM #SM)
			+ ' INNER JOIN (SELECT DISTINCT AVTCO#, AVTVH# FROM LGDAT.AVTX WHERE AVTTX# >= '
			+ @V1
			+ ') X ON X.AVTCO# = LBCOM# AND X.AVTVH# = LBVCH#'
		--SELECT @SQL;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	---------------Create table copy------------------------------------------------------
	IF @EC = 0
	BEGIN
		SELECT * INTO #XM FROM LGDAT.POMVAR WHERE 0=1;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	
	---------------Execute select to table copy-------------------------------------------
	IF @EC = 0
	BEGIN
		INSERT INTO #XM EXECUTE(@SQL) AT CMS;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	
	---------------Buld merge statement---------------------------------------------------
	IF @EC = 0
	BEGIN
		SELECT * INTO #MM FROM BUILD_MERGE_SMASH('LGDAT','POMVAR','#XM') OPTION (MAXRECURSION 1000);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	---------------Move merge to scalar variable------------------------------------------
	IF @EC = 0
	BEGIN
		SET @SQL = (SELECT CMD FROM #MM);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	
	---------------Execute merge----------------------------------------------------------
	IF @EC = 0
	BEGIN
		EXECUTE(@SQL);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	
	---------------Drop temp tables-------------------------------------------------------
	IF @EC = 0
	BEGIN
		DROP TABLE #XM;
		DROP TABLE #MM;
		DROP TABLE #SM;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	---------------Write to details log---------------------------------------------------
	IF @EC = 0 
	BEGIN
		PRINT 'POMVAR PROCESSED CORRECTLY';
		INSERT INTO CTRL.IMP_DET VALUES (@NV, 'IMPORT_POMVAR', @EC, @PR, GETDATE());
		SET @PR = GETDATE();
		PRINT cast(DATEDIFF(MS,@PR,GETDATE()) as varchar(max)) + ' ms';
	END
	ELSE 
	BEGIN
		PRINT 'POMVAR PROCESSING ISSUE: ' + @EM
		ROLLBACK TRANSACTION PURCH;
		INSERT INTO CTRL.IMP_DET VALUES (@NV, 'IMPORT_POMAVR', @EC, @PR, GETDATE());
		GOTO ERRH
	END


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

	IF @EC = 0
		COMMIT TRANSACTION PURCH;

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


