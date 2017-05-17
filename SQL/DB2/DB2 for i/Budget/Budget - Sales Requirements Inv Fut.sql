
DROP TABLE QGPL.FFBSUPP;

CREATE TABLE QGPL.FFBSUPP(PLNT VARCHAR(3), PART VARCHAR(20), SEQ INT);

INSERT INTO 
	QGPL.FFBSUPP
SELECT
	PLNT,
	PART,
	ROW_NUMBER() OVER (ORDER BY PLNT, PART)
FROM
	QGPL.FFBS0516
GROUP BY
	PLNT,
	PART
ORDER BY 
	PLNT,
	PART;


--PRODUCT STRUCTURE EXPLOSION DETAILS-- 
--REVISION LEVEL 3
---------------------------------------------------------------------------------------------------------------------------------------- 
--This result set explodes the METHDM bill of materials along the STKA.V6RPLN procurement path and 
--links in the routings & burden rates to get to a detailed rebuild of the product cost. 
--The explosion method is a recursive CTE (common table expression) that operates like a self join. 
--the explosion stops if it encounters a replenishment type 2 or exceeds 10 levels which is interpreted as an infinite loop somewhere 
--the last select breaks out all possible data points 
--duty, shipping and warehousing on the ICSTR file and the misc1 & 2 cost categories functions are not known but included here anyways 
--it is assumed any conversion issues are handled in a single step by the PUNIT file, which doesn't always have a single step conversion 
---------------------------------------------------------------------------------------------------------------------------------------- 

--DROP TABLE QGPL.FFBSMRPC;

/*
optional to create the table do 
CREATE TABLE
	QGPL.FFBSMRC AS

(
	CTE
) WITH NO DATA
*/

DELETE FROM QGPL.FFBSREQF;

INSERT INTO 
	QGPL.FFBSREQF
WITH RECURSIVE PSE 
	(
		 ------------EXPLOSION TRACKING---------------- 
		LVL, PLINE, CLINE, MAST, MPLT, PRNT, CHLD, RTYP,
		 ------------PROCUREMENT----------------------- 
		STAT, REPL, 
		 ------------ROUTING--------------------------- 
		SEQ, OSRV, DEP, RESC, OPC, REPP, REFF, XREFF, 
		 ------------BILL OF MATERIALS----------------- 
		RQBY, BACK, SCRP, EFF, QTY, BQTY, RQTY, ERQTY, 
		 ------------UOM CONVERSIONS------------------- 
		UNTI, BUOM, CONV, 
		 ------------SOURCING-------------------------- 
		CPLNT, SPLNT, 
		 ------------CURRENCY-------------------------- 
		CPC, SPC, FXR 
	) AS 
