
CREATE TABLE RLARP.FFSTMTD(
	STMT varchar(255) ,
	SEQ int,
	FGRP varchar(7),
	EFLAG varchar(30),
	LINE int,
	L_DESCR varchar(255),
	AGG_FLG varchar(1),
	PLINE int,
	PRE_SIGN int,
	POST_SIGN int,
	STAT varchar(10),
	SUPP_S varchar(255)
);

-----------------------------------------------------------------------------------------------------	

CREATE VIEW RLARP.VSTMTH as
SELECT DISTINCT 
	STMT, PLINE, LINE, AGG_FLG
FROM 
	FFSTMTD 
WHERE 
	PLINE IS NOT NULL OR 
	AGG_FLG = 'X';
	
-----------------------------------------------------------------------------------------------------	
	
CREATE OR REPLACE FUNCTION RLARP.FSTMTAE(VSTMT VARCHAR(255)) 
RETURNS TABLE
(
	STMT VARCHAR(255),
	MAST INT,
	PLINE INT,
	CLINE INT,
	AF VARCHAR(255)
)
RETURN
WITH H (STMT, MAST, PLINE, CLIN, AF) AS
(
	SELECT DISTINCT
		STMT, LINE, 0, LINE, 'N'
	FROM
		 RLARP.VSTMTH 
	WHERE
		STMT = VSTMT AND
		AGG_FLG = 'X'
	
	UNION ALL

	SELECT
		H.STMT, MAST, H.CLIN, V.LINE, COALESCE(V.AGG_FLG,'N')
	FROM
		H
		INNER JOIN RLARP.VSTMTH V ON
			V.STMT = H.STMT AND
			V.PLINE = H.CLIN

)
	SELECT * FROM H WHERE COALESCE(AF,'') <> 'X' AND PLINE <> 0;
	
-----------------------------------------------------------------------------------------------------	

CREATE OR REPLACE FUNCTION RLARP.FSTMTIP (VFP VARCHAR(4), VTP VARCHAR(4), VSTMT VARCHAR(255)) 
RETURNS TABLE
(
	STMT VARCHAR(255),
	LINE INT,
	L_DESCR VARCHAR(255),
	AGG_FLG VARCHAR(255),
	PLINE INT,
	PRE_SIGN INT,
	POST_SIGN INT,
	STAT VARCHAR(255),
	NODEV FLOAT
)
RETURN
SELECT
	S.STMT, S.LINE, S.L_DESCR, S.AGG_FLG, S.PLINE, S.PRE_SIGN, S.POST_SIGN, S.STAT, SUM(A.NODEV) NODEV
FROM
	STMT_DEF S
	LEFT OUTER JOIN
	(
		--------EBITDA components pull if listed--------
		SELECT
			S.STMT, SEQ, S.FGRP, EFLAG, LINE, L_DESCR, PLINE, PRE_SIGN, SUM(NET_LOCAL) NODEV, SUM(NET_LOCAL) AGGV
		FROM 
			RLARP.FFSTMTD S
			INNER JOIN LGDAT.GGTP G ON
				G.D35DES1 = S.EFLAG
			INNER JOIN LGDAT.MAST M ON
				AZFUT3 = G.D35GCDE
			INNER JOIN RLARP.VW_FFTBJCS B ON
				AJ4COMP||DIGITS(AJ4GL#1)||DIGITS(AJ4GL#2) = AZCOMP||DIGITS(AZGL#1)||DIGITS(AZGL#2) AND
				B.FSPR >= VFP AND
				B.FSPR <= VTP
		WHERE
			S.STMT = VSTMT
		GROUP BY
			S.STMT, SEQ, S.FGRP, EFLAG, LINE, L_DESCR, PLINE, PRE_SIGN

		UNION ALL

		------pull account group balances where EBITDA column on statement is null
		SELECT
			S.STMT, SEQ, S.FGRP, EFLAG, LINE, L_DESCR, PLINE, PRE_SIGN, SUM(NETT) NODEV, SUM(NETT) AGGV
		FROM 
			RLARP.FFSTMTD S
			INNER JOIN LGDAT.MAST M ON
				M.AZGROP = S.FGRP
			INNER JOIN RLARP.VW_FFTBJCS B ON
				B.ACCT = M.ACCT AND
				B.FSPR >= VFP AND
				B.FSPR <= VTP
		WHERE
			S.STMT = VSTMT
		GROUP BY
			S.STMT, SEQ, S.FGRP, EFLAG, LINE, L_DESCR, PLINE, PRE_SIGN
	) A ON
		S.SEQ = A.SEQ
WHERE
	S.STMT = VSTMT
GROUP BY
	S.STMT, S.LINE, S.L_DESCR, S.AGG_FLG, S.PLINE, S.PRE_SIGN, S.POST_SIGN, S.STAT
	
-----------------------------------------------------------------------------------------------------
	
CREATE OR REPLACE FUNCTION RLARP.FSTMTPR(VFP VARCHAR(4), VTP VARCHAR(4), VSTMT VARCHAR(255)) 
RETURNS TABLE 
(
	STMT VARCHAR(255),
	LINE INT,
	STAT VARCHAR(255),
	LINE_D VARCHAR(255),
	AVALUE FLOAT,
	PVALUE FLOAT
)

RETURN
SELECT 
	S.STMT, S.LINE, STAT, COALESCE(S.L_DESCR,'') LINE_D, COALESCE(S.NODEV,A.AMT) AVALUE, COALESCE(S.NODEV,A.AMT)*POST_SIGN PVALUE
FROM 
	TABLE(RLARP.FSTMTIP(VFP,VTP,VSTMT)) S
	LEFT OUTER JOIN
	(
		SELECT 
			MAST, SUM(NODEV*PRE_SIGN) AMT
		FROM 
			TABLE(RLARP.FSTMTAE(VSTMT)) X
			INNER JOIN TABLE(RLARP.FSTMTIP(VFP,VTP,VSTMT)) A ON
				A.LINE = X.CLINE
		GROUP BY
			MAST
	) A ON
		A.MAST = S.LINE