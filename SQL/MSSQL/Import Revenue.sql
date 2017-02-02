BEGIN

	--GET MAX DKRCID FROM GLSBAR AS MIN
	--UPDATE GLSBAR
	--GET MAX DCRCID FROM GLSBAR AS MAX
	--QUERY OID FOR INVOICES IN: 
		--GLSBAR WHERE IN MAX DKRCID RANGE AND 
		--FROM OIH WHERE DHTOTI = 0 AND CURRENT PERIOD AND NOT IN LIST FROM LOCAL (BUILD OUT)
	--SAME FOR OIH
	

	DECLARE @EC INT;
	DECLARE @EM VARCHAR(MAX);
	DECLARE @SQL VARCHAR(MAX);
	DECLARE @MINID NUMERIC(12,0);
	DECLARE @MAXID NUMERIC(12,0);
	
	
	SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	
	-----------------------------GET MAX RECID AS MIN RECID----------------------------------------------

	IF @EC = 0
	BEGIN	
		SELECT @MINID = SELECT MAX(DKRCID) FROM LGDAT.GLSBAR;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	
	-----------------------------BUILD SELECT------------------------------------------------------------

	IF @EC = 0
	BEGIN	
		SELECT CMD INTO #S FROM dbo.BUILD_DB2_SELECT('LGDAT','GLSBAR') OPTION (MAXRECURSION 1000);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	
	-----------------------------ADD WHERE CLAUSE--------------------------------------------------------

	IF @EC = 0
	BEGIN	
		SET @SQL = 
			(SELECT CMD FROM #S)
			+ ' WHERE DKRCID >= '
			+ (SELECT CAST(MAX(DKRCID) AS VARCHAR(MAX)) FROM LGDAT.GLSBAR);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	-----------------------------CREATE A TABLE COPY-----------------------------------------------------
	
	IF @EC = 0
	BEGIN	
		SELECT * INTO #X FROM LGDAT.GLSBAR WHERE 0=1;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	
	-----------------------------EXECUTE SELECT----------------------------------------------------------

	IF @EC = 0
	BEGIN	
		INSERT INTO #X EXECUTE(@SQL) AT CMS;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	-----------------------------CREATE MERGE RETENTION TABLE--------------------------------------------
	
	IF @EC = 0
	BEGIN
		SELECT CAST('X' AS VARCHAR(MAX)) FLAG, * INTO #A FROM LGDAT.GLSBAR WHERE 0=1;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	-----------------------------BUILD MERGE-------------------------------------------------------------
	
	IF @EC = 0
	BEGIN	
		SELECT * INTO #M FROM BUILD_MERGE_SMASH_KEEP('LGDAT','GLSBAR','#X','#A') OPTION (MAXRECURSION 1000);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	
	
	-----------------------------PUSH MERGE TO SCALAR VARIABLE-------------------------------------------

	
	IF @EC = 0
	BEGIN	
		SET @SQL = (SELECT CMD FROM #M);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	
	-----------------------------EXECUTE MERGE-----------------------------------------------------------
	
	IF @EC = 0
	BEGIN	
		EXECUTE(@SQL);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	-----------------------------CLEAN UP TEMP TABLES----------------------------------------------------
	
	SELECT * FROM #A

	

END;