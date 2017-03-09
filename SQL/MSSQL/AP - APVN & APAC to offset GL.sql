--SET SHOWPLAN_ALL ON
--SET SHOWPLAN_ALL OFF
--SET STATISTICS PROFILE OFF
SET STATISTICS IO ON;
WITH
	-----------list of accounts to exclude that hold the vouchered amount--------------------------
	XL (APA) AS
	(
		SELECT CAST(IFCOM# AS VARCHAR(MAX))+FORMAT(IFAPGL,'0000000000') FROM LGDAT.CONT
	),
	------------pre-aggregate the detail-----------------------------------------------------------
	D (ACCT, MODULE, CUSVEND, PERD, AMT)
	AS
	(
		SELECT 
			ACCT,
			MODULE, 
			CUSVEND, 
			PERD, 
			SUM(AMT) AMT
		FROM 
			FANALYSISP.DBO.FFSBGLR1 D
			LEFT OUTER JOIN XL ON
				XL.APA = D.ACCT
		WHERE	
			PERD >= '1601' AND
			MODULE IN ('APVN','APAC') AND
			SUBSTRING(D.ACCT,1,2) <> '66' AND
			XL.APA IS NULL
		GROUP BY
			ACCT,
			MODULE, 
			CUSVEND, 
			PERD
	),
	------------build the account attributes-------------------------------------------------------
	AM (ACCT, FGRP_DESCR, D35DES2, D35USR3) AS
	(
		SELECT	
			M.ACCT,
			CASE WHEN SUBSTRING(AZGROP,1,1) <= '4' THEN AZGROP ELSE SUBSTRING(AZGROP,LEN(RTRIM(AZGROP))-1,2) END +' - '+ COALESCE(RM.DESCR,BQ1TITL) FGRP_DESCR, 
			D35DES2, 
			D35USR3
		FROM
			FANALYSIS.LGDAT.MAST M
			LEFT OUTER JOIN FANALYSIS.LGDAT.FGRP ON
				AZGROP = BQ1GRP
			LEFT OUTER JOIN FANALYSIS.LGDAT.GGTP ON
				D35GCDE = AZFUT3
			--------------------cross reference material related account groups to materials-----------------------------
			LEFT OUTER JOIN 
				(
					SELECT '1103040' FGRP, 'MATERIALS' DESCR UNION ALL
					SELECT '2101020' FGRP, 'MATERIALS' DESCR UNION ALL
					SELECT '5401060' FGRP, 'MATERIALS' DESCR
				) RM ON
				RM.FGRP = AZGROP
		GROUP BY
			M.ACCT,
			CASE WHEN SUBSTRING(AZGROP,1,1) <= '4' THEN AZGROP ELSE SUBSTRING(AZGROP,LEN(RTRIM(AZGROP))-1,2) END +' - '+ COALESCE(RM.DESCR,BQ1TITL),
			D35DES2, 
			D35USR3
	)
-------------final select-------------------
SELECT
	D.MODULE, 
	D.CUSVEND+' - '+RTRIM(BTNAME) VEND,
	SUM(D.AMT) AMT,
	AM.FGRP_DESCR, 
	AM.D35DES2, 
	RTRIM(AM.D35USR3) FUNCAREA, 
	D.PERD
FROM
	D 
	LEFT OUTER JOIN 
	---------------------cross reference PPV account to inventory account----------------------------------------
	(
		SELECT DISTINCT
			CAST(YACOMP AS VARCHAR(MAX))+FORMAT(Y1PRVR,'0000000000') PPVG, CAST(YACOMP AS VARCHAR(MAX))+CASE YAACRL WHEN 0 THEN SUBSTRING(A249,228,10) ELSE FORMAT(YAACRL,'0000000000') END ACCG
		FROM 
			FANALYSIS.LGDAT.GLIE
			LEFT OUTER JOIN FANALYSIS.LGDAT.PLNT ON
				YAPLNT = Y1PLNT
			LEFT OUTER JOIN FANALYSIS.LGDAT.NAME ON
				A7 = 'C0000'+CAST(YACOMP AS VARCHAR(MAX))
	) GS ON
		PPVG = ACCT
	LEFT OUTER JOIN AM ON
		AM.ACCT = COALESCE(ACCG, D.ACCT)
	LEFT OUTER JOIN LGDAT.VEND ON
		BTVEND = CUSVEND
GROUP BY
	MODULE, 
	D.CUSVEND+' - '+RTRIM(BTNAME),
	AM.FGRP_DESCR, 
	AM.D35DES2, 
	AM.D35USR3, 
	PERD
OPTION (MAXDOP 8);
SET STATISTICS IO OFF;