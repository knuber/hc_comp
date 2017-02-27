
BEGIN

	--GET MAX DKRCID FROM GLSBAR AS MIN
	--UPDATE GLSBAR
	--GET MAX DCRCID FROM GLSBAR AS MAX
	--QUERY OID FOR INVOICES IN: 
		--GLSBAR WHERE IN MAX DKRCID RANGE AND 
		--FROM OIH WHERE DHTOTI = 0 AND CURRENT PERIOD AND NOT IN LIST FROM LOCAL (BUILD OUT)
	--SAME FOR OIH
	--NEED TO BE ABLE TO UPDATE UNPOSTED INVOICES AS WELL FOR REPORTING OUT ON THAT

	

	DECLARE @EC INT;
	DECLARE @EM VARCHAR(MAX);
	DECLARE @SQL VARCHAR(MAX);
	DECLARE @MAXRC VARCHAR(MAX);
	DECLARE @MINRC VARCHAR(MAX);
	DECLARE @MINP VARCHAR(MAX);
	DECLARE @ILIST VARCHAR(MAX);
	DECLARE @I VARCHAR(MAX);

	SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();

	-----------------determine max db2 value for dkrcid---------------------------------
	CREATE TABLE #MRC (MAXRI BIGINT);
	IF @EC = 0
	BEGIN	
		INSERT INTO #MRC EXEC ('SELECT MAX(DKRCID) FROM LGDAT.GLSBAR') AT CMS;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	
	-----------------push into scalar variable------------------------------------------
	IF @EC = 0
	BEGIN
		SELECT @MAXRC = (SELECT * FROM #MRC);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	-----------------determine max local dkrid------------------------------------------
	IF @EC = 0
	BEGIN
		SELECT @MINRC = (SELECT MAX(DKRCID) FROM LGDAT.GLSBAR);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	-----------------build select-------------------------------------------------------

	SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	IF @EC = 0
	BEGIN	
		SELECT CMD INTO #SAR FROM dbo.BUILD_DB2_SELECT('LGDAT','GLSBAR') OPTION (MAXRECURSION 1000);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	-----------------add where clause---------------------------------------------------
	IF @EC = 0
	BEGIN	
		SET @SQL = 
			(SELECT CMD FROM #SAR)
			+ ' WHERE DKRCID >= '
			+ @MINRC 
			+ ' AND DKRCID <= '
			+ @MAXRC;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	

	-----------------create table copy for import records-------------------------------
	IF @EC = 0
	BEGIN	
		SELECT * INTO #XAR FROM LGDAT.GLSBAR WHERE 0=1;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	-----------------execute sql into table copy----------------------------------------
	IF @EC = 0
	BEGIN	
		INSERT INTO #XAR EXECUTE(@SQL) AT CMS;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	-----------------build merge statement----------------------------------------------
	IF @EC = 0
	BEGIN	
		SELECT * INTO #MAR FROM BUILD_MERGE_SMASH('LGDAT','GLSBAR','#XAR') OPTION (MAXRECURSION 1000);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	
	-----------------convert to scalar variable-----------------------------------------
	IF @EC = 0
	BEGIN	
		SET @SQL = (SELECT CMD FROM #MAR);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	
	-----------------execute merge statement--------------------------------------------
	IF @EC = 0
	BEGIN	
		EXECUTE(@SQL);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	-----------------drop tables--------------------------------------------------------
	IF @EC = 0
	BEGIN	
		DROP TABLE #XAR;
		DROP TABLE #MAR;
		DROP TABLE #SAR;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	

	IF @EC = 0 PRINT 'GLSBAR PROCESSED CORRECTLY';
	ELSE PRINT 'GLSBAR PROCESSING ISSUE: ' + @EM;

	----------------get minimum period currently active----------------------

	IF @EC = 0
	BEGIN	
		SELECT @MINP = 
		(
			SELECT
				MIN (PERD)
			FROM
				(
				SELECT
					COMP,
					MAX(FORMAT(DKFSYY,'00')+FORMAT(DKFSPR,'00')) PERD
				FROM
					(
						SELECT
							SUBSTRING(CAST(DKACC# AS VARCHAR(MAX)),1,2) COMP,
							DKFSYY,
							DKFSPR
						FROM
							LGDAT.GLSBAR
						WHERE
							DKRCID >= @MAXRC
						GROUP BY
							SUBSTRING(CAST(DKACC# AS VARCHAR(MAX)),1,2),
							DKFSYY,
							DKFSPR
					) X
				GROUP BY
					COMP
				) X
		)
		OPTION (MAXDOP 8, RECOMPILE)
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	
	----------------build list of invoices already imported------------------

	IF @EC = 0
	BEGIN
		DECLARE C CURSOR FOR 
			SELECT 
				DHINV# 
			FROM 
				LGDAT.OIH 
			WHERE 
				DHTOTI = 0 AND 
				(
					DHARYR = CAST(SUBSTRING(@MINP,1,2) AS INTEGER) AND 
					DHARPR >= CAST(SUBSTRING(@MINP,3,2) AS INTEGER)
				) OR 
				DHARYR > CAST(SUBSTRING(@MINP,1,2) AS INTEGER)
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	----------------open cursor----------------------------------------------
	IF @EC = 0
	BEGIN
		OPEN C;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	----------------get first cursor row*------------------------------------
	IF @EC = 0
	BEGIN
		FETCH NEXT FROM C INTO @I;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	----------------set aggregator-------------------------------------------
	IF @EC = 0
	BEGIN
		SET @ILIST = @I
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	----------------get next cursor row--------------------------------------
	IF @EC = 0
	BEGIN
		FETCH NEXT FROM C INTO @I;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	----------------enter into cursor loop-----------------------------------
	IF @EC = 0 
	BEGIN
		WHILE @@FETCH_STATUS = 0
		BEGIN
			IF @EC = 0 
			BEGIN
				SET @ILIST = @ILIST + ',' + @I;
				SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
			END;
			IF @EC = 0 
			BEGIN
				FETCH NEXT FROM C INTO @I;
				SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
			END;
		END
	END

	----------------build oih selectyow--------------------------------------
	SELECT @SQL = 
		'SELECT * FROM LGDAT.OIH WHERE '
		+ '((DHARYR = '+ SUBSTRING(@MINP,1,2)
		+' AND DHARPR >= ' + SUBSTRING(@MINP,3,2)
		+ ') OR DHARYR > ' + SUBSTRING(@MINP,1,2)
		+ ') AND DHTOTI = 0 AND DHINV# NOT  IN ('
		+ @ILIST + ')'


	----------OID--------------------------

	IF @EC = 0
	BEGIN	
		SELECT CMD INTO #SD FROM dbo.BUILD_DB2_SELECT('LGDAT','OID') OPTION (MAXRECURSION 1000);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	
	IF @EC = 0
	BEGIN	
		SET @SQL = 
			(SELECT CMD FROM #SD) + 
			+ ' WHERE DIINV# IN (SELECT DISTINCT DKKEYN FROM LGDAT.GLSBAR WHERE DKRCID >= ' 
			+ @MINRC 
			+ ' AND DKRCID <= ' 
			+ @MAXRC
			+ ' AND DKSRCE = ''OE'' UNION SELECT DHINV# FROM LGDAT.OIH WHERE '
			+ '((DHARYR = '+ SUBSTRING(@MINP,1,2)
			+' AND DHARPR >= ' + SUBSTRING(@MINP,3,2)
			+ ') OR DHARYR > ' + SUBSTRING(@MINP,1,2)
			+ ') AND DHTOTI = 0 AND DHINV# NOT  IN ('
			+ @ILIST + '))';
		SELECT @SQL;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	
	IF @EC = 0
	BEGIN	
		SELECT * INTO #XD FROM LGDAT.OID WHERE 0=1;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	
	IF @EC = 0
	BEGIN	
		INSERT INTO #XD EXECUTE(@SQL) AT CMS;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	
	IF @EC = 0
	BEGIN	
		SELECT * INTO #MD FROM BUILD_MERGE_SMASH('LGDAT','OID','#XD') OPTION (MAXRECURSION 1000);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	
	IF @EC = 0
	BEGIN	
		SET @SQL = (SELECT CMD FROM #MD);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	
	
	IF @EC = 0
	BEGIN	
		EXECUTE(@SQL);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	
	IF @EC = 0
	BEGIN	
		DROP TABLE #XD;
		DROP TABLE #MD;
		DROP TABLE #SD;
		DROP TABLE #MRC
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	PRINT 'OID COMPLETE';

	--------------------------OIH--------------------------------

	IF @EC = 0
	BEGIN	
		SELECT CMD INTO #SH FROM dbo.BUILD_DB2_SELECT('LGDAT','OIH') OPTION (MAXRECURSION 1000);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	
	IF @EC = 0
	BEGIN	
		SET @SQL = 
			(SELECT CMD FROM #SH) + 
			+ ' WHERE DHINV# IN (SELECT DISTINCT DKKEYN FROM LGDAT.GLSBAR WHERE DKRCID >= ' 
			+ @MINRC	
			+ ' AND DKRCID <= ' 
			+ @MAXRC
			+ ' AND DKSRCE = ''OE'' UNION SELECT DHINV# FROM LGDAT.OIH WHERE '
			+ '((DHARYR = '+ SUBSTRING(@MINP,1,2)
			+' AND DHARPR >= ' + SUBSTRING(@MINP,3,2)
			+ ') OR DHARYR > ' + SUBSTRING(@MINP,1,2)
			+ ') AND DHTOTI = 0 AND DHINV# NOT  IN ('
			+ @ILIST + '))';
		SELECT @SQL;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	
	IF @EC = 0
	BEGIN	
		SELECT * INTO #XH FROM LGDAT.OIH WHERE 0=1;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	
	IF @EC = 0
	BEGIN	
		INSERT INTO #XH EXECUTE(@SQL) AT CMS;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	
	IF @EC = 0
	BEGIN	
		SELECT * INTO #MH FROM BUILD_MERGE_SMASH('LGDAT','OIH','#XH') OPTION (MAXRECURSION 1000);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	
	IF @EC = 0
	BEGIN	
		SET @SQL = (SELECT CMD FROM #MH);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END
	
	
	IF @EC = 0
	BEGIN	
		EXECUTE(@SQL);
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END

	
	IF @EC = 0
	BEGIN	
		DROP TABLE #XH;
		DROP TABLE #MH;
		DROP TABLE #SH;
		SELECT @EC = @@ERROR, @EM = ERROR_MESSAGE();
	END;
	PRINT 'OIH COMPLETE';


END;
