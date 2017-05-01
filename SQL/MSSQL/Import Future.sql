BEGIN

	--GET MAX DKRCID FROM GLSBAR AS MIN
	--UPDATE GLSBAR
	--GET MAX DCRCID FROM GLSBAR AS MAX
	--QUERY OID FOR INVOICES IN: 
		--GLSBAR WHERE IN MAX DKRCID RANGE AND 
		--FROM OIH WHERE DHTOTI = 0 AND CURRENT PERIOD AND NOT IN LIST FROM LOCAL (BUILD OUT)
	--SAME FOR OIH
	--NEED TO BE ABLE TO UPDATE UNPOSTED INVOICES AS WELL FOR REPORTING OUT ON THAT

	

	DECLARE @EC INT;				--error code
	DECLARE @EM VARCHAR(MAX);		--error message
	DECLARE @SQL VARCHAR(MAX);		--sql holder
	DECLARE @MAXRC VARCHAR(MAX);	--max target record
	DECLARE @MINRC VARCHAR(MAX);	--minimum target record
	DECLARE @MINP VARCHAR(MAX);		--current period to target
	DECLARE @ILIST VARCHAR(MAX);	--aggregate list ov invoices
	DECLARE @I VARCHAR(MAX);		--next cursor value
	DECLARE @ST DATETIME2;			--start time
	DECLARE @PR DATETIME2;			--prior start
	DECLARE @NV BIGINT;				--next sequence value
	DECLARE @S BIGINT;				--count of rows
	DECLARE @AGG VARCHAR(MAX)		--last transactions clause

	SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();

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

	----------------GET NEXT JOB# IN SEQUNCE-----------------------------------------------
	SELECT @NV = NEXT VALUE FOR CTRL.MASTER_IMPORT;


	----------------SEE IF THERE ARE ANY GLOBAL LOCKS--------------------------------------
	IF @EC = 0 
	BEGIN
		SELECT @S = (SELECT COUNT(*) CNT FROM CTRL.IMP_JOB WHERE GLOB_LOCK = 1);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END


	----------------INSERT JOB TO LOG------------------------------------------------------
	IF @EC = 0
		BEGIN
			IF @S <> 0
				BEGIN
					INSERT INTO 
						CTRL.IMP_JOB 
					VALUES
						(@NV,CURRENT_USER,APP_NAME(),'IMPORT_R_FMETH','NOT STARTED - JOB IN PROCESS',0,GETDATE(),GETDATE(),0);
					SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
					GOTO ERRH
				END
				BEGIN
					INSERT INTO 
						CTRL.IMP_JOB 
					VALUES
						(@NV,CURRENT_USER,APP_NAME(),'IMPORT_R_FMETH','PROCESSING',0,GETDATE(),NULL,1);
					SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
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
	BEGIN TRANSACTION METH;


