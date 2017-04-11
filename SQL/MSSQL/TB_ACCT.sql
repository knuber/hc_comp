
----------------------------------OVERVIEW-------------------------------------------------------
--This view pulls the account balances and generates a pseudo financial statement
--that was originally designed to be part of an Excel pivot feed that can collapse
--and expand levels in a heirarchy.
--
--The idea for generation of financial statements in general is that each account is assigend to 
--an account group (LGDAT.FGRP). The account groups exist in a heirarchy with each level up
--being more summarized, so the farther down you drill the more detail you get.
--
--The hope was this feed could be used in COGNOS to accomplish a similar end, but where the 
--level reported is fixed to a preset definition. Because I don't know how COGNOS works exactly
--this feed may not be well aligned to the inputs that COGNOS works with
-------------------------------------------------------------------------------------------------
SELECT
	'20'+SUBSTRING(B.PERD,1,2) FSYR,
	'' QRTR,
	B.PERD FSPR,
	FORMAT(N1ED01,'yyMM') CAPR,
	OPSGRP,
	AZCOMP,
	CAST(AZCOMP AS VARCHAR(MAX))+ ' - ' + RTRIM(T.DESCR) COMP_DESCR,
	SUBS SUBSIDIARY,
	PARENT,
	B.ACCT ACCT, RTRIM(M.AZTITL) ACCT_DESCR,
	B.ACCT + ' - ' +RTRIM(M.AZTITL) ACCT_AND_DESCR,
	SUBSTRING(B.ACCT,7,4) PRIME,
	SUBSTRING(B.ACCT,7,6) PRIMESUB,
	M.AZFUT2,
	RTRIM(AZGROP) + ' - ' + RTRIM(G.BQ1TITL) FGRP,
	CASE WHEN AZATYP <= '3' THEN 'BALANCE SHEET' ELSE 'INCOME STATEMENT' END STMT,
	G.LVL0,
	G.LVL1,
	G.LVL2,
	G.LVL3,
	M.AZFUT3,
	RTRIM(C.D35DES1) EBITDA, 
	C.D35DES2 Department, 
	C.D35DES3 IC_Type, 
	C.D35USR1 IC_Pointer, 
	C.D35USR2 ELIM_GRP, 
	C.D35USR3 FuncArea,
	c.D35USR4 Consol_Level,
	B.OB OPEN_BAL,
	B.TT NET_CHANGE,
	B.OB + B.TT END_BAL
FROM
	FAnalysis.R.GLMT B
	LEFT OUTER JOIN FAnalysis.LGDAT.MAST M ON
		M.ACCT = B.ACCT
	LEFT OUTER JOIN FAnalysis.R.FGRP G ON
		G.BQ1GRP = M.AZGROP
	LEFT OUTER JOIN FAnalysis.LGDAT.GGTP C ON
		C.D35GCDE = M.AZFUT3
	LEFT OUTER JOIN FAnalysis.R.GLDATREF P ON
		P.N1COMP = M.AZCOMP AND
		P.N1FSYP = B.PERD
	LEFT OUTER JOIN dbo.COMP T on
		COMP = AZCOMP
WHERE   
    B.PERD >= '1601' AND
    B.PERD <= '1612' AND
    (
            B.OB <> 0 OR
            B.TT <> 0
    )