ALTER PROC FANALYSIS.LGDAT.IMPORT_R_PRODUCTION AS
BEGIN
	
	

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
	DECLARE @I VARCHAR(MAX);		--oid sql
	DECLARE @H VARCHAR(MAX);		--oih sql
	DECLARE @Y INT;					--max year
	DECLARE @P INT;					--max period
	DECLARE @AGG VARCHAR(MAX)		--batches for glsbiv where clause
	DECLARE @F VARCHAR(MAX)			--max nwfut9 value

	--NEED TO TAKE A SNAPSHOT OF MAX NWFUT9 A THE BEGINNING AND THEN MAKE SURE THAT IS THE UPPER RANGE ON ALL TABLES INCLUDING RPRH
	--IN CASE THERE IS POSTING FROM INITIAL TABLE QUERY TO RPRH TABLE QUERY WHICH WOUDL LOCK OUT UPDATING OF THE DROPPED TRANS

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
	
	PRINT 'LINE 1'
	
	
	----------------POPULATE ERROR VARIABLES-----------------------------------------------
	SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();



	----------------GET NEXT JOB# IN SEQUNCE-----------------------------------------------
	SELECT @NV = NEXT VALUE FOR CTRL.MASTER_IMPORT;

	PRINT 'GOT NEXT SEQ: ' + CAST(@NV AS VARCHAR(MAX))

	----------------SEE IF THERE ARE ANY GLOBAL LOCKS--------------------------------------
	IF @EC = 0 
	BEGIN
		SELECT @S = (SELECT COUNT(*) CNT FROM CTRL.IMP_JOB WHERE GLOB_LOCK = 1);
		SELECT @EC = @@ERROR;
	END

	PRINT 'COUNT JOB LOG: ' + CAST(@S AS VARCHAR(MAX))

	----------------INSERT JOB TO LOG------------------------------------------------------
	IF @EC = 0
	BEGIN
		IF @S <> 0
		BEGIN
			INSERT INTO 
				CTRL.IMP_JOB 
			VALUES
				(@NV,CURRENT_USER,APP_NAME(),'IMPORT_R_PRODUCTION','NOT STARTED - JOB IN PROCESS',0,GETDATE(),GETDATE(),0);
			SET @EC = @@ERROR;
			GOTO ERRH
		END
		BEGIN
			INSERT INTO 
				CTRL.IMP_JOB 
			VALUES
				(@NV,CURRENT_USER,APP_NAME(),'IMPORT_R_PRODUCTION','PROCESSING',0,GETDATE(),NULL,1);
			SET @EC = @@ERROR;
		END
	END

	PRINT 'FINISH LOG INSERT'
	--SELECT * FROM CTRL.IMP_JOB WHERE ID = @NV
			
	---------------@st hold the start of the beginning of processing----------------------
	SET @ST = GETDATE()
	SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED;


	-----PRODUCTION REPORTING-----------------------------
	--all these have to be updated prior to updating RPRH.
	--if any fails and then RPRH updates anyways, sync will be lost and must manually sync up
	--use above error handling to stop procedure.

	--need to add a check that tests that all RPRH batches have an RPR% offset.
	--this gap could arise if RPRM batches are pulled and then after that but before RPRH is update more batches are enteres in CMS
	
	

	BEGIN TRANSACTION PRODUCTION
					  	

	SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	IF @EC = 0
	BEGIN
		CREATE TABLE #F(F VARCHAR(MAX));
		INSERT INTO #F EXECUTE ('SELECT MAX(NWFUT9) FROM LGDAT.RPRH WHERE NWPOST = ''Y''') AT CMS;
		SELECT @F = (SELECT F FROM #F);
		DROP TABLE #F;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	PRINT 'GOT MAX NWFUT9: ' + @F

/*---------------------------------------------------------------------------------------------------------------------------------------
  _____    _____    _____    _____  
 |  __ \  |  __ \  |  __ \  |  __ \ 
 | |__) | | |__) | | |__) | | |__) |
 |  _  /  |  ___/  |  _  /  |  ___/ 
 | | \ \  | |      | | \ \  | |     
 |_|  \_\ |_|      |_|  \_\ |_|     
                                    
*/---------------------------------------------------------------------------------------------------------------------------------------
	

	IF @EC = 0
	BEGIN	
		SELECT @SQL = 
			(SELECT CMD FROM dbo.BUILD_DB2_SELECT('LGDAT','RPRP')) +  
			' WHERE OEBTID IN (SELECT NWBTID FROM LGDAT.RPRH WHERE NWPOST = ''Y'' AND NWFUT9 >= ' + 
			(SELECT CAST(MAX(NWFUT9) AS VARCHAR(255)) FROM LGDAT.RPRH) + ' AND NWFUT9 <= ' + @F + ')';
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END


	IF @EC = 0
	BEGIN
		SELECT * INTO #RPRP FROM LGDAT.RPRP WHERE 0=1;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	
	IF @EC = 0
	BEGIN
		INSERT INTO #RPRP EXECUTE(@SQL) AT CMS;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	
	IF @EC = 0
	BEGIN
		SET @SQL = (SELECT CMD FROM dbo.BUILD_MERGE_SMASH('LGDAT','RPRP','#RPRP'));
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	
	
	IF @EC = 0
	BEGIN
		EXECUTE (@SQL);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	
	IF @EC = 0
	BEGIN
		DROP TABLE #RPRP;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	IF @EC = 0 
	BEGIN
		PRINT 'RPRP PROCESSED CORRECTLY';
		INSERT INTO CTRL.IMP_DET VALUES (@NV, 'IMPORT_RPRP', @EC, @PR, GETDATE());
		SET @PR = GETDATE();
		PRINT cast(DATEDIFF(MS,@PR,GETDATE()) as varchar(max)) + ' ms';
	END
	ELSE 
	BEGIN
		PRINT 'RPRP PROCESSING ISSUE: ' + @EM
		ROLLBACK TRANSACTION PRODUCTION;
		INSERT INTO CTRL.IMP_DET VALUES (@NV, 'IMPORT_RPRP', @EC, @PR, GETDATE());
		GOTO ERRH
	END
		
	
	
	

/*---------------------------------------------------------------------------------------------------------------------------------------
  _____    _____    _____     ____  
 |  __ \  |  __ \  |  __ \   / __ \ 
 | |__) | | |__) | | |__) | | |  | |
 |  _  /  |  ___/  |  _  /  | |  | |
 | | \ \  | |      | | \ \  | |__| |
 |_|  \_\ |_|      |_|  \_\  \___\_\
                                    
*/---------------------------------------------------------------------------------------------------------------------------------------


	IF @EC = 0
	BEGIN	
		SELECT @SQL = 
			(SELECT CMD FROM dbo.BUILD_DB2_SELECT('LGDAT','RPRQ')) + 
			' WHERE TIBTID IN (SELECT NWBTID FROM LGDAT.RPRH WHERE NWPOST = ''Y'' AND NWFUT9 >= ' + 
			(SELECT CAST(MAX(NWFUT9) AS VARCHAR(255)) FROM LGDAT.RPRH) + ' AND NWFUT9 <= ' + @F + ')';
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	
	IF @EC = 0
	BEGIN	
		SELECT * INTO #RPRQ FROM LGDAT.RPRQ WHERE 0=1;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	
	IF @EC = 0
	BEGIN	
		INSERT INTO #RPRQ EXECUTE(@SQL) AT CMS;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	
	IF @EC = 0
	BEGIN	
		SET @SQL = (SELECT CMD FROM dbo.BUILD_MERGE_SMASH('LGDAT','RPRQ','#RPRQ'));
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	
	IF @EC = 0
	BEGIN	
		EXECUTE(@SQL);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	
	IF @EC = 0
	BEGIN	
		DROP TABLE #RPRQ;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	IF @EC = 0 
	BEGIN
		PRINT 'RPRQ PROCESSED CORRECTLY';
		INSERT INTO CTRL.IMP_DET VALUES (@NV, 'IMPORT_RPRQ', @EC, @PR, GETDATE());
		SET @PR = GETDATE();
		PRINT cast(DATEDIFF(MS,@PR,GETDATE()) as varchar(max)) + ' ms';
	END
	ELSE 
	BEGIN
		PRINT 'RPRQ PROCESSING ISSUE: ' + @EM
		ROLLBACK TRANSACTION PRODUCTION;
		INSERT INTO CTRL.IMP_DET VALUES (@NV, 'IMPORT_RPRQ', @EC, @PR, GETDATE());
		GOTO ERRH
	END

/*---------------------------------------------------------------------------------------------------------------------------------------
  _____    _____    _____    _____  
 |  __ \  |  __ \  |  __ \  |  __ \ 
 | |__) | | |__) | | |__) | | |  | |
 |  _  /  |  ___/  |  _  /  | |  | |
 | | \ \  | |      | | \ \  | |__| |
 |_|  \_\ |_|      |_|  \_\ |_____/ 
                                    
*/---------------------------------------------------------------------------------------------------------------------------------------

	IF @EC = 0
	BEGIN	
		SELECT @SQL = 
			(SELECT CMD FROM dbo.BUILD_DB2_SELECT('LGDAT','RPRD')) + 
			' WHERE NXBTID IN (SELECT NWBTID FROM LGDAT.RPRH WHERE NWPOST = ''Y'' AND NWFUT9 >= ' + 
			(SELECT CAST(MAX(NWFUT9) AS VARCHAR(255)) FROM LGDAT.RPRH) + ' AND NWFUT9 <= ' + @F + ')';
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	
	IF @EC = 0
	BEGIN	
		SELECT * INTO #RPRD FROM LGDAT.RPRD WHERE 0=1;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END


	
	IF @EC = 0
	BEGIN	
		INSERT INTO #RPRD EXECUTE(@SQL) AT CMS;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	
	IF @EC = 0
	BEGIN	
		SET @SQL = (SELECT CMD FROM dbo.BUILD_MERGE_SMASH('LGDAT','RPRD','#RPRD'));
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	
	IF @EC = 0
	BEGIN	
		EXECUTE	(@SQL);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	
	
	IF @EC = 0
	BEGIN	
		DROP TABLE #RPRD;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	IF @EC = 0 
	BEGIN
		PRINT 'RPRD PROCESSED CORRECTLY';
		INSERT INTO CTRL.IMP_DET VALUES (@NV, 'IMPORT_RPRD', @EC, @PR, GETDATE());
		SET @PR = GETDATE();
		PRINT cast(DATEDIFF(MS,@PR,GETDATE()) as varchar(max)) + ' ms';
	END
	ELSE 
	BEGIN
		PRINT 'RPRD PROCESSING ISSUE: ' + @EM
		ROLLBACK TRANSACTION PRODUCTION;
		INSERT INTO CTRL.IMP_DET VALUES (@NV, 'IMPORT_RPRD', @EC, @PR, GETDATE());
		GOTO ERRH
	END

/*---------------------------------------------------------------------------------------------------------------------------------------
  _____    _____    _____    __  __ 
 |  __ \  |  __ \  |  __ \  |  \/  |
 | |__) | | |__) | | |__) | | \  / |
 |  _  /  |  ___/  |  _  /  | |\/| |
 | | \ \  | |      | | \ \  | |  | |
 |_|  \_\ |_|      |_|  \_\ |_|  |_|
                                    
*/---------------------------------------------------------------------------------------------------------------------------------------



	IF @EC = 0
	BEGIN	
		SELECT @SQL = 
			(SELECT CMD FROM dbo.BUILD_DB2_SELECT('LGDAT','RPRM')) + 
			' WHERE UIBTID IN (SELECT NWBTID FROM LGDAT.RPRH WHERE NWPOST = ''Y'' AND NWFUT9 >= ' + 
			(SELECT CAST(MAX(NWFUT9) AS VARCHAR(255)) FROM LGDAT.RPRH) + ' AND NWFUT9 <= ' + @F + ')';
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	
	IF @EC = 0
	BEGIN
		SELECT * INTO #RPRM FROM LGDAT.RPRM WHERE 0=1;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	
	IF @EC = 0
	BEGIN
		INSERT INTO #RPRM EXECUTE(@SQL) AT CMS;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END


	IF @EC = 0
	BEGIN
		SET @SQL = (SELECT CMD FROM dbo.BUILD_MERGE_SMASH('LGDAT','RPRM','#RPRM'));
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	
	IF @EC = 0
	BEGIN
		EXECUTE (@SQL);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	
	IF @EC = 0
	BEGIN
		DROP TABLE #RPRM;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	IF @EC = 0 
	BEGIN
		PRINT 'RPRM PROCESSED CORRECTLY';
		INSERT INTO CTRL.IMP_DET VALUES (@NV, 'IMPORT_RPRM', @EC, @PR, GETDATE());
		SET @PR = GETDATE();
		PRINT cast(DATEDIFF(MS,@PR,GETDATE()) as varchar(max)) + ' ms';
	END
	ELSE 
	BEGIN
		PRINT 'RPRM PROCESSING ISSUE: ' + @EM
		ROLLBACK TRANSACTION PRODUCTION;
		INSERT INTO CTRL.IMP_DET VALUES (@NV, 'IMPORT_RPRM', @EC, @PR, GETDATE());
		GOTO ERRH
	END

/*---------------------------------------------------------------------------------------------------------------------------------------
  _____    _____    _____    _____  
 |  __ \  |  __ \  |  __ \  |  __ \ 
 | |__) | | |__) | | |__) | | |__) |
 |  _  /  |  ___/  |  _  /  |  _  / 
 | | \ \  | |      | | \ \  | | \ \ 
 |_|  \_\ |_|      |_|  \_\ |_|  \_\
                                    
*/---------------------------------------------------------------------------------------------------------------------------------------

	IF @EC = 0
	BEGIN	
		SELECT @SQL = 
			(SELECT CMD FROM dbo.BUILD_DB2_SELECT('LGDAT','RPRR')) + 
			' WHERE OABTID IN (SELECT NWBTID FROM LGDAT.RPRH WHERE NWPOST = ''Y'' AND NWFUT9 >= ' + 
			(SELECT CAST(MAX(NWFUT9) AS VARCHAR(255)) FROM LGDAT.RPRH) + ' AND NWFUT9 <= ' + @F + ')';
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	
	IF @EC = 0
	BEGIN	
		SELECT * INTO #RPRR FROM LGDAT.RPRR WHERE 0=1;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	
	IF @EC = 0
	BEGIN	
		INSERT INTO #RPRR EXECUTE(@SQL) AT CMS;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	
	IF @EC = 0
	BEGIN	
		SET @SQL = (SELECT CMD FROM dbo.BUILD_MERGE_SMASH('LGDAT','RPRR','#RPRR'));
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	
	IF @EC = 0
	BEGIN	
		EXECUTE(@SQL);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	
	IF @EC = 0
	BEGIN	
		DROP TABLE #RPRR;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	IF @EC = 0 
	BEGIN
		PRINT 'RPRR PROCESSED CORRECTLY';
		INSERT INTO CTRL.IMP_DET VALUES (@NV, 'IMPORT_RPRR', @EC, @PR, GETDATE());
		SET @PR = GETDATE();
		PRINT cast(DATEDIFF(MS,@PR,GETDATE()) as varchar(max)) + ' ms';
	END
	ELSE 
	BEGIN
		PRINT 'RPRR PROCESSING ISSUE: ' + @EM
		ROLLBACK TRANSACTION PRODUCTION;
		INSERT INTO CTRL.IMP_DET VALUES (@NV, 'IMPORT_RPRR', @EC, @PR, GETDATE());
		GOTO ERRH
	END


/*---------------------------------------------------------------------------------------------------------------------------------------
  _____    _____    _____    _      
 |  __ \  |  __ \  |  __ \  | |     
 | |__) | | |__) | | |__) | | |     
 |  _  /  |  ___/  |  _  /  | |     
 | | \ \  | |      | | \ \  | |____ 
 |_|  \_\ |_|      |_|  \_\ |______|
                                    
*/---------------------------------------------------------------------------------------------------------------------------------------
	
	IF @EC = 0
	BEGIN	
		SELECT @SQL = 
			(SELECT CMD FROM dbo.BUILD_DB2_SELECT('LGDAT','RPRL')) + 
			' WHERE TPBTID IN (SELECT NWBTID FROM LGDAT.RPRH WHERE NWPOST = ''Y'' AND NWFUT9 >= ' + 
			(SELECT CAST(MAX(NWFUT9) AS VARCHAR(255)) FROM LGDAT.RPRH) + ' AND NWFUT9 <= ' + @F + ')';
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	
	IF @EC = 0
	BEGIN	
		SELECT * INTO #RPRL FROM LGDAT.RPRL WHERE 0=1;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	
	IF @EC = 0
	BEGIN	
		INSERT INTO #RPRL EXECUTE(@SQL) AT CMS;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	
	IF @EC = 0
	BEGIN	
		SET @SQL = (SELECT CMD FROM dbo.BUILD_MERGE_SMASH('LGDAT','RPRL','#RPRL'));
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	
	IF @EC = 0
	BEGIN	
		EXECUTE (@SQL);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	
	IF @EC = 0
	BEGIN	
		DROP TABLE #RPRL;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	IF @EC = 0 
	BEGIN
		PRINT 'RPRL PROCESSED CORRECTLY';
		INSERT INTO CTRL.IMP_DET VALUES (@NV, 'IMPORT_RPRL', @EC, @PR, GETDATE());
		SET @PR = GETDATE();
		PRINT cast(DATEDIFF(MS,@PR,GETDATE()) as varchar(max)) + ' ms';
	END
	ELSE 
	BEGIN
		PRINT 'RPRL PROCESSING ISSUE: ' + @EM
		ROLLBACK TRANSACTION PRODUCTION;
		INSERT INTO CTRL.IMP_DET VALUES (@NV, 'IMPORT_RPRL', @EC, @PR, GETDATE());
		GOTO ERRH
	END


/*---------------------------------------------------------------------------------------------------------------------------------------
  _____    _____    _____    _   _ 
 |  __ \  |  __ \  |  __ \  | \ | |
 | |__) | | |__) | | |__) | |  \| |
 |  _  /  |  ___/  |  _  /  | . ` |
 | | \ \  | |      | | \ \  | |\  |
 |_|  \_\ |_|      |_|  \_\ |_| \_|
                                   
*/---------------------------------------------------------------------------------------------------------------------------------------
	
	IF @EC = 0
	BEGIN	
		SELECT @SQL = 
			(SELECT CMD FROM dbo.BUILD_DB2_SELECT('LGDAT','RPRN')) + 
			' WHERE AL1BTID IN (SELECT NWBTID FROM LGDAT.RPRH WHERE NWPOST = ''Y'' AND NWFUT9 >= ' + 
			(SELECT CAST(MAX(NWFUT9) AS VARCHAR(255)) FROM LGDAT.RPRH) + ' AND NWFUT9 <= ' + @F + ')';
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	
	IF @EC = 0
	BEGIN	
		SELECT * INTO #RPRN FROM LGDAT.RPRN WHERE 0=1;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	
	IF @EC = 0
	BEGIN	
		INSERT INTO #RPRN EXECUTE(@SQL) AT CMS;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	
	IF @EC = 0
	BEGIN	
		SET @SQL = (SELECT CMD FROM dbo.BUILD_MERGE_SMASH('LGDAT','RPRN','#RPRN'));
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	
	IF @EC = 0
	BEGIN	
		EXECUTE(@SQL);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	
	IF @EC = 0
	BEGIN	
		DROP TABLE #RPRN;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	IF @EC = 0 
	BEGIN
		PRINT 'RPRN PROCESSED CORRECTLY';
		INSERT INTO CTRL.IMP_DET VALUES (@NV, 'IMPORT_RPRN', @EC, @PR, GETDATE());
		SET @PR = GETDATE();
		PRINT cast(DATEDIFF(MS,@PR,GETDATE()) as varchar(max)) + ' ms';
	END
	ELSE 
	BEGIN
		PRINT 'RPRN PROCESSING ISSUE: ' + @EM
		ROLLBACK TRANSACTION PRODUCTION;
		INSERT INTO CTRL.IMP_DET VALUES (@NV, 'IMPORT_RPRN', @EC, @PR, GETDATE());
		GOTO ERRH
	END

/*---------------------------------------------------------------------------------------------------------------------------------------
  _____    _____    _____    _    _ 
 |  __ \  |  __ \  |  __ \  | |  | |
 | |__) | | |__) | | |__) | | |__| |
 |  _  /  |  ___/  |  _  /  |  __  |
 | | \ \  | |      | | \ \  | |  | |
 |_|  \_\ |_|      |_|  \_\ |_|  |_|
                                    
*/---------------------------------------------------------------------------------------------------------------------------------------
	

	IF @EC = 0
	BEGIN	
		SET @SQL = 
			(SELECT CMD FROM dbo.BUILD_DB2_SELECT('LGDAT','RPRH')) + 
			' WHERE NWPOST = ''Y'' AND NWFUT9 >= ' + 
			(SELECT CAST(MAX(NWFUT9) AS VARCHAR(255)) FROM LGDAT.RPRH) + ' AND NWFUT9 <= ' + @F;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	
	IF @EC = 0
	BEGIN
		SELECT * INTO #RPRH FROM LGDAT.RPRH WHERE 0=1;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	
	IF @EC = 0
	BEGIN
		INSERT INTO #RPRH EXECUTE (@SQL) AT CMS;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	
	IF @EC = 0
	BEGIN
		SET @SQL = (SELECT CMD FROM dbo.BUILD_MERGE_SMASH('LGDAT','RPRH','#RPRH'));
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	
	IF @EC = 0
	BEGIN
		EXECUTE (@SQL);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	
	IF @EC = 0
	BEGIN
		DROP TABLE #RPRH;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	IF @EC = 0 
	BEGIN
		PRINT 'RPRH PROCESSED CORRECTLY';
		INSERT INTO CTRL.IMP_DET VALUES (@NV, 'IMPORT_RPRH', @EC, @PR, GETDATE());
		SET @PR = GETDATE();
		PRINT cast(DATEDIFF(MS,@PR,GETDATE()) as varchar(max)) + ' ms';
	END
	ELSE 
	BEGIN
		PRINT 'RPRH PROCESSING ISSUE: ' + @EM
		ROLLBACK TRANSACTION PRODUCTION;
		PRINT 'TRANSACTION ROLLED BACK';
		INSERT INTO CTRL.IMP_DET VALUES (@NV, 'IMPORT_RPRH', @EC, @PR, GETDATE());
		GOTO ERRH
	END

/*---------------------------------------------------------------------------------------------------------------------------------------
   _____   _         _____   ____    _____  __      __
  / ____| | |       / ____| |  _ \  |_   _| \ \    / /
 | |  __  | |      | (___   | |_) |   | |    \ \  / / 
 | | |_ | | |       \___ \  |  _ <    | |     \ \/ /  
 | |__| | | |____   ____) | | |_) |  _| |_     \  /   
  \_____| |______| |_____/  |____/  |_____|     \/    
                                                      
*/---------------------------------------------------------------------------------------------------------------------------------------

	IF @EC = 0
	BEGIN	
		SELECT CMD INTO #S FROM dbo.BUILD_DB2_SELECT('LGDAT','GLSBIV') OPTION (MAXRECURSION 1000);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	
	IF @EC = 0
	BEGIN
		EXEC @EC = R.LAST_GLSBIV @AGG OUTPUT;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	IF @EC = 0
	BEGIN
		SET @SQL = 
			(SELECT CMD FROM #S)
			+ ' WHERE DKPOST = ''Y'' AND DKBTC# IN (SELECT DISTINCT DKBTC# FROM LGDAT.GTRAN WHERE ' 
			+ @AGG 
			+ ') AND DKRCID >= '
			+ (SELECT CAST(MAX(DKRCID) AS VARCHAR(MAX)) FROM LGDAT.GLSBIV);
		--SELECT @SQL;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	

	IF @EC = 0
	BEGIN
		SELECT * INTO #X FROM LGDAT.GLSBIV WHERE 0=1;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	

	IF @EC = 0
	BEGIN
		INSERT INTO #X EXECUTE(@SQL) AT CMS;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	

	IF @EC = 0
	BEGIN
		SELECT * INTO #M FROM BUILD_MERGE_SMASH('LGDAT','GLSBIV','#X') OPTION (MAXRECURSION 1000);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	
	IF @EC = 0
	BEGIN
		SET @SQL = (SELECT CMD FROM #M);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	

	IF @EC = 0
	BEGIN
		EXECUTE(@SQL);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	

	IF @EC = 0
	BEGIN
		DROP TABLE #X;
		DROP TABLE #M;
		DROP TABLE #S;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	IF @EC = 0 
	BEGIN
		PRINT 'GLSBIV PROCESSED CORRECTLY';
		INSERT INTO CTRL.IMP_DET VALUES (@NV, 'IMPORT_GLSBIV', @EC, @PR, GETDATE());
		SET @PR = GETDATE();
		PRINT cast(DATEDIFF(MS,@PR,GETDATE()) as varchar(max)) + ' ms';
	END
	ELSE 
	BEGIN
		PRINT 'GLSBIV PROCESSING ISSUE: ' + @EM
		ROLLBACK TRANSACTION PRODUCTION;
		INSERT INTO CTRL.IMP_DET VALUES (@NV, 'IMPORT_GLSBIV', @EC, @PR, GETDATE());
		GOTO ERRH
	END

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
			COMMIT TRANSACTION PRODUCTION;
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




