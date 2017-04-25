
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
						(@NV,CURRENT_USER,APP_NAME(),'IMPORT_R_AR','NOT STARTED - JOB IN PROCESS',0,GETDATE(),GETDATE(),0);
					SET @EC = @@ERROR;
					GOTO ERRH
				END
				BEGIN
					INSERT INTO 
						CTRL.IMP_JOB 
					VALUES
						(@NV,CURRENT_USER,APP_NAME(),'IMPORT_R_AR','PROCESSING',0,GETDATE(),NULL,1);
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
	BEGIN TRANSACTION AR;

/*-------------------------------------------------------------------------------------------------------------------------------------------------------------------
           _____   ____  _    _ _______ 
     /\   |  __ \ / __ \| |  | |__   __|
    /  \  | |__) | |  | | |__| |  | |   
   / /\ \ |  _  /| |  | |  __  |  | |   
  / ____ \| | \ \| |__| | |  | |  | |   
 /_/    \_\_|  \_\\____/|_|  |_|  |_|   
                                        
*/-------------------------------------------------------------------------------------------------------------------------------------------------------------------
	
	------------------------build select-----------------------------------------------
	IF @EC = 0
	BEGIN	
		SELECT CMD INTO #SHT FROM dbo.BUILD_DB2_SELECT('LGDAT','AROHT') OPTION (MAXRECURSION 1000);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	
	------------------------build where clause-----------------------------------------
	IF @EC = 0
	BEGIN
		SET @SQL = 
			(SELECT CMD FROM #SHT) + 
			+' WHERE ASTDAT >= ''' 
			+ (SELECT CAST(MAX(ASTDAT) AS VARCHAR(MAX)) FROM LGDAT.AROHT)
			+ ''' OR ASPDAT >= '''
			+ (SELECT CAST(MAX(ASPDAT) AS VARCHAR(MAX)) FROM LGDAT.AROHT)
			+ '''';
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	
	------------------------build copy of table----------------------------------------
	IF @EC = 0
	BEGIN
		SELECT * INTO #XHT FROM LGDAT.AROHT WHERE 0=1;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	------------------------run sql to copy table--------------------------------------
	IF @EC = 0
	BEGIN
		INSERT INTO #XHT EXECUTE(@SQL) AT CMS;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	------------------------build merge statement--------------------------------------
	IF @EC = 0
	BEGIN
		SELECT * INTO #MHT FROM BUILD_MERGE_SMASH('LGDAT','AROHT','#XHT') OPTION (MAXRECURSION 1000);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	------------------------convert merge to scalar -----------------------------------
	IF @EC = 0
	BEGIN
		SET @SQL = (SELECT CMD FROM #MHT);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	
	------------------------execute merge----------------------------------------------
	IF @EC = 0
	BEGIN
		EXECUTE(@SQL);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	------------------------drop temp tables-------------------------------------------
	IF @EC = 0
	BEGIN
		DROP TABLE #XHT;
		DROP TABLE #SHT;
		DROP TABLE #MHT;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END


	---------------Write to details log---------------------------------------------------
	IF @EC = 0 
	BEGIN
		PRINT 'AROHT PROCESSED CORRECTLY';
		INSERT INTO CTRL.IMP_DET VALUES (@NV, 'IMPORT_AROHT', @EC, @PR, GETDATE());
		SET @PR = GETDATE();
		PRINT cast(DATEDIFF(MS,@PR,GETDATE()) as varchar(max)) + ' ms';
	END
	ELSE 
	BEGIN
		PRINT 'AROHT PROCESSING ISSUE: ' + @EM
		ROLLBACK TRANSACTION AR;
		INSERT INTO CTRL.IMP_DET VALUES (@NV, 'IMPORT_AROHT', @EC, @PR, GETDATE());
		GOTO ERRH
	END

/*-------------------------------------------------------------------------------------------------------------------------------------------------
           _____   ____  _____  
     /\   |  __ \ / __ \|  __ \ 
    /  \  | |__) | |  | | |__) |
   / /\ \ |  _  /| |  | |  ___/ 
  / ____ \| | \ \| |__| | |     
 /_/    \_\_|  \_\\____/|_|     
                                
*/-------------------------------------------------------------------------------------------------------------------------------------------------

	------------------------create select----------------------------------------------
	IF @EC = 0
	BEGIN	
		SELECT CMD INTO #SO FROM dbo.BUILD_DB2_SELECT('LGDAT','AROP') OPTION (MAXRECURSION 1000);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	
	------------------------build where clause-----------------------------------------
	IF @EC = 0
	BEGIN
		SET @SQL = 
			(SELECT CMD FROM #SO) + 
			+' WHERE ASTDAT >= ''' 
			+ (SELECT CAST(MAX(ASTDAT) AS VARCHAR(MAX)) FROM LGDAT.AROP)
			+ ''' OR ASPDAT >= '''
			+ (SELECT CAST(MAX(ASPDAT) AS VARCHAR(MAX)) FROM LGDAT.AROP)
			+ '''';
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	
	------------------------build copy of target table---------------------------------
	IF @EC = 0
	BEGIN
		SELECT * INTO #XO FROM LGDAT.AROP WHERE 0=1;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	------------------------execute sql into copy--------------------------------------
	IF @EC = 0
	BEGIN
		INSERT INTO #XO EXECUTE(@SQL) AT CMS;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	------------------------build merge statement--------------------------------------
	IF @EC = 0
	BEGIN
		SELECT * INTO #MO FROM BUILD_MERGE_SMASH('LGDAT','AROP','#XO') OPTION (MAXRECURSION 1000);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	------------------------convert move merge to scalar variable----------------------
	IF @EC = 0
	BEGIN
		SET @SQL = (SELECT CMD FROM #MO);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	
	------------------------execute merge----------------------------------------------
	IF @EC = 0
	BEGIN
		EXECUTE(@SQL);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	------------------------drop temp tables-------------------------------------------
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
		PRINT 'AROP PROCESSED CORRECTLY';
		INSERT INTO CTRL.IMP_DET VALUES (@NV, 'IMPORT_AROP', @EC, @PR, GETDATE());
		SET @PR = GETDATE();
		PRINT cast(DATEDIFF(MS,@PR,GETDATE()) as varchar(max)) + ' ms';
	END
	ELSE 
	BEGIN
		PRINT 'AROP PROCESSING ISSUE: ' + @EM
		ROLLBACK TRANSACTION AR;
		INSERT INTO CTRL.IMP_DET VALUES (@NV, 'IMPORT_AROP', @EC, @PR, GETDATE());
		GOTO ERRH
	END

/*-------------------------------------------------------------------------------------------------------------------------------------------------
           _____ _______ _____  _   _ 
     /\   |  __ \__   __|  __ \| \ | |
    /  \  | |__) | | |  | |__) |  \| |
   / /\ \ |  _  /  | |  |  _  /| . ` |
  / ____ \| | \ \  | |  | | \ \| |\  |
 /_/    \_\_|  \_\ |_|  |_|  \_\_| \_|
                                      
*/-------------------------------------------------------------------------------------------------------------------------------------------------

	------------------------build select-----------------------------------------------
	IF @EC = 0
	BEGIN	
		SELECT CMD INTO #ST FROM dbo.BUILD_DB2_SELECT('LGDAT','ARTRN') OPTION (MAXRECURSION 1000);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	
	------------------------build where cluase-----------------------------------------
	IF @EC = 0
	BEGIN
		SET @SQL = 
			(SELECT CMD FROM #ST) + 
			+' WHERE LOTDAT >= ''' 
			+ (SELECT CAST(MAX(LOTDAT) AS VARCHAR(MAX)) FROM LGDAT.ARTRN)
			+ '''';
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	
	------------------------create copy of target table--------------------------------
	IF @EC = 0
	BEGIN
		SELECT * INTO #XT FROM LGDAT.ARTRN WHERE 0=1;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	------------------------execute sql into table copy--------------------------------
	IF @EC = 0
	BEGIN
		INSERT INTO #XT EXECUTE(@SQL) AT CMS;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	---------------------ARTRN HAS NON-UNIQUE ROWS, WILL DELETE TDAT RANGE AND INSERT----------------
	IF @EC = 0
	BEGIN
		DELETE 
			A 
		FROM 
			LGDAT.ARTRN A
			INNER JOIN 
				(
						SELECT DISTINCT 
							LOCOMP, 
							LOINV#, 
							LOTDAT, 
							LOTTYP 
						FROM 
							#XT
				) X ON
					X.LOCOMP = A.LOCOMP AND
					X.LOINV# = A.LOINV# AND
					X.LOTDAT = A.LOTDAT AND
					X.LOTTYP = A.LOTTYP;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	------------------------insert all rows--------------------------------------------
	IF @EC = 0
	BEGIN
		INSERT INTO LGDAT.ARTRN SELECT * FROM #XT
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	------------------------drop temp tables-------------------------------------------
	IF @EC = 0
	BEGIN
		DROP TABLE #XT;
		DROP TABLE #ST;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	---------------Write to details log---------------------------------------------------
	IF @EC = 0 
	BEGIN
		PRINT 'ARTRN PROCESSED CORRECTLY';
		INSERT INTO CTRL.IMP_DET VALUES (@NV, 'IMPORT_ARTRN', @EC, @PR, GETDATE());
		SET @PR = GETDATE();
		PRINT cast(DATEDIFF(MS,@PR,GETDATE()) as varchar(max)) + ' ms';
	END
	ELSE 
	BEGIN
		PRINT 'ARTRN PROCESSING ISSUE: ' + @EM
		ROLLBACK TRANSACTION AR;
		INSERT INTO CTRL.IMP_DET VALUES (@NV, 'IMPORT_ARTRN', @EC, @PR, GETDATE());
		GOTO ERRH
	END

/*-------------------------------------------------------------------------------------------------------------------------------------------------
   _____ _    _  _____ _______ 
  / ____| |  | |/ ____|__   __|
 | |    | |  | | (___    | |   
 | |    | |  | |\___ \   | |   
 | |____| |__| |____) |  | |   
  \_____|\____/|_____/   |_|   
                               
*/-------------------------------------------------------------------------------------------------------------------------------------------------
	
	------------------------build select-----------------------------------------------
	IF @EC = 0
	BEGIN	
		SELECT CMD INTO #SC FROM dbo.BUILD_DB2_SELECT('LGDAT','CUST') OPTION (MAXRECURSION 1000);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	
	------------------------build where clause-----------------------------------------
	IF @EC = 0
	BEGIN
		SET @SQL = 
			(SELECT CMD FROM #SC) + 
			+ ' WHERE MAX(BVCDAT, BVMDAT, BVLDAT, BVPDAT) >= '''
			+ (SELECT CAST(dbo.GREATEST_DATE(dbo.GREATEST_DATE(dbo.GREATEST_DATE(MAX(BVCDAT), MAX(BVMDAT)), MAX(BVPDAT)), MAX(BVLDAT)) AS VARCHAR(MAX)) FROM LGDAT.CUST)
			+ '''';
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	
	------------------------create copy of target table---------------------------------
	IF @EC = 0
	BEGIN
		SELECT * INTO #XC FROM LGDAT.CUST WHERE 0=1;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	
	------------------------execute select into copy------------------------------------
	IF @EC = 0
	BEGIN
		INSERT INTO #XC EXECUTE(@SQL) AT CMS;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	
	------------------------build merge-------------------------------------------------
	IF @EC = 0
	BEGIN
		SELECT * INTO #MC FROM BUILD_MERGE_SMASH('LGDAT','CUST','#XC') OPTION (MAXRECURSION 1000);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	------------------------move merge to scalar variable-------------------------------
	IF @EC = 0
	BEGIN
		SET @SQL = (SELECT CMD FROM #MC);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	
	------------------------execute merge-----------------------------------------------
	IF @EC = 0
	BEGIN
		EXECUTE(@SQL);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	
	------------------------drop temp tables--------------------------------------------
	IF @EC = 0
	BEGIN
		DROP TABLE #XC;
		DROP TABLE #MC;
		DROP TABLE #SC;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	---------------Write to details log---------------------------------------------------
	IF @EC = 0 
	BEGIN
		PRINT 'CUST PROCESSED CORRECTLY';
		INSERT INTO CTRL.IMP_DET VALUES (@NV, 'IMPORT_CUST', @EC, @PR, GETDATE());
		SET @PR = GETDATE();
		PRINT cast(DATEDIFF(MS,@PR,GETDATE()) as varchar(max)) + ' ms';
	END
	ELSE 
	BEGIN
		PRINT 'CUST PROCESSING ISSUE: ' + @EM
		ROLLBACK TRANSACTION AR;
		INSERT INTO CTRL.IMP_DET VALUES (@NV, 'IMPORT_CUST', @EC, @PR, GETDATE());
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
		COMMIT TRANSACTION AR;

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