(
SELECT 
	0, 
	/* sort key must accomodate pass-through transfers & multiple sequences*/
	------parent sort key----------
	VARCHAR (
		SUBSTR (
			DIGITS (
				INT (
					RANK () OVER (ORDER BY A.V6PART ASC, A.V6PLNT ASC)
				)
			)
		, 6, 5)
	, 100) || 
	CASE WHEN AOSEQ# < 10 
		THEN SUBSTR (DIGITS (- AOSEQ# + 9), 2, 3) 
		ELSE '' 
	END AS PLINE, 
	------child sort key (master)----------
	VARCHAR (
		SUBSTR (
			DIGITS (
				INT (
					RANK () OVER (ORDER BY A.V6PART ASC, A.V6PLNT ASC)
				)
			)
		, 6, 5)
	, 100) || 
	CASE A.V6RPLN
		WHEN 1 THEN
			SUBSTR (DIGITS (- AOSEQ# + 10), 2, 3) 
		WHEN 3 THEN 'T' || A.V6TPLN	
		WHEN 2 THEN ''
	END AS CLINE, 
	---------------------------
	A.V6PART MAST, 
	A.V6PLNT MPLT, 
	A.V6PART PRNT, 
	A.V6PART CHLD, 
	CASE A.V6RPLN
		WHEN 1 THEN 'R'
		WHEN 2 THEN 'B'
		WHEN 3 THEN 'T'
	END RTYP,
	A.V6STAT STAT, 
	A.V6RPLN RPLN, 
	AOSEQ# SEQ, 
	AAOSRV OSRV,
	AODEPT DEP, 
	COALESCE (APVEND, AORESC) RESC, 
	COALESCE (APODES, AOOPNM) OPC, 
	AOREPP REPP, 
	ROUND (FLOAT (1 / IFNULL (AOEFC1, 1)), 8) REFF, 
	ROUND (FLOAT (1 / IFNULL (AOEFC1, 1)), 8) XREFF, 
	'R' RQBY, 
	' ' BACK, 
	1 SCRP, 
	1 EFF, 
	1 QTY,  
	1 BQTY, 
	1 RQTY, 
	1 ERQTY, 
	A.V6UNTI UNIT, 
	A.V6UNTI BUOM, 
	FLOAT (1) CONV, 
	A.V6PLNT CPLNT, 
	CASE A.V6RPLN WHEN '3' THEN A.V6TPLN ELSE A.V6PLNT END SPLNT, 
	SUBSTR (CC.A215, 152, 2) CPC, 
	SUBSTR (SC.A215, 152, 2) SPC, 
	B86SRTE FXR
FROM 
	QGPL.FFBSUPP S
	INNER JOIN  LGDAT.STKA A  ON
		S.PART = V6PART AND
		S.PLNT = V6PLNT
	LEFT OUTER JOIN LGDAT.FUTHDR ON 
		AOPART = A.V6PART AND 
		AOPLNT = A.V6PLNT AND
		A.V6RPLN = 1
	LEFT OUTER JOIN LGDAT.DEPTS ON
		AADEPT = AODEPT
	LEFT OUTER JOIN LGDAT.FUTHDO ON 
		APPART = A.V6PART AND 
		APPLNT = CASE A.V6TPLN WHEN '' THEN A.V6PLNT ELSE A.V6TPLN END AND 
		A.V6RPLN = 1 AND
		AAOSRV = 'Y'
	LEFT OUTER JOIN LGDAT.PLNT CP ON 
		CP.YAPLNT = A.V6PLNT 
	LEFT OUTER JOIN LGDAT.PLNT SP ON 
		SP.YAPLNT = CASE A.V6RPLN WHEN '3' THEN A.V6TPLN ELSE A.V6PLNT END 
	LEFT OUTER JOIN LGDAT.CODE CC ON 
		LTRIM (RTRIM (CC.A9)) = CP.YACOMP AND 
		CC.A2 = 'AA' 
	LEFT OUTER JOIN LGDAT.CODE SC ON 
		LTRIM (RTRIM (SC.A9)) = SP.YACOMP AND 
		SC.A2 = 'AA' 
	LEFT OUTER JOIN LGDAT.CRET ON 
		B86COMN = SP.YACOMP AND 
		B86CURC = SUBSTR (CC.A215, 152, 2) AND 
		B86RTTY = 'S' 
  
UNION ALL 
/*
===============================================================================================================================================================================================================
*/  

SELECT 
	PSE.LVL + 1, 
	-----parent sort key-----
	CASE PP.V6RPLN
		WHEN 1 THEN
			CASE PSE.RTYP
				WHEN 'R' THEN
					PSE.CLINE
				ELSE
					--should evaluate to a scenario where the incoming parent is a make but is not a routing (thus the initial routing linkage)
					--it is assumed that all the sequnces at play will be present in the routing and sync with all other method file sequences of the same number

					--if there are sequences less than 10, then then parent sequence of 9 must be 10 and the parent sequence of 8 must be 9 etc.
					--the parent of sequence 10 does not exist because it is the last one and can simply inherit the pse.pline sort key
					CASE WHEN AOSEQ# < 10 
						THEN 
							--parent line
							PSE.CLINE || '-' || 
							--BOM line # leading 0's
							REPEAT ('0', 3 - LENGTH (VARCHAR (R.AOLIN#))) || 
							--BOM line #
							VARCHAR (R.AOLIN#) ||
							--previous method sequence (assumption that 10 is final sequence and prior seq increment in order by 1 until they reach 10)
							SUBSTR (DIGITS (- AOSEQ# + 9), 2, 3) 
						ELSE 
							PSE.CLINE
					END 
			END
		ELSE
			PSE.CLINE
	END PLINE, 
	-----child sort key------
	CASE PP.V6RPLN
		WHEN 1 THEN
			CASE PSE.RTYP
				WHEN 'R' THEN
					--parent sort key
					PSE.CLINE || '-' || 
					--BOM line# leading 0's
					REPEAT ('0', 3 - LENGTH (VARCHAR (M.AQLIN#))) || 
					--BOM line#'s
					VARCHAR (M.AQLIN#) || 
					--method sequence #'s
					SUBSTR (DIGITS (AQSEQ#), 2, 3) 
				ELSE
					--parent sort key
					PSE.CLINE || '-' || 
					--BOM line# leading 0's
					REPEAT ('0', 3 - LENGTH (VARCHAR (R.AOLIN#))) || 
					--BOM line#'s
					VARCHAR (R.AOLIN#) || 
					--method sequence #'s
					SUBSTR (DIGITS (- AOSEQ# + 10), 2, 3) 
			END
		WHEN 3 THEN
			--parent sort key
			PSE.CLINE || '-' ||
			--transfer plant
			'00T'||PP.V6TPLN
		WHEN 2 THEN
			PSE.CLINE
	END CLINE,
	-------------------------
	PSE.MAST, 
	PSE.MPLT, 
	PSE.CHLD PRNT, 
	CASE PP.V6RPLN
		WHEN 3 THEN PSE.CHLD
		WHEN 1 THEN COALESCE(M.AQMTLP,PSE.CHLD)
		WHEN 2 THEN ''
	END CHLD, 
	CASE PSE.RTYP
		WHEN 'R' THEN
			CASE PP.V6RPLN
				WHEN 1 THEN 'B'
			END
		WHEN 'B' THEN
			CASE PP.V6RPLN
				WHEN 1 THEN 'R'
				WHEN 3 THEN 'T'
				ELSE ''
			END
		WHEN 'T' THEN
			CASE PP.V6RPLN
				WHEN 1 THEN 'R'
				WHEN 2 THEN 'B'
				WHEN 3 THEN 'T'
			END
	END RTYP,
	CASE PP.V6RPLN
		WHEN 1 THEN 
			CASE PSE.RTYP
				WHEN 'R' THEN
				 	A.V6STAT
				ELSE
					PP.V6STAT
			END
		ELSE
			PP.V6STAT
	END STAT,
	CASE PP.V6RPLN
		WHEN 1 THEN A.V6RPLN
		ELSE PP.V6RPLN
	END RPLN, 
	COALESCE (AOSEQ#, AQSEQ#), 
	AAOSRV,
	AODEPT, 
	COALESCE (APVEND, AORESC), 
	COALESCE (APODES, AOOPNM), 
	AOREPP, 
	ROUND (FLOAT (1 / IFNULL (AOEFC1, 1)), 8), 
	ROUND (FLOAT (1 / IFNULL (AOEFC1, 1)), 8) * PSE.XREFF, 
	COALESCE(M.AQRQBY,'R') RQBY, 
	COALESCE(M.AQBACK,'') BACK, 
	COALESCE(FLOAT (1 - M.AQSCRP / 100),1.0) SCRP, 
	1 EFF, 
	COALESCE(M.AQQPPC,1) QTY, 
	COALESCE(M.AQQTYM,1) BQTY, 
	COALESCE(
		CASE M.AQQTYM
			WHEN 0 
				THEN 0
			ELSE
				--qty required per 1 parent
				FLOAT (M.AQQPPC / M.AQQTYM) / 
				--scrap factor in BOM
				FLOAT (1 - M.AQSCRP / 100) * 
				--byproduct flag
				CASE M.AQRQBY WHEN 'B' THEN - 1 ELSE 1 END
		END
	,1) RQTY, 
	COALESCE(
		CASE M.AQQTYM
			WHEN 0 
				THEN 0
			ELSE
				--qty required per 1 parent
				FLOAT (M.AQQPPC / M.AQQTYM) * 
				--parent extended required qty
				FLOAT (PSE.ERQTY) / 
				--scrap in BOM
				FLOAT (1 - M.AQSCRP / 100) * 
				--byproduct flag
				CASE M.AQRQBY WHEN 'B' THEN - 1 ELSE 1 END
			--parent extended req qty
		END
	,PSE.ERQTY) ERQTY, 
	---build in transfer conversion here.
	--A2 is going to be either the BOM uom in the source plant (or consumption plant if none) or the uom of the parent part in the transfer plant if pass-through
	CASE PP.V6RPLN 
		WHEN 1 THEN 
			A.V6UNTI
		ELSE
			PP.V6UNTI 
	END UNIT,
	M.AQUNIT BUOM, 
	FLOAT (COALESCE (U.MULT_BY, 1)) * PSE.CONV CONV, 
	PSE.SPLNT CPLNT, 
	--the consumption plant coudl be either a pass through transfer or otherwise need to get the procurement of the BOM components to see if they need transfered
	CASE PP.V6RPLN
		WHEN 3 THEN PP.V6TPLN 
		WHEN 1 THEN	
			CASE A.V6RPLN
				WHEN 3 THEN A.V6TPLN
				ELSE A.V6PLNT
			END
		ELSE PP.V6PLNT
	END SPLNT,
	SUBSTR (CC.A215, 152, 2) CPC, 
	SUBSTR (SC.A215, 152, 2) SPC, 
	B86SRTE * PSE.FXR 
FROM 
	PSE PSE 
	---join last leaf on tree to its procurement path
	INNER JOIN LGDAT.STKA PP ON
		PP.V6PART = PSE.CHLD AND
		PP.V6PLNT = PSE.SPLNT
	LEFT OUTER JOIN LGDAT.FUTHDR R ON
		AOPART = PSE.CHLD AND
		AOPLNT = PSE.SPLNT AND
		PP.V6RPLN = 1 AND
		PSE.RTYP IN ('B','T')
	LEFT OUTER JOIN LGDAT.DEPTS ON
		AADEPT = AODEPT
	LEFT OUTER JOIN LGDAT.FUTHDO ON
		AAOSRV = 'Y' AND
		APPART = AOPART AND
		APPLNT = AOPLNT AND
		APSEQ# = AOSEQ#
	LEFT OUTER JOIN LGDAT.FUTHDM M ON
		M.AQPART = PSE.CHLD AND
		M.AQPLNT = PSE.SPLNT AND
		M.AQSEQ# = PSE.SEQ AND
		PP.V6RPLN = 1 AND
		PSE.RTYP = 'R'
		--this is going to have to accomodate type 1's that don't have a BOM in order to stop the explosion, otherwise it will recurse infinately
		--dependency that there is only one os sequence
	---join the the procurement path of the BOM children
	LEFT OUTER JOIN LGDAT.STKA A ON 
		A.V6PART = COALESCE(M.AQMTLP,PSE.CHLD) AND 
		A.V6PLNT = PSE.SPLNT
	LEFT OUTER JOIN 
	(
	SELECT 
		IHUNT1 AS UNT1, IHUNT2 AS UNT2, IHCNV2 / IHCNV1 AS MULT_BY 
	FROM 
		LGDAT.PUNIT 
	WHERE 
		IHPART = '&&GLOBAL' 
  
	UNION ALL 
  
	SELECT 
		IHUNT2 AS UNT1, IHUNT1 AS UNT2, IHCNV1 / IHCNV2 AS MULT_BY 
	FROM 
		LGDAT.PUNIT 
	WHERE 
		IHPART = '&&GLOBAL' 
	) U ON 
		U.UNT1 = M.AQUNIT AND 
		U.UNT2 = A.V6UNTI 
	LEFT OUTER JOIN LGDAT.PLNT CP ON 
		CP.YAPLNT = PSE.SPLNT
	LEFT OUTER JOIN LGDAT.PLNT SP ON 
		SP.YAPLNT = CASE PP.V6RPLN
						WHEN 3 THEN PP.V6TPLN 
						WHEN 1 THEN	
							CASE A.V6RPLN
								WHEN 3 THEN A.V6TPLN
								ELSE A.V6PLNT
							END
						ELSE PP.V6PLNT
					END
	LEFT OUTER JOIN LGDAT.CODE CC ON 
		LTRIM (RTRIM (CC.A9)) = CP.YACOMP AND 
		CC.A2 = 'AA' 
	LEFT OUTER JOIN LGDAT.CODE SC ON 
		LTRIM (RTRIM (SC.A9)) = SP.YACOMP AND 
		SC.A2 = 'AA' 
	LEFT OUTER JOIN LGDAT.CRET ON 
		B86COMN = SP.YACOMP AND 
		B86CURC = SUBSTR (CC.A215, 152, 2) AND 
		B86RTTY = 'S'		 
WHERE 
	LVL <= 10 
	AND PSE.REPL <> '2' AND
	COALESCE(AOPLNT,AQPLNT,PP.V6TPLN,'') <> ''

) 
  
SELECT 
	MAST, 
	MPLT, 
	REPEAT ('.  ', LVL) || LVL AS TLVL, 
	REPEAT ('.  ', LVL) || CHLD TPART, 
	REPEAT ('.  ', LVL) || COALESCE (AWDES1, AVDES1) DESCR, 
	PLINE, 
	CLINE, 
	RTYP,
	PSE.CHLD PART, 
	CPLNT, 
	STAT, 
	REPL,
	SPLNT, 
	SEQ, 
	OSRV OUTS, 
	DEP, 
	RESC, 
	OPC, 
	REPP, 
	REFF, 
	XREFF, 
	RQBY, 
	BACK, 
	IFNULL (MM.AVMAJG, MP.AWMAJG) MAJG, 
	IFNULL (MM.AVMING, MP.AWMING) || ' - ' || RTRIM (MMGP.BRDES) MING, 
	IFNULL (MM.AVGLCD, MP.AWGLDC) GLCD, 
	IFNULL (MM.AVGLED, MP.AWGLED) GLED, 
	SCRP, 
	 --QTY, BQTY, 
	RQTY, 
	ERQTY, 
	ERQTY * (1 / XREFF - 1) ERQTYS, 
	UNTI, 
	BUOM, 
	CONV, 
	CPC, 
	SPC, 
	 --FXR, 
	 --COALESCE(IP.COCURR, IR.Y3FUT1) AS CURR, 
	COALESCE (IP.COSDAT, IR.Y3SDAT, IM.CNSDAT) DT, 
	CASE REPL 
		WHEN 2 THEN COALESCE(IP.COSUC, IM.CNSTCS, IR.Y3STCS)
		ELSE IP.COSUC
	END BASE, 
	IP.COSFC FRT, 
	IP.COSDC DUTY, 
	IP.COS1C MISC1, 
	IP.COS2C MISC2, 
	 -------------------------MOD 10/20/15----------------------------- 
	CASE REPL WHEN '2' THEN IP.COSCC WHEN '3' THEN IR.Y3SOC ELSE 0 END AS CURR, 
	IR.Y3SSHC "S&H", 
	APFCSO "FRT-TO", 
	APFCSI "FRT-FROM", 
	APUNCS SUBC, 
	AORUNS RUNTIME, 
	AO#MEN / AO#MCH RUNCREW, 
	AOSETP SETTIME, 
	V6OPTR RUNSIZE, 
	AOSCRW SETCREW, 
	CASE R9LABR WHEN 0 THEN R8STDR ELSE R9LABR END LABRATE, 
	CASE R9BRDR WHEN 0 THEN R8BRDR ELSE R9BRDR END FIXRATE, 
	CASE R9VBRD WHEN 0 THEN R8VBRD ELSE R9VBRD END VARRATE, 
	CASE WHEN OSRV = 'Y' 
		THEN 0 
		ELSE 
			CASE R9LABR 
				WHEN 0 THEN 
					R8STDR 
				ELSE 
					R9LABR 
			END 
			/ AORUNS 
			* AO#MEN 
			/ AO#MCH 
	END LABRUN, 
	CASE WHEN OSRV = 'Y' 
		THEN 0 
		ELSE 
			CASE R9BRDR 
				WHEN 0 THEN 
					R8BRDR 
				ELSE 
					R9BRDR
			END 
			/ AORUNS 
	END FIXRUN, 
	CASE WHEN OSRV = 'Y' 
		THEN 0 
		ELSE 
			CASE R9VBRD 
				WHEN 0 THEN 
					R8VBRD 
				ELSE 
					R9VBRD 
			END 
			/ AORUNS 
	END VARRUN, 
	CASE R9LABR WHEN 0 THEN R8STDR ELSE R9LABR END * AOSETP * AOSCRW / V6OPTR LABSET, 
	CASE R9BRDR WHEN 0 THEN R8BRDR ELSE R9BRDR END * AOSETP / V6OPTR FIXSET, 
	CASE R9VBRD WHEN 0 THEN R8VBRD ELSE R9VBRD END * AOSETP / V6OPTR VARSET, 
	 ----------EXTENDED VALUES---------- 
	CASE REPL 
		WHEN 2 THEN COALESCE(IP.COSUC, IM.CNSTCS, IR.Y3STCS)
		ELSE IP.COSUC
	END * ERQTY BASEX, 
	IP.COSFC * ERQTY FRTX, 
	IP.COSDC * ERQTY DUTYX,
	IP.COS1C * ERQTY MULT1X,
	IP.COS2C * ERQTY MULT2X,
	IR.Y3SSHC * ERQTY SHIPHX,
	APFCSO * ERQTY OSFTX,
	APFCSI * ERQTY OSFFX,
	CASE REPL WHEN '2' THEN IP.COSCC WHEN '3' THEN IR.Y3SOC ELSE 0 END * ERQTY AS CURRX, 
	APUNCS * ERQTY SUBCX, 
	CASE WHEN OSRV = 'Y' THEN 0 ELSE CASE R9LABR WHEN 0 THEN R8STDR ELSE R9LABR END / AORUNS * AO#MEN / AO#MCH * ERQTY  END LABRX, 
	CASE WHEN OSRV = 'Y' THEN 0 ELSE CASE R9BRDR WHEN 0 THEN R8BRDR ELSE R9BRDR END / AORUNS * ERQTY END FIXRX, 
	CASE WHEN OSRV = 'Y' THEN 0 ELSE CASE R9VBRD WHEN 0 THEN R8VBRD ELSE R9VBRD END / AORUNS * ERQTY END VARRX, 
	CASE R9LABR WHEN 0 THEN R8STDR ELSE R9LABR END * AOSETP * AOSCRW / V6OPTR * ERQTY LABSX, 
	CASE R9BRDR WHEN 0 THEN R8BRDR ELSE R9BRDR END * AOSETP / V6OPTR * ERQTY FIXSX, 
	CASE R9VBRD WHEN 0 THEN R8VBRD ELSE R9VBRD END * AOSETP / V6OPTR * ERQTY VARSX, 
	 --------SCRAP---------- 
	CASE REPL 
		WHEN 2 THEN COALESCE(IP.COSUC, IM.CNSTCS, IR.Y3STCS)
		ELSE IP.COSUC
	END * ERQTY * (1 / XREFF - 1) BASEXS, 
	IP.COSFC * ERQTY * (1 / XREFF - 1) FRTXS, 
	IP.COSDC * ERQTY * (1 / XREFF - 1) DUTYXS,
	IP.COS1C * ERQTY * (1 / XREFF - 1) MULT1XS,
	IP.COS2C * ERQTY * (1 / XREFF - 1) MULT2XS,
	IR.Y3SSHC * ERQTY * (1 / XREFF - 1) SHIPHXS,
	APFCSO * ERQTY * (1 / XREFF - 1) OSFTXS,
	APFCSI * ERQTY * (1 / XREFF - 1)  OSFFXS,
	CASE PSE.LVL WHEN '0' THEN 0 ELSE CASE REPL WHEN '2' THEN IP.COSCC WHEN '3' THEN IR.Y3SOC ELSE 0 END * ERQTY * (1 / XREFF - 1) END AS CURRXS, 
	APUNCS * ERQTY * (1 / XREFF - 1) SUBCXS, 
	CASE WHEN OSRV = 'Y' THEN 0 ELSE CASE R9LABR WHEN 0 THEN R8STDR ELSE R9LABR END / AORUNS * AO#MEN / AO#MCH * ERQTY * (1 / XREFF - 1) END LABRXS, 
	CASE WHEN OSRV = 'Y' THEN 0 ELSE CASE R9BRDR WHEN 0 THEN R8BRDR ELSE R9BRDR END / AORUNS * ERQTY * (1 / XREFF - 1) END FIXRXS, 
	CASE WHEN OSRV = 'Y' THEN 0 ELSE CASE R9VBRD WHEN 0 THEN R8VBRD ELSE R9VBRD END / AORUNS * ERQTY * (1 / XREFF - 1) END VARRXS, 
	CASE R9LABR WHEN 0 THEN R8STDR ELSE R9LABR END * AOSETP * AOSCRW / V6OPTR * ERQTY * (1 / XREFF - 1) LABSXS, 
	CASE R9BRDR WHEN 0 THEN R8BRDR ELSE R9BRDR END * AOSETP / V6OPTR * ERQTY * (1 / XREFF - 1) FIXSXS, 
	CASE R9VBRD WHEN 0 THEN R8VBRD ELSE R9VBRD END * AOSETP / V6OPTR * ERQTY * (1 / XREFF - 1) VARSXS
FROM 
	PSE PSE 
	LEFT OUTER JOIN LGDAT.FTCSTM IM ON
		IM.CNPART = PSE.CHLD AND
		IM.CNPLNT = PSE.SPLNT
	LEFT OUTER JOIN LGDAT.FTCSTP IP ON
		IP.COPART = PSE.CHLD AND
		IP.COPLNT = PSE.SPLNT
	LEFT OUTER JOIN LGDAT.FTCSTR IR ON
		IR.Y3PART = PSE.CHLD AND
		IR.Y3PLNT = PSE.CPLNT
	LEFT OUTER JOIN LGDAT.FUTHDO ON
		APPART = CHLD AND
		APPLNT = SPLNT AND
		APSEQ# = SEQ AND
		APVEND = RESC
	LEFT OUTER JOIN LGDAT.FUTHDR ON 
		AOPART = CHLD AND
		AOPLNT = SPLNT AND
		AOSEQ# = SEQ AND
		PSE.RTYP = 'R'
	LEFT OUTER JOIN LGDAT.STKA ON
		V6PART = CHLD AND
		V6PLNT = SPLNT
	LEFT OUTER JOIN LGDAT.FRESRE ON
		R9PLNT = SPLNT AND
		R9DEPT = PSE.DEP AND
		R9RESC = RESC
	LEFT OUTER JOIN LGDAT.FDEPTS ON
		AODEPT = R8DEPT 
	LEFT OUTER JOIN LGDAT.STKMM MM ON
		MM.AVPART = PSE.CHLD 
	LEFT OUTER JOIN LGDAT.STKMP MP ON
		MP.AWPART = PSE.CHLD 
	LEFT OUTER JOIN LGDAT.MMGP MMGP ON
		MMGP.BRMGRP = COALESCE (AWMING, AVMING) AND
		MMGP.BRGRP = COALESCE (AWMAJG, AVMAJG)
ORDER BY CLINE ASC;