USE [FAnalysis]
GO
/****** Object:  StoredProcedure [LGDAT].[IMPORT_R_ACCT]    Script Date: 4/25/2017 9:55:24 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROC [LGDAT].[IMPORT_R_ACCT] AS
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
						(@NV,CURRENT_USER,APP_NAME(),'IMPORT_R_ACCT','NOT STARTED - JOB IN PROCESS',0,GETDATE(),GETDATE(),0);
					SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
					GOTO ERRH
				END
				BEGIN
					INSERT INTO 
						CTRL.IMP_JOB 
					VALUES
						(@NV,CURRENT_USER,APP_NAME(),'IMPORT_R_ACCT','PROCESSING',0,GETDATE(),NULL,1);
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
	BEGIN TRANSACTION ACCT;

/*--------------------------------------------------------------------------------------------------------------------------------------------
   _____ _      __  __ _______ 
  / ____| |    |  \/  |__   __|
 | |  __| |    | \  / |  | |   
 | | |_ | |    | |\/| |  | |   
 | |__| | |____| |  | |  | |   
  \_____|______|_|  |_|  |_|   
                               
*/--------------------------------------------------------------------------------------------------------------------------------------------

	------------------------------BUILD OUT SELECT STATEMENT----------------------------------------------
	IF @EC = 0
	BEGIN	
		SELECT CMD INTO #SB FROM dbo.BUILD_DB2_SELECT('LGDAT','GLMT') OPTION (MAXRECURSION 1000);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	
	------------------------------GET EXTERNAL WHERE CLAUSE-----------------------------------------------
	IF @EC = 0
	BEGIN
		EXEC @EC =  R.LAST_GTRAN @AGG OUTPUT;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	------------------------------BUILD OUT FULL SQL------------------------------------------------------
	IF @EC = 0
	BEGIN
		SET @SQL = 
			(SELECT CMD FROM #SB)
			+' B INNER JOIN (SELECT DISTINCT CAST(SUBSTR(DKACC#,1,2) AS DEC(2,0)) COMP, CAST(SUBSTR(DKACC#,3,4) AS DEC(4,0)) GL#1, CAST(SUBSTR(DKACC#,7,6) AS DEC(6,0)) GL#2, DKFSYR||DKFSYY CCYY FROM LGDAT.GTRAN WHERE ' +
			+ @AGG
			+ ') X ON X.COMP = B.AJ4COMP AND X.GL#1 = AJ4GL#1 AND X.GL#2 = AJ4GL#2 AND X.CCYY = AJ4CCYY';
		SELECT @SQL;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	
	------------------------------CREATE GLMT COPY------------------------------------------------------
	IF @EC = 0
	BEGIN
		SELECT * INTO #XB FROM LGDAT.GLMT WHERE 0=1;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	------------------------------EXECUTE CONSTRUCTED SQL------------------------------------------------
	IF @EC = 0
	BEGIN
		INSERT INTO #XB EXECUTE(@SQL) AT CMS;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	------------------------------BUILD OUT MERGE STATEMENT-----------------------------------------------
	IF @EC = 0
	BEGIN
		SELECT * INTO #MB FROM BUILD_MERGE_SMASH('LGDAT','GLMT','#XB') OPTION (MAXRECURSION 1000);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	------------------------------MOVE TO SCALAR VARIABLE-------------------------------------------------
	IF @EC = 0
	BEGIN
		SET @SQL = (SELECT CMD FROM #MB);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	
	------------------------------EXECUTE MERGE STATEMENT-------------------------------------------------
	IF @EC = 0
	BEGIN
		EXECUTE(@SQL);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	------------------------------CREATE COPY OF R.GLMT---------------------------------------------------
	IF @EC = 0
	BEGIN
		SELECT * INTO #G FROM R.GLMT WHERE 0=1;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	------------------------------UNPIVOT ADDED RECORDS IN #X---------------------------------------------
	IF @EC = 0
	BEGIN
		INSERT INTO #G
		SELECT * FROM
		(
		SELECT FORMAT(AJ4COMP,'00') + FORMAT(AJ4GL#1,'0000') + FORMAT(AJ4GL#2,'000000') ACCT, SUBSTRING(FORMAT(AJ4CCYY,'0000'),3,2)+'01' PERD,  AJ4OB01, AJ4TT01, AJ4CB01, AJ4FR01 FROM  #XB UNION ALL
		SELECT FORMAT(AJ4COMP,'00') + FORMAT(AJ4GL#1,'0000') + FORMAT(AJ4GL#2,'000000') ACCT, SUBSTRING(FORMAT(AJ4CCYY,'0000'),3,2)+'02' PERD,  AJ4OB02, AJ4TT02, AJ4CB02, AJ4FR02 FROM  #XB UNION ALL
		SELECT FORMAT(AJ4COMP,'00') + FORMAT(AJ4GL#1,'0000') + FORMAT(AJ4GL#2,'000000') ACCT, SUBSTRING(FORMAT(AJ4CCYY,'0000'),3,2)+'03' PERD,  AJ4OB03, AJ4TT03, AJ4CB03, AJ4FR03 FROM  #XB UNION ALL
		SELECT FORMAT(AJ4COMP,'00') + FORMAT(AJ4GL#1,'0000') + FORMAT(AJ4GL#2,'000000') ACCT, SUBSTRING(FORMAT(AJ4CCYY,'0000'),3,2)+'04' PERD,  AJ4OB04, AJ4TT04, AJ4CB04, AJ4FR04 FROM  #XB UNION ALL
		SELECT FORMAT(AJ4COMP,'00') + FORMAT(AJ4GL#1,'0000') + FORMAT(AJ4GL#2,'000000') ACCT, SUBSTRING(FORMAT(AJ4CCYY,'0000'),3,2)+'05' PERD,  AJ4OB05, AJ4TT05, AJ4CB05, AJ4FR05 FROM  #XB UNION ALL
		SELECT FORMAT(AJ4COMP,'00') + FORMAT(AJ4GL#1,'0000') + FORMAT(AJ4GL#2,'000000') ACCT, SUBSTRING(FORMAT(AJ4CCYY,'0000'),3,2)+'06' PERD,  AJ4OB06, AJ4TT06, AJ4CB06, AJ4FR06 FROM  #XB UNION ALL
		SELECT FORMAT(AJ4COMP,'00') + FORMAT(AJ4GL#1,'0000') + FORMAT(AJ4GL#2,'000000') ACCT, SUBSTRING(FORMAT(AJ4CCYY,'0000'),3,2)+'07' PERD,  AJ4OB07, AJ4TT07, AJ4CB07, AJ4FR07 FROM  #XB UNION ALL
		SELECT FORMAT(AJ4COMP,'00') + FORMAT(AJ4GL#1,'0000') + FORMAT(AJ4GL#2,'000000') ACCT, SUBSTRING(FORMAT(AJ4CCYY,'0000'),3,2)+'08' PERD,  AJ4OB08, AJ4TT08, AJ4CB08, AJ4FR08 FROM  #XB UNION ALL
		SELECT FORMAT(AJ4COMP,'00') + FORMAT(AJ4GL#1,'0000') + FORMAT(AJ4GL#2,'000000') ACCT, SUBSTRING(FORMAT(AJ4CCYY,'0000'),3,2)+'09' PERD,  AJ4OB09, AJ4TT09, AJ4CB09, AJ4FR09 FROM  #XB UNION ALL
		SELECT FORMAT(AJ4COMP,'00') + FORMAT(AJ4GL#1,'0000') + FORMAT(AJ4GL#2,'000000') ACCT, SUBSTRING(FORMAT(AJ4CCYY,'0000'),3,2)+'10' PERD,  AJ4OB10, AJ4TT10, AJ4CB10, AJ4FR0A FROM  #XB UNION ALL
		SELECT FORMAT(AJ4COMP,'00') + FORMAT(AJ4GL#1,'0000') + FORMAT(AJ4GL#2,'000000') ACCT, SUBSTRING(FORMAT(AJ4CCYY,'0000'),3,2)+'11' PERD,  AJ4OB11, AJ4TT11, AJ4CB11, AJ4FR0B FROM  #XB UNION ALL
		SELECT FORMAT(AJ4COMP,'00') + FORMAT(AJ4GL#1,'0000') + FORMAT(AJ4GL#2,'000000') ACCT, SUBSTRING(FORMAT(AJ4CCYY,'0000'),3,2)+'12' PERD,  AJ4OB12, AJ4TT12, AJ4CB12, AJ4FR0C FROM  #XB UNION ALL
		SELECT FORMAT(AJ4COMP,'00') + FORMAT(AJ4GL#1,'0000') + FORMAT(AJ4GL#2,'000000') ACCT, SUBSTRING(FORMAT(AJ4CCYY,'0000'),3,2)+'13' PERD,  AJ4OB13, AJ4TT13, AJ4CB13, AJ4FR0D FROM  #XB UNION ALL
		SELECT FORMAT(AJ4COMP,'00') + FORMAT(AJ4GL#1,'0000') + FORMAT(AJ4GL#2,'000000') ACCT, SUBSTRING(FORMAT(AJ4CCYY,'0000'),3,2)+'14' PERD,  AJ4OB14, AJ4TT14, AJ4CB14, AJ4FR0E FROM  #XB UNION ALL
		SELECT FORMAT(AJ4COMP,'00') + FORMAT(AJ4GL#1,'0000') + FORMAT(AJ4GL#2,'000000') ACCT, SUBSTRING(FORMAT(AJ4CCYY,'0000'),3,2)+'15' PERD,  AJ4OB15, AJ4TT15, AJ4CB15, AJ4FR0F FROM  #XB
		) AS UNPVT;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	------------------------------BUILD MERGE FOR R.GLMT--------------------------------------------------
	IF @EC = 0
	BEGIN
		SET @SQL = (SELECT CMD FROM dbo.BUILD_MERGE_SMASH('R','GLMT','#G'));
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
		DROP TABLE #XB;
		DROP TABLE #SB;
		DROP TABLE #MB;
		DROP TABLE #G;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	---------------Write to details log---------------------------------------------------
	IF @EC = 0 
	BEGIN
		PRINT 'GLMT PROCESSED CORRECTLY';
		INSERT INTO CTRL.IMP_DET VALUES (@NV, 'IMPORT_GLMT', @EC, @PR, GETDATE());
		SET @PR = GETDATE();
		PRINT cast(DATEDIFF(MS,@PR,GETDATE()) as varchar(max)) + ' ms';
	END
	ELSE 
	BEGIN
		PRINT 'GLMT PROCESSING ISSUE: ' + @EM
		ROLLBACK TRANSACTION ACCT;
		INSERT INTO CTRL.IMP_DET VALUES (@NV, 'IMPORT_GLMT', @EC, @PR, GETDATE());
		GOTO ERRH
	END

/*--------------------------------------------------------------------------------------------------------------------------------------------
   _____ _______ _____            _   _ 
  / ____|__   __|  __ \     /\   | \ | |
 | |  __   | |  | |__) |   /  \  |  \| |
 | | |_ |  | |  |  _  /   / /\ \ | . ` |
 | |__| |  | |  | | \ \  / ____ \| |\  |
  \_____|  |_|  |_|  \_\/_/    \_\_| \_|
                                        
*/--------------------------------------------------------------------------------------------------------------------------------------------

	------------------------------BUILD OUT SELECT STATEMENT----------------------------------------------
	IF @EC = 0
	BEGIN	
		SELECT CMD INTO #ST FROM dbo.BUILD_DB2_SELECT('LGDAT','GTRAN') OPTION (MAXRECURSION 1000);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	
	------------------------------GET EXTERNAL WHERE CLAUSE-----------------------------------------------
	IF @EC = 0
	BEGIN
		EXEC @EC =  R.LAST_GTRAN_RCID @AGG OUTPUT;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	------------------------------BUILD OUT FULL SQL------------------------------------------------------
	IF @EC = 0
	BEGIN
		SET @SQL = 
			(SELECT CMD FROM #ST)
			+' WHERE ' +
			+ @AGG;
		SELECT @SQL;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	
	------------------------------CREATE GLMT COPY------------------------------------------------------
	IF @EC = 0
	BEGIN
		SELECT * INTO #XT FROM LGDAT.GTRAN WHERE 0=1;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	------------------------------EXECUTE CONSTRUCTED SQL------------------------------------------------
	IF @EC = 0
	BEGIN
		INSERT INTO #XT EXECUTE(@SQL) AT CMS;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	------------------------------BUILD OUT MERGE STATEMENT-----------------------------------------------
	IF @EC = 0
	BEGIN
		SELECT * INTO #MT FROM BUILD_MERGE_SMASH('LGDAT','GTRAN','#XT') OPTION (MAXRECURSION 1000);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	------------------------------MOVE TO SCALAR VARIABLE-------------------------------------------------
	IF @EC = 0
	BEGIN
		SET @SQL = (SELECT CMD FROM #MT);
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
		DROP TABLE #XT;
		DROP TABLE #ST;
		DROP TABLE #MT;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	---------------Write to details log---------------------------------------------------
	IF @EC = 0 
	BEGIN
		PRINT 'GTRAN PROCESSED CORRECTLY';
		INSERT INTO CTRL.IMP_DET VALUES (@NV, 'IMPORT_GTRAN', @EC, @PR, GETDATE());
		SET @PR = GETDATE();
		PRINT cast(DATEDIFF(MS,@PR,GETDATE()) as varchar(max)) + ' ms';
	END
	ELSE 
	BEGIN
		PRINT 'GTRAN PROCESSING ISSUE: ' + @EM
		ROLLBACK TRANSACTION ACCT;
		INSERT INTO CTRL.IMP_DET VALUES (@NV, 'IMPORT_GTRAN', @EC, @PR, GETDATE());
		GOTO ERRH
	END

/*--------------------------------------------------------------------------------------------------------------------------------------------
   _____ _____  ______ _______ 
  / ____|  __ \|  ____|__   __|
 | |    | |__) | |__     | |   
 | |    |  _  /|  __|    | |   
 | |____| | \ \| |____   | |   
  \_____|_|  \_\______|  |_|   
                               
*/--------------------------------------------------------------------------------------------------------------------------------------------

	IF @EC = 0
	BEGIN	
		SELECT CMD INTO #SX FROM dbo.BUILD_DB2_SELECT('LGDAT','CRET') OPTION (MAXRECURSION 1000);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	

	IF @EC = 0
	BEGIN
		SET @SQL = 
			(SELECT CMD FROM #SX) + 
			+ ' WHERE MAX(B86CDAT,B86UDAT) >= '''
			+ (SELECT CAST(dbo.GREATEST_DATE(MAX(B86CDAT), MAX(B86UDAT)) AS VARCHAR(MAX)) FROM LGDAT.CRET)
			+ '''';
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	

	IF @EC = 0
	BEGIN
		SELECT * INTO #XX FROM LGDAT.CRET WHERE 0=1;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	

	IF @EC = 0
	BEGIN
		INSERT INTO #XX EXECUTE(@SQL) AT CMS;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	

	IF @EC = 0
	BEGIN
		SELECT * INTO #MX FROM BUILD_MERGE_SMASH('LGDAT','CRET','#XX') OPTION (MAXRECURSION 1000);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	
	IF @EC = 0
	BEGIN
		SET @SQL = (SELECT CMD FROM #MX);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	

	IF @EC = 0
	BEGIN
		EXECUTE(@SQL);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	

	IF @EC = 0
	BEGIN
		DROP TABLE #XX;
		DROP TABLE #MX;
		DROP TABLE #SX;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	
	---------------Write to details log---------------------------------------------------
	IF @EC = 0 
	BEGIN
		PRINT 'CRET PROCESSED CORRECTLY';
		INSERT INTO CTRL.IMP_DET VALUES (@NV, 'IMPORT_CRET', @EC, @PR, GETDATE());
		SET @PR = GETDATE();
		PRINT cast(DATEDIFF(MS,@PR,GETDATE()) as varchar(max)) + ' ms';
	END
	ELSE 
	BEGIN
		PRINT 'CRET PROCESSING ISSUE: ' + @EM
		ROLLBACK TRANSACTION ACCT;
		INSERT INTO CTRL.IMP_DET VALUES (@NV, 'IMPORT_CRET', @EC, @PR, GETDATE());
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
		COMMIT TRANSACTION ACCT;

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



