USE [FAnalysis]
GO

/****** Object:  UserDefinedFunction [dbo].[STMT_IPULL]    Script Date: 1/17/2017 8:50:13 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


ALTER FUNCTION [dbo].[STMT_IPULL](@FP VARCHAR(4), @TP VARCHAR(4), @STMT VARCHAR(255)) RETURNS TABLE AS
RETURN
SELECT
	S.STMT, S.LINE, S.L_DESCR, S.AGG_FLG, S.PLINE, S.PRE_SIGN, S.POST_SIGN, S.STAT, SUM(A.NODEV) NODEV
FROM
	STMT_DEF S
	LEFT OUTER JOIN
	(
		--------EBITDA components pull if listed--------
		SELECT
			STMT, SEQ, S.FGRP, EFLAG, LINE, L_DESCR, PLINE, PRE_SIGN, SUM(NETT) NODEV, SUM(NETT) AGGV
		FROM 
			STMT_DEF S
			INNER JOIN LGDAT.GGTP G ON
				RTRIM(G.D1) = RTRIM(S.EFLAG)
			INNER JOIN LGDAT.MAST M ON
				M.AZFUT3 = G.D35GCDE
			INNER JOIN R.GLMT B ON
				B.ACCT = M.ACCT AND
				B.PERD >= @FP AND
				B.PERD <= @TP
		WHERE
			S.STMT = @STMT
		GROUP BY
			STMT, SEQ, S.FGRP, EFLAG, LINE, L_DESCR, PLINE, PRE_SIGN

		UNION ALL

		------pull account group balances where EBITDA column on statement is null
		SELECT
			STMT, SEQ, S.FGRP, EFLAG, LINE, L_DESCR, PLINE, PRE_SIGN, SUM(TT) NODEV, SUM(TT) AGGV
		FROM 
			STMT_DEF S
			INNER JOIN LGDAT.MAST M ON
				M.AZGROP = S.FGRP
			INNER JOIN R.GLMT B ON
				B.ACCT = M.ACCT AND
				B.PERD >= @FP AND
				B.PERD <= @TP
		WHERE
			S.STMT = @STMT
		GROUP BY
			STMT, SEQ, S.FGRP, EFLAG, LINE, L_DESCR, PLINE, PRE_SIGN
	) A ON
		S.SEQ = A.SEQ
WHERE
	S.STMT = @STMT
GROUP BY
	S.STMT, S.LINE, S.L_DESCR, S.AGG_FLG, S.PLINE, S.PRE_SIGN, S.POST_SIGN, S.STAT

GO


