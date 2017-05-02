SET STATISTICS IO ON;
WITH G AS (
	SELECT
		PERD,
		ACCT,
		MODULE, 
		CUSMOD,
		dbo.sfn_GL_CATEGORY(MODULE, CUSMOD, CUSKEY1, CUSKEY2, CUSKEY3, CUSKEY4, dbo.RETURN_NONBLANK(CUSVEND, CUSCUST,'')) TRAN1,
		dbo.sfn_GL_CATEGORY_2(MODULE, CUSMOD, CUSKEY1, CUSKEY2, CUSKEY3, CUSKEY4, dbo.RETURN_NONBLANK(CUSVEND, CUSCUST,'')) TRAN2,
		CUSVEND,
		CUSCUST,
		SUM(AMT) AMT
	FROM
		FANALYSISP.DBO.FFSBGLR1
	WHERE
		PERD >= '1604' AND
		SUBSTRING(ACCT,1,2) > '19' AND
		(SUBSTRING(ACCT,7,1) = '7' OR SUBSTRING(ACCT,7,4) IN ('1305','2103'))
	GROUP BY 
		PERD,
		ACCT,
		MODULE, 
		CUSMOD,
		dbo.sfn_GL_CATEGORY(MODULE, CUSMOD, CUSKEY1, CUSKEY2, CUSKEY3, CUSKEY4, dbo.RETURN_NONBLANK(CUSVEND, CUSCUST,'')),
		dbo.sfn_GL_CATEGORY_2(MODULE, CUSMOD, CUSKEY1, CUSKEY2, CUSKEY3, CUSKEY4, dbo.RETURN_NONBLANK(CUSVEND, CUSCUST,'')),
		CUSVEND,
		CUSCUST

)
SELECT	
	SUBSTRING(T.ACCT,1,2) COMP,
	'20'+SUBSTRING(T.PERD,1,2) FSYR,
	FORMAT(P.N1SD01,'yyMM') CAPR,
	G.BQ1GRP + ' - ' + RTRIM(G.BQ1TITL) FGRP,
	RTRIM(G.BQ1TITL) FGRP_DESCR,
	T.ACCT + ' - ' + M.AZTITL ACCOUNT, 
	SUBSTRING(T.ACCT,7,4) PRIME,
	MODULE, 
	CUSMOD,
	TRAN1,
	TRAN2,
	CUSVEND + ' - '+ BTNAME VENDOR,
	CUSCUST + ' - '+ BVNAME CUSTOMER,
	CASE WHEN M.AZATYP <= '3' THEN 'BALANCE SHEET' ELSE 'INCOME STATEMENT' END STMT,
	G.LVL0,
	G.LVL1,
	G.LVL2,
	G.LVL3,
	M.AZFUT3,
	C.D35DES1 EBITDA, 
	C.D35DES2 Department, 
	C.D35DES3 IC_Type, 
	C.D35USR1 IC_Pointer, 
	C.D35USR2 ELIM_GRP, 
	RTRIM(C.D35USR3) FuncArea,
	T.AMT TRANS_BASE,
	T.AMT*COALESCE(F.RATE,1) TRANS_USD
FROM
	G T
	INNER JOIN FAnalysis.LGDAT.MAST M ON --ACOUNT MASTER
		M.ACCT = T.ACCT
	LEFT OUTER JOIN FAnalysis.LGDAT.GGTP C ON	--GL CATEGORY CODE MASTER
		C.D35GCDE = M.AZFUT3
	LEFT OUTER JOIN FAnalysis.R.FGRP G ON --ACCOUNT GROUP MASTER
		G.BQ1GRP = COALESCE(C.D35USR2,M.AZGROP)
	LEFT OUTER JOIN FAnalysis.R.GLDATREF P ON	--PERIOD MASTER
		P.N1COMP = SUBSTRING(T.ACCT,1,2) AND
		P.N1FSYP = T.PERD
	LEFT OUTER JOIN FANALYSIS.R.FFCRET F ON				--EXCHANGE RATES
		F.FCUR = M.AZFUT2 AND
		F.TCUR = 'US' AND
		F.PERD = T.PERD AND
		F.RTYP = CASE WHEN M.AZATYP <= '3' THEN 'ME' ELSE 'MA' END
	LEFT JOIN FANALYSIS.LGDAT.VEND ON
		BTVEND = CUSVEND
	LEFT JOIN FANALYSIS.LGDAT.CUST ON
		BVCUST = CUSCUST

option (maxdop 8, recompile)