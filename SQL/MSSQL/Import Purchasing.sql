ALTER PROC [LGDAT].[IMPORT_R_AP] AS
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
	DECLARE @AGG VARCHAR(MAX);		--glsbap where clause

/*
	EFTBD	- batch number serves as sequence
	EFTBH	- batch number serves as sequence
	AVTX	- transaction number serves as sequence
	VCHR	- based on AVTX
	OPEN	- based on AVTX
	CHQR	- based on AVTX
	UCHQ	- get everything after last check date. 90% waste but no other way identified currently
	POMVAR	- based on AVTX
	GLSBAP	- based on GTRAN batch and then DKRCID used as sequence, and then pull all DKRCID where 0
	VEND	- based on update/create date flags
*/

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
						(@NV,CURRENT_USER,APP_NAME(),'IMPORT_R_AP','NOT STARTED - JOB IN PROCESS',0,GETDATE(),GETDATE(),0);
					SET @EC = @@ERROR;
					GOTO ERRH
				END
				BEGIN
					INSERT INTO 
						CTRL.IMP_JOB 
					VALUES
						(@NV,CURRENT_USER,APP_NAME(),'IMPORT_R_AP','PROCESSING',0,GETDATE(),NULL,1);
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

/*-------------------------------------------------------------------------------------------------------------------------------------------------
  ______ ______ _______ ____  _____  
 |  ____|  ____|__   __|  _ \|  __ \ 
 | |__  | |__     | |  | |_) | |  | |
 |  __| |  __|    | |  |  _ <| |  | |
 | |____| |       | |  | |_) | |__| |
 |______|_|       |_|  |____/|_____/ 
                                     
*/-------------------------------------------------------------------------------------------------------------------------------------------------

	---------------Build select statement-------------------------------------------------
	IF @EC = 0
	BEGIN	
		SELECT CMD INTO #SBD FROM dbo.BUILD_DB2_SELECT('LGDAT','EFTBD') OPTION (MAXRECURSION 1000);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	
	---------------Build where clause-----------------------------------------------------
	IF @EC = 0
	BEGIN
		SET @SQL = 
			(SELECT CMD FROM #SBD) + 
			+ ' WHERE ETDBTC# >= '
			+ (SELECT CAST(MAX(ETDBTC#) AS VARCHAR(MAX)) FROM LGDAT.EFTBD);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	
	---------------Create table copy------------------------------------------------------
	IF @EC = 0
	BEGIN
		SELECT * INTO #XBD FROM LGDAT.EFTBD WHERE 0=1;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	
	---------------Execute select into copy-----------------------------------------------
	IF @EC = 0
	BEGIN
		INSERT INTO #XBD EXECUTE(@SQL) AT CMS;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	---------------Build merge statement--------------------------------------------------
	IF @EC = 0
	BEGIN
		SELECT CMD INTO #MBD FROM BUILD_MERGE_SMASH('LGDAT','EFTBD','#XBD') OPTION (MAXRECURSION 1000);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	---------------move merge statement to scalar variable--------------------------------
	IF @EC = 0
	BEGIN
		SET @SQL = (SELECT CMD FROM #MBD);
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
		DROP TABLE #XBD;
		DROP TABLE #MBD;
		DROP TABLE #SBD;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	---------------Write to details log---------------------------------------------------
	IF @EC = 0 
	BEGIN
		PRINT 'EFTBD PROCESSED CORRECTLY';
		INSERT INTO CTRL.IMP_DET VALUES (@NV, 'IMPORT_EFTBD', @EC, @PR, GETDATE());
		SET @PR = GETDATE();
		PRINT cast(DATEDIFF(MS,@PR,GETDATE()) as varchar(max)) + ' ms';
	END
	ELSE 
	BEGIN
		PRINT 'EFTBD PROCESSING ISSUE: ' + @EM
		ROLLBACK TRANSACTION PURCH;
		INSERT INTO CTRL.IMP_DET VALUES (@NV, 'IMPORT_EFTBD', @EC, @PR, GETDATE());
		GOTO ERRH
	END

/*-------------------------------------------------------------------------------------------------------------------------------------------------
  ______ ______ _______ ____  _    _ 
 |  ____|  ____|__   __|  _ \| |  | |
 | |__  | |__     | |  | |_) | |__| |
 |  __| |  __|    | |  |  _ <|  __  |
 | |____| |       | |  | |_) | |  | |
 |______|_|       |_|  |____/|_|  |_|
                                     
*/-------------------------------------------------------------------------------------------------------------------------------------------------

	---------------Build select statement-------------------------------------------------
	IF @EC = 0
	BEGIN	
		SELECT CMD INTO #SBH FROM dbo.BUILD_DB2_SELECT('LGDAT','EFTBH') OPTION (MAXRECURSION 1000);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	
	---------------Build where clause-----------------------------------------------------
	IF @EC = 0
	BEGIN
		SET @SQL = 
			(SELECT CMD FROM #SBH) + 
			+ ' WHERE ETHBTC# >= '
			+ (SELECT CAST(MAX(ETHBTC#) AS VARCHAR(MAX)) FROM LGDAT.EFTBH);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	
	---------------Create table copy------------------------------------------------------
	IF @EC = 0
	BEGIN
		SELECT * INTO #XBH FROM LGDAT.EFTBH WHERE 0=1;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	
	---------------Execute select into copy-----------------------------------------------
	IF @EC = 0
	BEGIN
		INSERT INTO #XBH EXECUTE(@SQL) AT CMS;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	---------------Build merge statement--------------------------------------------------
	IF @EC = 0
	BEGIN
		SELECT CMD INTO #MBH FROM BUILD_MERGE_SMASH('LGDAT','EFTBH','#XBH') OPTION (MAXRECURSION 1000);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	---------------move merge statement to scalar variable--------------------------------
	IF @EC = 0
	BEGIN
		SET @SQL = (SELECT CMD FROM #MBH);
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
		DROP TABLE #XBH;
		DROP TABLE #MBH;
		DROP TABLE #SBH;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	---------------Write to details log---------------------------------------------------
	IF @EC = 0 
	BEGIN
		PRINT 'EFTBH PROCESSED CORRECTLY';
		INSERT INTO CTRL.IMP_DET VALUES (@NV, 'IMPORT_EFTBH', @EC, @PR, GETDATE());
		SET @PR = GETDATE();
		PRINT cast(DATEDIFF(MS,@PR,GETDATE()) as varchar(max)) + ' ms';
	END
	ELSE 
	BEGIN
		PRINT 'EFTBH PROCESSING ISSUE: ' + @EM
		ROLLBACK TRANSACTION PURCH;
		INSERT INTO CTRL.IMP_DET VALUES (@NV, 'IMPORT_EFTBH', @EC, @PR, GETDATE());
		GOTO ERRH
	END

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
  _    _  _____ _    _  ____  
 | |  | |/ ____| |  | |/ __ \ 
 | |  | | |    | |__| | |  | |
 | |  | | |    |  __  | |  | |
 | |__| | |____| |  | | |__| |
  \____/ \_____|_|  |_|\___\_\
                                     
*/-------------------------------------------------------------------------------------------------------------------------------------------------

	---------------Create initial select--------------------------------------------------
	IF @EC = 0
	BEGIN	
		SELECT CMD INTO #SU FROM dbo.BUILD_DB2_SELECT('LGDAT','UCHQ') OPTION (MAXRECURSION 1000);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	
	---------------Build where clause-----------------------------------------------------
	IF @EC = 0
	BEGIN
		---------get all local checks where status is open and issued post acquisition and bank is not p. get the min date.
		---------get all db2 checks after this date
		SET @SQL = 
			(SELECT CMD FROM #SU)
			+ ' WHERE IEDATE >= '''
			+ (SELECT CAST(MIN(IEDATE) AS VARCHAR(MAX)) FROM LGDAT.UCHQ WHERE IESTS = 'O' AND IEDATE >= '2015-02-18' AND IEBNK# <> 'P') + '''';
		SELECT @SQL;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	---------------Create table copy------------------------------------------------------
	IF @EC = 0
	BEGIN
		SELECT * INTO #XU FROM LGDAT.UCHQ WHERE 0=1;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	---------------Execute select---------------------------------------------------------
	IF @EC = 0
	BEGIN
		INSERT INTO #XU EXECUTE(@SQL) AT CMS
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	---------------Build merge statement--------------------------------------------------
	IF @EC = 0
	BEGIN
		SELECT CMD INTO #MU FROM dbo.BUILD_MERGE_SMASH('LGDAT','UCHQ','#XU');
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	---------------Move merge to scalar variable------------------------------------------
	IF @EC = 0
	BEGIN
		SET @SQL = (SELECT CMD FROM #MU);
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
		DROP TABLE #SU
		DROP TABLE #MU
		DROP TABLE #XU
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	---------------Write to details log---------------------------------------------------
	IF @EC = 0 
	BEGIN
		PRINT 'UCHQ PROCESSED CORRECTLY';
		INSERT INTO CTRL.IMP_DET VALUES (@NV, 'IMPORT_UCHQ', @EC, @PR, GETDATE());
		SET @PR = GETDATE();
		PRINT cast(DATEDIFF(MS,@PR,GETDATE()) as varchar(max)) + ' ms';
	END
	ELSE 
	BEGIN
		PRINT 'UCHQ PROCESSING ISSUE: ' + @EM
		ROLLBACK TRANSACTION PURCH;
		INSERT INTO CTRL.IMP_DET VALUES (@NV, 'IMPORT_UCHQ', @EC, @PR, GETDATE());
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

	/*----------------------------------------------------------------------------------------------------------------------------

   _____ _       _____ ____          _____  
  / ____| |     / ____|  _ \   /\   |  __ \ 
 | |  __| |    | (___ | |_) | /  \  | |__) |
 | | |_ | |     \___ \|  _ < / /\ \ |  ___/ 
 | |__| | |____ ____) | |_) / ____ \| |     
  \_____|______|_____/|____/_/    \_\_|     
                                            

	*/----------------------------------------------------------------------------------------------------------------------------


	---------------Get max periods & post dates of current copy---------------------------
	IF @EC = 0
	BEGIN
		EXEC @EC = R.LAST_GLSBAP @AGG OUTPUT;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	---------------Build select with where------------------------------------------------
	IF @EC = 0
	BEGIN
		SET @SQL = 
			'SELECT DKACC#, DKFSPR, DKJRTP, DKTDAT, DKSRCE, DKAMT, DKREF#, DKREFD, DKADDD, DKREV, DKREVS, DKFSYR, DKFSYY, DKPOST, DKPDAT, DKBTC#, DKQUAL, DKKEYN, DKPART, DKPJNM, DKQTY, DKUNIT, DKFUT1, DKFUT2, DKFUT3, DKFUT4, DKFUT5, DKFUT6, DKFUT7, DKFUT8, DKFUT9, DKFUT10, DKFUT11, DKFUT12, DKFUT13, DKFUT14, DKFUT15, DKFUT16, DKFUT17, DKFUT18, DKFUT19, DKFUT20, DKEMCD, DKMINS, DKTERR, DKORD#, DKBCUS, DKLABH, DKCPYT, DKCPYF, DKCLSC, DKCFAN, DKJRNN, DKMJSC, DKBCID, DKBSRF, DKRCID, DKTMS FROM LGDAT.GLSBAP'
			+ ' WHERE DKPOST = ''Y'' AND DKBTC# IN (SELECT DISTINCT DKBTC# FROM LGDAT.GTRAN WHERE ' 
			+ @AGG 
			+ ') AND (DKRCID >= '
			+ (SELECT CAST(MAX(DKRCID) AS VARCHAR(MAX)) FROM LGDAT.GLSBAP)
			+ ' OR DKRCID = 0)'
		SELECT @SQL;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	
	---------------Manually build temptable without sequence field at end-----------------
	IF @EC = 0
	BEGIN
		CREATE TABLE #X
		(
			DKACC# numeric(12, 0) NULL,
			DKFSPR numeric(2, 0) NULL,
			DKJRTP varchar(1) NULL,
			DKTDAT date NULL,
			DKSRCE varchar(2) NULL,
			DKAMT numeric(14, 2) NULL,
			DKREF# varchar(10) NULL,
			DKREFD varchar(30) NULL,
			DKADDD varchar(30) NULL,
			DKREV varchar(1) NULL,
			DKREVS varchar(1) NULL,
			DKFSYR numeric(2, 0) NULL,
			DKFSYY numeric(2, 0) NULL,
			DKPOST varchar(1) NULL,
			DKPDAT date NULL,
			DKBTC# numeric(9, 0) NULL,
			DKQUAL varchar(2) NULL,
			DKKEYN varchar(20) NULL,
			DKPART varchar(20) NULL,
			DKPJNM varchar(20) NULL,
			DKQTY numeric(15, 5) NULL,
			DKUNIT varchar(3) NULL,
			DKFUT1 varchar(1) NULL,
			DKFUT2 varchar(1) NULL,
			DKFUT3 varchar(1) NULL,
			DKFUT4 varchar(10) NULL,
			DKFUT5 varchar(10) NULL,
			DKFUT6 varchar(20) NULL,
			DKFUT7 numeric(5, 0) NULL,
			DKFUT8 varchar(3) NULL,
			DKFUT9 varchar(3) NULL,
			DKFUT10 varchar(5) NULL,
			DKFUT11 varchar(5) NULL,
			DKFUT12 varchar(10) NULL,
			DKFUT13 varchar(10) NULL,
			DKFUT14 numeric(11, 2) NULL,
			DKFUT15 numeric(11, 2) NULL,
			DKFUT16 numeric(15, 5) NULL,
			DKFUT17 numeric(15, 5) NULL,
			DKFUT18 varchar(1) NULL,
			DKFUT19 varchar(1) NULL,
			DKFUT20 varchar(1) NULL,
			DKEMCD varchar(5) NULL,
			DKMINS varchar(3) NULL,
			DKTERR varchar(4) NULL,
			DKORD# numeric(9, 0) NULL,
			DKBCUS varchar(8) NULL,
			DKLABH numeric(11, 2) NULL,
			DKCPYT varchar(1) NULL,
			DKCPYF varchar(1) NULL,
			DKCLSC varchar(1) NULL,
			DKCFAN numeric(12, 0) NULL,
			DKJRNN numeric(5, 0) NULL,
			DKMJSC varchar(3) NULL,
			DKBCID numeric(12, 0) NULL,
			DKBSRF varchar(1) NULL,
			DKRCID numeric(12, 0) NULL,
			DKTMS datetime2(7) NULL
		);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	
	---------------Execute select---------------------------------------------------------
	IF @EC = 0
	BEGIN
		INSERT INTO #X EXECUTE(@SQL) AT CMS;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	---------------Delete from the local copy any rcid = 0 for overwrite------------------
	IF @EC = 0
	BEGIN
		DELETE FROM LGDAT.GLSBAP WHERE DKPOST = 'Y' AND DKBTC# IN (SELECT DISTINCT DKBTC# FROM #X WHERE DKRCID = 0);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	PRINT 'DELETE COMPLETE';

	---------------Merge records where rcid <> 0------------------------------------------
	IF @EC = 0
	BEGIN
		MERGE LGDAT.GLSBAP A
		USING (SELECT * FROM #X WHERE DKRCID <> 0) B
			ON A.DKRCID = B.DKRCID
		WHEN MATCHED
			THEN
				UPDATE
				SET DKACC# = B.DKACC#,
					DKFSPR = B.DKFSPR,
					DKJRTP = B.DKJRTP,
					DKTDAT = B.DKTDAT,
					DKSRCE = B.DKSRCE,
					DKAMT = B.DKAMT,
					DKREF# = B.DKREF#,
					DKREFD = B.DKREFD,
					DKADDD = B.DKADDD,
					DKREV = B.DKREV,
					DKREVS = B.DKREVS,
					DKFSYR = B.DKFSYR,
					DKFSYY = B.DKFSYY,
					DKPOST = B.DKPOST,
					DKPDAT = B.DKPDAT,
					DKBTC# = B.DKBTC#,
					DKQUAL = B.DKQUAL,
					DKKEYN = B.DKKEYN,
					DKPART = B.DKPART,
					DKPJNM = B.DKPJNM,
					DKQTY = B.DKQTY,
					DKUNIT = B.DKUNIT,
					DKFUT1 = B.DKFUT1,
					DKFUT2 = B.DKFUT2,
					DKFUT3 = B.DKFUT3,
					DKFUT4 = B.DKFUT4,
					DKFUT5 = B.DKFUT5,
					DKFUT6 = B.DKFUT6,
					DKFUT7 = B.DKFUT7,
					DKFUT8 = B.DKFUT8,
					DKFUT9 = B.DKFUT9,
					DKFUT10 = B.DKFUT10,
					DKFUT11 = B.DKFUT11,
					DKFUT12 = B.DKFUT12,
					DKFUT13 = B.DKFUT13,
					DKFUT14 = B.DKFUT14,
					DKFUT15 = B.DKFUT15,
					DKFUT16 = B.DKFUT16,
					DKFUT17 = B.DKFUT17,
					DKFUT18 = B.DKFUT18,
					DKFUT19 = B.DKFUT19,
					DKFUT20 = B.DKFUT20,
					DKEMCD = B.DKEMCD,
					DKMINS = B.DKMINS,
					DKTERR = B.DKTERR,
					DKORD# = B.DKORD#,
					DKBCUS = B.DKBCUS,
					DKLABH = B.DKLABH,
					DKCPYT = B.DKCPYT,
					DKCPYF = B.DKCPYF,
					DKCLSC = B.DKCLSC,
					DKCFAN = B.DKCFAN,
					DKJRNN = B.DKJRNN,
					DKMJSC = B.DKMJSC,
					DKBCID = B.DKBCID,
					DKBSRF = B.DKBSRF,
					DKTMS = B.DKTMS
		WHEN NOT MATCHED
			THEN
				INSERT (
					DKACC#,
					DKFSPR,
					DKJRTP,
					DKTDAT,
					DKSRCE,
					DKAMT,
					DKREF#,
					DKREFD,
					DKADDD,
					DKREV,
					DKREVS,
					DKFSYR,
					DKFSYY,
					DKPOST,
					DKPDAT,
					DKBTC#,
					DKQUAL,
					DKKEYN,
					DKPART,
					DKPJNM,
					DKQTY,
					DKUNIT,
					DKFUT1,
					DKFUT2,
					DKFUT3,
					DKFUT4,
					DKFUT5,
					DKFUT6,
					DKFUT7,
					DKFUT8,
					DKFUT9,
					DKFUT10,
					DKFUT11,
					DKFUT12,
					DKFUT13,
					DKFUT14,
					DKFUT15,
					DKFUT16,
					DKFUT17,
					DKFUT18,
					DKFUT19,
					DKFUT20,
					DKEMCD,
					DKMINS,
					DKTERR,
					DKORD#,
					DKBCUS,
					DKLABH,
					DKCPYT,
					DKCPYF,
					DKCLSC,
					DKCFAN,
					DKJRNN,
					DKMJSC,
					DKBCID,
					DKBSRF,
					DKRCID,
					DKTMS,
					GLSBAP_ID
					)
				VALUES (
					B.DKACC#,
					B.DKFSPR,
					B.DKJRTP,
					B.DKTDAT,
					B.DKSRCE,
					B.DKAMT,
					B.DKREF#,
					B.DKREFD,
					B.DKADDD,
					B.DKREV,
					B.DKREVS,
					B.DKFSYR,
					B.DKFSYY,
					B.DKPOST,
					B.DKPDAT,
					B.DKBTC#,
					B.DKQUAL,
					B.DKKEYN,
					B.DKPART,
					B.DKPJNM,
					B.DKQTY,
					B.DKUNIT,
					B.DKFUT1,
					B.DKFUT2,
					B.DKFUT3,
					B.DKFUT4,
					B.DKFUT5,
					B.DKFUT6,
					B.DKFUT7,
					B.DKFUT8,
					B.DKFUT9,
					B.DKFUT10,
					B.DKFUT11,
					B.DKFUT12,
					B.DKFUT13,
					B.DKFUT14,
					B.DKFUT15,
					B.DKFUT16,
					B.DKFUT17,
					B.DKFUT18,
					B.DKFUT19,
					B.DKFUT20,
					B.DKEMCD,
					B.DKMINS,
					B.DKTERR,
					B.DKORD#,
					B.DKBCUS,
					B.DKLABH,
					B.DKCPYT,
					B.DKCPYF,
					B.DKCLSC,
					B.DKCFAN,
					B.DKJRNN,
					B.DKMJSC,
					B.DKBCID,
					B.DKBSRF,
					B.DKRCID,
					B.DKTMS,
					DEFAULT
					);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	PRINT 'MERGE COMPLETE';

	---------------Insert rcid= 0 and include next sequence-------------------------------
	IF @EC = 0
	BEGIN
		INSERT INTO LGDAT.GLSBAP SELECT *, NEXT VALUE FOR LGDAT.GLSBAP_SEQ FROM #X WHERE DKRCID = 0;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	PRINT 'INSERT COMPLETE';

	---------------Drop temp table--------------------------------------------------------
	IF @EC = 0
	BEGIN
		DROP TABLE #X;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END


	---------------Write to details log---------------------------------------------------
	IF @EC = 0 
	BEGIN
		PRINT 'GLSBAP PROCESSED CORRECTLY';
		INSERT INTO CTRL.IMP_DET VALUES (@NV, 'IMPORT_GLSBAP', @EC, @PR, GETDATE());
		SET @PR = GETDATE();
		PRINT cast(DATEDIFF(MS,@PR,GETDATE()) as varchar(max)) + ' ms';
	END
	ELSE 
	BEGIN
		PRINT 'GLSBAP PROCESSING ISSUE: ' + @EM
		ROLLBACK TRANSACTION PURCH;
		INSERT INTO CTRL.IMP_DET VALUES (@NV, 'IMPORT_GLSBAP', @EC, @PR, GETDATE());
		GOTO ERRH
	END

/*----------------------------------------------------------------------------------------------------------------------------
 __      ________ _   _ _____  
 \ \    / /  ____| \ | |  __ \ 
  \ \  / /| |__  |  \| | |  | |
   \ \/ / |  __| | . ` | |  | |
    \  /  | |____| |\  | |__| |
     \/   |______|_| \_|_____/ 
                               
*/---------------------------------------------------------------------------------------------------------------------------

	---------------build select-----------------------------------------------------------
	IF @EC = 0
	BEGIN	
		SELECT CMD INTO #SVE FROM dbo.BUILD_DB2_SELECT('LGDAT','VEND') OPTION (MAXRECURSION 1000);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	
	---------------build where clause-----------------------------------------------------
	IF @EC = 0
	BEGIN
		SET @SQL = 
			(SELECT CMD FROM #SVE) + 
			+ ' WHERE BTUDAT >= '''
			+ (SELECT CAST(MAX(BTUDAT) AS VARCHAR(MAX)) FROM LGDAT.VEND)
			+ ''' OR BTCDAT >= '''
			+ (SELECT CAST(MAX(BTUDAT) AS VARCHAR(MAX)) FROM LGDAT.VEND)
			+ '''';
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	
	---------------create copy of target table--------------------------------------------
	IF @EC = 0
	BEGIN
		SELECT * INTO #XVE FROM LGDAT.VEND WHERE 0=1;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	
	---------------execute sql to copy----------------------------------------------------
	IF @EC = 0
	BEGIN
		INSERT INTO #XVE EXECUTE(@SQL) AT CMS;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	
	---------------build merge statement--------------------------------------------------
	IF @EC = 0
	BEGIN
		SELECT * INTO #MVE FROM BUILD_MERGE_SMASH('LGDAT','VEND','#XVE') OPTION (MAXRECURSION 1000);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	---------------move merge to scalar variable------------------------------------------
	IF @EC = 0
	BEGIN
		SET @SQL = (SELECT CMD FROM #MVE);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	
	---------------execute merge----------------------------------------------------------
	IF @EC = 0
	BEGIN
		EXECUTE(@SQL);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	
	---------------drop temp tables-------------------------------------------------------
	IF @EC = 0
	BEGIN
		DROP TABLE #XVE;
		DROP TABLE #MVE;
		DROP TABLE #SVE;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	---------------Write to details log---------------------------------------------------
	IF @EC = 0 
	BEGIN
		PRINT 'VEND PROCESSED CORRECTLY';
		INSERT INTO CTRL.IMP_DET VALUES (@NV, 'IMPORT_VEND', @EC, @PR, GETDATE());
		SET @PR = GETDATE();
		PRINT cast(DATEDIFF(MS,@PR,GETDATE()) as varchar(max)) + ' ms';
	END
	ELSE 
	BEGIN
		PRINT 'VEND PROCESSING ISSUE: ' + @EM
		ROLLBACK TRANSACTION PURCH;
		INSERT INTO CTRL.IMP_DET VALUES (@NV, 'IMPORT_VEND', @EC, @PR, GETDATE());
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