/*--------------------------------------------------------------------------------------------------------------------------------------------
  __  __ ______ _______ _    _ _____  __  __ 
 |  \/  |  ____|__   __| |  | |  __ \|  \/  |
 | \  / | |__     | |  | |__| | |  | | \  / |
 | |\/| |  __|    | |  |  __  | |  | | |\/| |
 | |  | | |____   | |  | |  | | |__| | |  | |
 |_|  |_|______|  |_|  |_|  |_|_____/|_|  |_|
                                             
*/--------------------------------------------------------------------------------------------------------------------------------------------

	
	------------------------------BUILD OUT SELECT STATEMENT----------------------------------------------
	IF @EC = 0
	BEGIN	
		SELECT CMD INTO #SM FROM dbo.BUILD_DB2_SELECT('LGDAT','FUTHDM') OPTION (MAXRECURSION 1000);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	------------------------------BUILD OUT WHERE CLAUSE--------------------------------------------------
	IF @EC = 0
	BEGIN	
		SET @SQL = 
			(SELECT CMD FROM #SM)
			+' INNER JOIN LGDAT.FUTHH H ON ANPART = AQPART AND ANPLNT = AQPLNT WHERE ANDATE >= ''' 
			+ (SELECT CAST(MAX(ANDATE) AS VARCHAR(MAX)) FROM LGDAT.FUTHH) 
			+ '''';
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END;

	------------------------------CREATE METHDM COPY------------------------------------------------------
	IF @EC = 0
	BEGIN
		SELECT * INTO #XM FROM LGDAT.FUTHDM WHERE 0=1;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	------------------------------EXECUTE CONSTRUCTED SQL------------------------------------------------
	IF @EC = 0
	BEGIN
		INSERT INTO #XM EXECUTE(@SQL) AT CMS;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	------------------------------NEED TO DELETE ALL CHILDREN/SEQUENCES FOR INCOMMING PARENTS------------
	IF @EC = 0
	BEGIN
		DELETE 
			M 
		FROM 
			LGDAT.FUTHDM M
			INNER JOIN 
			(
				SELECT DISTINCT 
					AQPART, 
					AQPLNT 
				FROM 
					#XM
			) X ON 
				X.AQPART = M.AQPART AND 
				X.AQPLNT = M.AQPLNT;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	
	------------------------------BUILD OUT MERGE STATEMENT-----------------------------------------------
	IF @EC = 0
	BEGIN
		SELECT * INTO #MM FROM BUILD_MERGE_SMASH('LGDAT','FUTHDM','#XM') OPTION (MAXRECURSION 1000);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	------------------------------MOVE TO SCALAR VARIABLE-------------------------------------------------
	IF @EC = 0
	BEGIN
		SET @SQL = (SELECT CMD FROM #MM);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	
	------------------------------EXECUTE MERGE STATEMENT-------------------------------------------------
	IF @EC = 0
	BEGIN
		EXECUTE(@SQL);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	------------------------------DROP TEMP TABLES--------------------------------------------------------
	IF @EC = 0
	BEGIN
		DROP TABLE #XM;
		DROP TABLE #SM;
		DROP TABLE #MM;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	---------------Write to details log---------------------------------------------------
	IF @EC = 0 
	BEGIN
		PRINT 'FUTHDM PROCESSED CORRECTLY';
		INSERT INTO CTRL.IMP_DET VALUES (@NV, 'IMPORT_FUTHDM', @EC, @PR, GETDATE());
		SET @PR = GETDATE();
		PRINT cast(DATEDIFF(MS,@PR,GETDATE()) as varchar(max)) + ' ms';
	END
	ELSE 
	BEGIN
		PRINT 'FUTHDM PROCESSING ISSUE: ' + @EM
		ROLLBACK TRANSACTION METH;
		INSERT INTO CTRL.IMP_DET VALUES (@NV, 'IMPORT_FUTHDM', @EC, @PR, GETDATE());
		GOTO ERRH
	END

/*--------------------------------------------------------------------------------------------------------------------------------------------
  __  __ ______ _______ _    _ _____   ____  
 |  \/  |  ____|__   __| |  | |  __ \ / __ \ 
 | \  / | |__     | |  | |__| | |  | | |  | |
 | |\/| |  __|    | |  |  __  | |  | | |  | |
 | |  | | |____   | |  | |  | | |__| | |__| |
 |_|  |_|______|  |_|  |_|  |_|_____/ \____/ 
                                             
*/--------------------------------------------------------------------------------------------------------------------------------------------

	------------------------------BUILD OUT SELECT STATEMENT----------------------------------------------
	IF @EC = 0
	BEGIN	
		SELECT CMD INTO #SO FROM dbo.BUILD_DB2_SELECT('LGDAT','FUTHDO') OPTION (MAXRECURSION 1000);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	------------------------------BUILD OUT WHERE CLAUSE--------------------------------------------------
	IF @EC = 0
	BEGIN	
		SET @SQL = 
			(SELECT CMD FROM #SO)
			+' INNER JOIN LGDAT.FUTHH H ON ANPART = APPART AND ANPLNT = APPLNT WHERE ANDATE >= ''' 
			+ (SELECT CAST(MAX(ANDATE) AS VARCHAR(MAX)) FROM LGDAT.FUTHH) 
			+ '''';
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END;

	------------------------------CREATE METHDO COPY------------------------------------------------------
	IF @EC = 0
	BEGIN
		SELECT * INTO #XO FROM LGDAT.FUTHDO WHERE 0=1;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	------------------------------EXECUTE CONSTRUCTED SQL------------------------------------------------
	IF @EC = 0
	BEGIN
		INSERT INTO #XO EXECUTE(@SQL) AT CMS;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	------------------------------DELETE ALL EXISTING PART FROM INCOMMING---------------------------------
	IF @EC = 0
	BEGIN
		DELETE O
		FROM
			LGDAT.FUTHDO O
			INNER JOIN
			(
				SELECT DISTINCT 
					APPART, APPLNT
				FROM
					#XO
			) X ON
				X.APPART = O.APPART AND
				X.APPLNT = O.APPLNT;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	------------------------------BUILD OUT MERGE STATEMENT-----------------------------------------------
	IF @EC = 0
	BEGIN
		SELECT * INTO #MO FROM BUILD_MERGE_SMASH('LGDAT','FUTHDO','#XO') OPTION (MAXRECURSION 1000);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	------------------------------MOVE TO SCALAR VARIABLE-------------------------------------------------
	IF @EC = 0
	BEGIN
		SET @SQL = (SELECT CMD FROM #MO);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	
	------------------------------EXECUTE MERGE STATEMENT-------------------------------------------------
	IF @EC = 0
	BEGIN
		EXECUTE(@SQL);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	------------------------------DROP TEMP TABLES--------------------------------------------------------
	IF @EC = 0
	BEGIN
		DROP TABLE #XO;
		DROP TABLE #SO;
		DROP TABLE #MO;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	---------------Write to details log---------------------------------------------------
	IF @EC = 0 
	BEGIN
		PRINT 'FUTHDO PROCESSED CORRECTLY';
		INSERT INTO CTRL.IMP_DET VALUES (@NV, 'IMPORT_FUTHDO', @EC, @PR, GETDATE());
		SET @PR = GETDATE();
		PRINT cast(DATEDIFF(MS,@PR,GETDATE()) as varchar(max)) + ' ms';
	END
	ELSE 
	BEGIN
		PRINT 'FUTHDO PROCESSING ISSUE: ' + @EM
		ROLLBACK TRANSACTION METH;
		INSERT INTO CTRL.IMP_DET VALUES (@NV, 'IMPORT_FUTHDO', @EC, @PR, GETDATE());
		GOTO ERRH
	END

/*--------------------------------------------------------------------------------------------------------------------------------------------
  __  __ ______ _______ _    _ _____  _____  
 |  \/  |  ____|__   __| |  | |  __ \|  __ \ 
 | \  / | |__     | |  | |__| | |  | | |__) |
 | |\/| |  __|    | |  |  __  | |  | |  _  / 
 | |  | | |____   | |  | |  | | |__| | | \ \ 
 |_|  |_|______|  |_|  |_|  |_|_____/|_|  \_\
                                             
*/--------------------------------------------------------------------------------------------------------------------------------------------

	------------------------------BUILD OUT SELECT STATEMENT----------------------------------------------
	IF @EC = 0
	BEGIN	
		SELECT CMD INTO #SR FROM dbo.BUILD_DB2_SELECT('LGDAT','FUTHDR') OPTION (MAXRECURSION 1000);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	------------------------------BUILD OUT WHERE CLAUSE--------------------------------------------------
	IF @EC = 0
	BEGIN	
		SET @SQL = 
			(SELECT CMD FROM #SR)
			+' INNER JOIN LGDAT.FUTHH H ON ANPART = AOPART AND ANPLNT = AOPLNT WHERE ANDATE >= ''' 
			+ (SELECT CAST(MAX(ANDATE) AS VARCHAR(MAX)) FROM LGDAT.FUTHH) 
			+ '''';
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END;

	------------------------------CREATE METHDR COPY------------------------------------------------------
	IF @EC = 0
	BEGIN
		SELECT * INTO #XR FROM LGDAT.FUTHDR WHERE 0=1;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	------------------------------EXECUTE CONSTRUCTED SQL------------------------------------------------
	IF @EC = 0
	BEGIN
		INSERT INTO #XR EXECUTE(@SQL) AT CMS;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	------------------------------NEED TO DELETE ALL ROWS FOR INCOMMING PARTS-----------------------------
	IF @EC = 0
	BEGIN
		DELETE	
			R
		FROM
			LGDAT.FUTHDR R
			INNER JOIN
			(
				SELECT DISTINCT 
					AOPART, 
					AOPLNT 
				FROM 
					#XR
			) X ON
				X.AOPART = R.AOPART AND
				X.AOPLNT = R.AOPLNT;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
		

	------------------------------BUILD OUT MERGE STATEMENT-----------------------------------------------
	IF @EC = 0
	BEGIN
		SELECT * INTO #MR FROM BUILD_MERGE_SMASH('LGDAT','FUTHDR','#XR') OPTION (MAXRECURSION 1000);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	------------------------------MOVE TO SCALAR VARIABLE-------------------------------------------------
	IF @EC = 0
	BEGIN
		SET @SQL = (SELECT CMD FROM #MR);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	
	------------------------------EXECUTE MERGE STATEMENT-------------------------------------------------
	IF @EC = 0
	BEGIN
		EXECUTE(@SQL);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	------------------------------DROP TEMP TABLES--------------------------------------------------------
	IF @EC = 0
	BEGIN
		DROP TABLE #XR;
		DROP TABLE #SR;
		DROP TABLE #MR;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	---------------Write to details log---------------------------------------------------
	IF @EC = 0 
	BEGIN
		PRINT 'FUTHDR PROCESSED CORRECTLY';
		INSERT INTO CTRL.IMP_DET VALUES (@NV, 'IMPORT_FUTHDR', @EC, @PR, GETDATE());
		SET @PR = GETDATE();
		PRINT cast(DATEDIFF(MS,@PR,GETDATE()) as varchar(max)) + ' ms';
	END
	ELSE 
	BEGIN
		PRINT 'FUTHDR PROCESSING ISSUE: ' + @EM
		ROLLBACK TRANSACTION METH;
		INSERT INTO CTRL.IMP_DET VALUES (@NV, 'IMPORT_FUTHDR', @EC, @PR, GETDATE());
		GOTO ERRH
	END

/*--------------------------------------------------------------------------------------------------------------------------------------------
  __  __ ______ _______ _    _ _    _ 
 |  \/  |  ____|__   __| |  | | |  | |
 | \  / | |__     | |  | |__| | |__| |
 | |\/| |  __|    | |  |  __  |  __  |
 | |  | | |____   | |  | |  | | |  | |
 |_|  |_|______|  |_|  |_|  |_|_|  |_|
                                      
*/--------------------------------------------------------------------------------------------------------------------------------------------

	------------------------------BUILD OUT SELECT STATEMENT----------------------------------------------
	IF @EC = 0
	BEGIN	
		SELECT CMD INTO #SH FROM dbo.BUILD_DB2_SELECT('LGDAT','FUTHH') OPTION (MAXRECURSION 1000);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	------------------------------BUILD OUT WHERE CLAUSE--------------------------------------------------

	IF @EC = 0 
	BEGIN
		SET @SQL = 
			(SELECT CMD FROM #SH)
			+' WHERE ANDATE >= '''
			+(SELECT CAST(MAX(ANDATE) AS VARCHAR(MAX)) FROM LGDAT.FUTHH)
			+ '''';
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	------------------------------CREATE METHH COPY------------------------------------------------------
	IF @EC = 0
	BEGIN
		SELECT * INTO #XH FROM LGDAT.FUTHH WHERE 0=1;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	------------------------------EXECUTE CONSTRUCTED SQL------------------------------------------------
	IF @EC = 0
	BEGIN
		INSERT INTO #XH EXECUTE(@SQL) AT CMS;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	------------------------------BUILD OUT MERGE STATEMENT-----------------------------------------------
	IF @EC = 0
	BEGIN
		SELECT * INTO #MH FROM BUILD_MERGE_SMASH('LGDAT','FUTHH','#XH') OPTION (MAXRECURSION 1000);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	------------------------------MOVE TO SCALAR VARIABLE-------------------------------------------------
	IF @EC = 0
	BEGIN
		SET @SQL = (SELECT CMD FROM #MH);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	
	------------------------------EXECUTE MERGE STATEMENT-------------------------------------------------
	IF @EC = 0
	BEGIN
		EXECUTE(@SQL);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	------------------------------DROP TEMP TABLES--------------------------------------------------------
	IF @EC = 0
	BEGIN
		DROP TABLE #XH;
		DROP TABLE #SH;
		DROP TABLE #MH;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

		---------------Write to details log---------------------------------------------------
	IF @EC = 0 
	BEGIN
		PRINT 'FUTHH PROCESSED CORRECTLY';
		INSERT INTO CTRL.IMP_DET VALUES (@NV, 'IMPORT_FUTHH', @EC, @PR, GETDATE());
		SET @PR = GETDATE();
		PRINT cast(DATEDIFF(MS,@PR,GETDATE()) as varchar(max)) + ' ms';
	END
	ELSE 
	BEGIN
		PRINT 'FUTHH PROCESSING ISSUE: ' + @EM
		ROLLBACK TRANSACTION METH;
		INSERT INTO CTRL.IMP_DET VALUES (@NV, 'IMPORT_FUTHH', @EC, @PR, GETDATE());
		GOTO ERRH
	END

/*--------------------------------------------------------------------------------------------------------------------------------------------
  ______ _______ _____  _____ _______ __  __ 
 |  ____|__   __/ ____|/ ____|__   __|  \/  |
 | |__     | | | |    | (___    | |  | \  / |
 |  __|    | | | |     \___ \   | |  | |\/| |
 | |       | | | |____ ____) |  | |  | |  | |
 |_|       |_|  \_____|_____/   |_|  |_|  |_|
                                             
*/--------------------------------------------------------------------------------------------------------------------------------------------

	------------------------------BUILD OUT SELECT STATEMENT----------------------------------------------
	IF @EC = 0
	BEGIN	
		SELECT CMD INTO #SCM FROM dbo.BUILD_DB2_SELECT('LGDAT','FTCSTM') OPTION (MAXRECURSION 1000);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	------------------------------BUILD OUT WHERE CLAUSE--------------------------------------------------

	IF @EC = 0 
	BEGIN
		SET @SQL = 
			(SELECT CMD FROM #SCM)
			+' WHERE CNSDAT >= '''
			+(SELECT CAST(MAX(CNSDAT) AS VARCHAR(MAX)) FROM LGDAT.FTCSTM)
			+ '''';
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	------------------------------CREATE METHH COPY------------------------------------------------------
	IF @EC = 0
	BEGIN
		SELECT * INTO #XCM FROM LGDAT.FTCSTM WHERE 0=1;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	------------------------------EXECUTE CONSTRUCTED SQL------------------------------------------------
	IF @EC = 0
	BEGIN
		INSERT INTO #XCM EXECUTE(@SQL) AT CMS;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	------------------------------BUILD OUT MERGE STATEMENT-----------------------------------------------
	IF @EC = 0
	BEGIN
		SELECT * INTO #MCM FROM BUILD_MERGE_SMASH('LGDAT','FTCSTM','#XCM') OPTION (MAXRECURSION 1000);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	------------------------------MOVE TO SCALAR VARIABLE-------------------------------------------------
	IF @EC = 0
	BEGIN
		SET @SQL = (SELECT CMD FROM #MCM);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	
	------------------------------EXECUTE MERGE STATEMENT-------------------------------------------------
	IF @EC = 0
	BEGIN
		EXECUTE(@SQL);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	------------------------------DROP TEMP TABLES--------------------------------------------------------
	IF @EC = 0
	BEGIN
		DROP TABLE #XCM;
		DROP TABLE #SCM;
		DROP TABLE #MCM;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

		---------------Write to details log---------------------------------------------------
	IF @EC = 0 
	BEGIN
		PRINT 'FTCSTM PROCESSED CORRECTLY';
		INSERT INTO CTRL.IMP_DET VALUES (@NV, 'IMPORT_FTCSTM', @EC, @PR, GETDATE());
		SET @PR = GETDATE();
		PRINT cast(DATEDIFF(MS,@PR,GETDATE()) as varchar(max)) + ' ms';
	END
	ELSE 
	BEGIN
		PRINT 'FTCSTM PROCESSING ISSUE: ' + @EM
		ROLLBACK TRANSACTION METH;
		INSERT INTO CTRL.IMP_DET VALUES (@NV, 'IMPORT_FTCSTM', @EC, @PR, GETDATE());
		GOTO ERRH
	END

/*--------------------------------------------------------------------------------------------------------------------------------------------
  ______ _______ _____  _____ _______ _____  
 |  ____|__   __/ ____|/ ____|__   __|  __ \ 
 | |__     | | | |    | (___    | |  | |__) |
 |  __|    | | | |     \___ \   | |  |  ___/ 
 | |       | | | |____ ____) |  | |  | |     
 |_|       |_|  \_____|_____/   |_|  |_|     
                                             
*/--------------------------------------------------------------------------------------------------------------------------------------------

	------------------------------BUILD OUT SELECT STATEMENT----------------------------------------------
	IF @EC = 0
	BEGIN	
		SELECT CMD INTO #SCP FROM dbo.BUILD_DB2_SELECT('LGDAT','FTCSTP') OPTION (MAXRECURSION 1000);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	------------------------------BUILD OUT WHERE CLAUSE--------------------------------------------------

	IF @EC = 0 
	BEGIN
		SET @SQL = 
			(SELECT CMD FROM #SCP)
			+' WHERE COSDAT >= '''
			+(SELECT CAST(MAX(COSDAT) AS VARCHAR(MAX)) FROM LGDAT.FTCSTP)
			+ '''';
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	------------------------------CREATE METHH COPY------------------------------------------------------
	IF @EC = 0
	BEGIN
		SELECT * INTO #XCP FROM LGDAT.FTCSTP WHERE 0=1;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	------------------------------EXECUTE CONSTRUCTED SQL------------------------------------------------
	IF @EC = 0
	BEGIN
		INSERT INTO #XCP EXECUTE(@SQL) AT CMS;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	------------------------------BUILD OUT MERGE STATEMENT-----------------------------------------------
	IF @EC = 0
	BEGIN
		SELECT * INTO #MCP FROM BUILD_MERGE_SMASH('LGDAT','FTCSTP','#XCP') OPTION (MAXRECURSION 1000);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	------------------------------MOVE TO SCALAR VARIABLE-------------------------------------------------
	IF @EC = 0
	BEGIN
		SET @SQL = (SELECT CMD FROM #MCP);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	
	------------------------------EXECUTE MERGE STATEMENT-------------------------------------------------
	IF @EC = 0
	BEGIN
		EXECUTE(@SQL);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	------------------------------DROP TEMP TABLES--------------------------------------------------------
	IF @EC = 0
	BEGIN
		DROP TABLE #XCP;
		DROP TABLE #SCP;
		DROP TABLE #MCP;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

		---------------Write to details log---------------------------------------------------
	IF @EC = 0 
	BEGIN
		PRINT 'FTCSTP PROCESSED CORRECTLY';
		INSERT INTO CTRL.IMP_DET VALUES (@NV, 'IMPORT_FTCSTP', @EC, @PR, GETDATE());
		SET @PR = GETDATE();
		PRINT cast(DATEDIFF(MS,@PR,GETDATE()) as varchar(max)) + ' ms';
	END
	ELSE 
	BEGIN
		PRINT 'FTCSTP PROCESSING ISSUE: ' + @EM
		ROLLBACK TRANSACTION METH;
		INSERT INTO CTRL.IMP_DET VALUES (@NV, 'IMPORT_FTCSTP', @EC, @PR, GETDATE());
		GOTO ERRH
	END

/*--------------------------------------------------------------------------------------------------------------------------------------------
  ______ _______ _____  _____ _______ _____  
 |  ____|__   __/ ____|/ ____|__   __|  __ \ 
 | |__     | | | |    | (___    | |  | |__) |
 |  __|    | | | |     \___ \   | |  |  _  / 
 | |       | | | |____ ____) |  | |  | | \ \ 
 |_|       |_|  \_____|_____/   |_|  |_|  \_\
                                             
*/--------------------------------------------------------------------------------------------------------------------------------------------

	------------------------------BUILD OUT SELECT STATEMENT----------------------------------------------
	IF @EC = 0
	BEGIN	
		SELECT CMD INTO #SCR FROM dbo.BUILD_DB2_SELECT('LGDAT','FTCSTR') OPTION (MAXRECURSION 1000);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	------------------------------BUILD OUT WHERE CLAUSE--------------------------------------------------

	IF @EC = 0 
	BEGIN
		SET @SQL = 
			(SELECT CMD FROM #SCR)
			+' WHERE Y3SDAT >= '''
			+(SELECT CAST(MAX(Y3SDAT) AS VARCHAR(MAX)) FROM LGDAT.FTCSTR)
			+ '''';
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	------------------------------CREATE METHH COPY------------------------------------------------------
	IF @EC = 0
	BEGIN
		SELECT * INTO #XCR FROM LGDAT.FTCSTR WHERE 0=1;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	------------------------------EXECUTE CONSTRUCTED SQL------------------------------------------------
	IF @EC = 0
	BEGIN
		INSERT INTO #XCR EXECUTE(@SQL) AT CMS;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	------------------------------BUILD OUT MERGE STATEMENT-----------------------------------------------
	IF @EC = 0
	BEGIN
		SELECT * INTO #MCR FROM BUILD_MERGE_SMASH('LGDAT','FTCSTR','#XCR') OPTION (MAXRECURSION 1000);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	------------------------------MOVE TO SCALAR VARIABLE-------------------------------------------------
	IF @EC = 0
	BEGIN
		SET @SQL = (SELECT CMD FROM #MCR);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	
	------------------------------EXECUTE MERGE STATEMENT-------------------------------------------------
	IF @EC = 0
	BEGIN
		EXECUTE(@SQL);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	------------------------------DROP TEMP TABLES--------------------------------------------------------
	IF @EC = 0
	BEGIN
		DROP TABLE #XCR;
		DROP TABLE #SCR;
		DROP TABLE #MCR;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

		---------------Write to details log---------------------------------------------------
	IF @EC = 0 
	BEGIN
		PRINT 'FTCSTR PROCESSED CORRECTLY';
		INSERT INTO CTRL.IMP_DET VALUES (@NV, 'IMPORT_FTCSTR', @EC, @PR, GETDATE());
		SET @PR = GETDATE();
		PRINT cast(DATEDIFF(MS,@PR,GETDATE()) as varchar(max)) + ' ms';
	END
	ELSE 
	BEGIN
		PRINT 'FTCSTR PROCESSING ISSUE: ' + @EM
		ROLLBACK TRANSACTION METH;
		INSERT INTO CTRL.IMP_DET VALUES (@NV, 'IMPORT_FTCSTR', @EC, @PR, GETDATE());
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
		COMMIT TRANSACTION METH;

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

END;