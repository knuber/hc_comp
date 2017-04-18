
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

  
WITH RECURSIVE PSE 
	(
		 ------------EXPLOSION TRACKING---------------- 
		LVL, PLINE, CLINE, MAST, MPLT, PRNT, CHLD, 
		 ------------PROCUREMENT----------------------- 
		STAT, REPL, 
		 ------------ROUTING--------------------------- 
		SEQ, DEP, RESC, OPC, REPP, REFF, XREFF, 
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
	A.V6PART, 
	A.V6PLNT, 
	A.V6PART, 
	A.V6PART, 
	A.V6STAT, 
	A.V6RPLN, 
	AOSEQ#, 
	AODEPT, 
	COALESCE (APVEND, AORESC), 
	COALESCE (APODES, AOOPNM), 
	AOREPP, 
	ROUND (FLOAT (1 / IFNULL (AOEFC1, 1)), 8), 
	ROUND (FLOAT (1 / IFNULL (AOEFC1, 1)), 8), 
	'R', 
	' ', 
	1, 
	1, 
	1, 
	1, 
	1, 
	1, 
	A.V6UNTI, 
	A.V6UNTI, 
	FLOAT (1), 
	A.V6PLNT, 
	CASE A.V6RPLN WHEN '3' THEN A.V6TPLN ELSE A.V6PLNT END, 
	SUBSTR (CC.A215, 152, 2), 
	SUBSTR (SC.A215, 152, 2), 
	B86SRTE 
FROM 
	LGDAT.STKA A 
	LEFT OUTER JOIN LGDAT.METHDR ON 
		AOPART = A.V6PART AND 
		AOPLNT = A.V6PLNT AND
		A.V6RPLN = 1
	LEFT OUTER JOIN LGDAT.METHDO ON 
		APPART = A.V6PART AND 
		APPLNT = CASE A.V6TPLN WHEN '' THEN A.V6PLNT ELSE A.V6TPLN END AND 
		A.V6RPLN = 1 
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
WHERE 
	V6PART = 'AZE06000B71C036LRT44' AND 
	V6PLNT = '112'
  
UNION ALL 
  
SELECT 
	PSE.LVL + 1, 
	-----parent sort key-----
	CASE PP.V6RPLN
		WHEN 1 THEN
			--if there are sequences less than 10, then then parent sequence of 9 must be 10 and the parent sequence of 8 must be 9 etc.
			--the parent of sequence 10 does not exist because it is the last one and can simply inherit the pse.pline sort key
			CASE WHEN AOSEQ# < 10 
				THEN 
					--parent line
					PSE.CLINE || '-' || 
					--BOM line # leading 0's
					REPEAT ('0', 3 - LENGTH (VARCHAR (M.AQLIN#))) || 
					--BOM line #
					VARCHAR (M.AQLIN#) || 
					--previous method sequence (assumption that 10 is final sequence and prior seq increment in order by 1 until they reach 10)
					SUBSTR (DIGITS (COALESCE (- AOSEQ# + 9, AQSEQ#)), 2, 3) 
				ELSE 
					VARCHAR (PSE.CLINE, 100) 
			END 
		ELSE
			PSE.CLINE
	END PLINE, 
	-----child sort key------
	CASE PP.V6RPLN
		WHEN 1 THEN
			--parent sort key
			PSE.CLINE || '-' || 
			--BOM line# leading 0's
			REPEAT ('0', 3 - LENGTH (VARCHAR (M.AQLIN#))) || 
			--BOM line#'s
			VARCHAR (M.AQLIN#) || 
			--method sequence #'s
			SUBSTR (DIGITS (COALESCE (- AOSEQ# + 10, AQSEQ#)), 2, 3) 
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
		WHEN 1 THEN M.AQMTLP
		WHEN 2 THEN ''
	END CHLD, 
	CASE PP.V6RPLN
		WHEN 1 THEN A.V6STAT
		ELSE PP.V6STAT
	END STAT,
	CASE PP.V6RPLN
		WHEN 1 THEN A.V6RPLN
		ELSE PP.V6RPLN
	END RPLN, 
	COALESCE (AOSEQ#, AQSEQ#), 
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
			--qty required per 1 parent
			FLOAT (M.AQQPPC / M.AQQTYM) / 
			--scrap factor in BOM
			FLOAT (1 - M.AQSCRP / 100) * 
			--byproduct flag
			CASE M.AQRQBY WHEN 'B' THEN - 1 ELSE 1 END
		,1) RQTY, 
	COALESCE(
			--qty required per 1 parent
			FLOAT (M.AQQPPC / M.AQQTYM) * 
			--parent extended required qty
			FLOAT (PSE.ERQTY) / 
			--scrap in BOM
			FLOAT (1 - M.AQSCRP / 100) * 
			--byproduct flag
			CASE M.AQRQBY WHEN 'B' THEN - 1 ELSE 1 END
		--parent extended req qty
		,PSE.ERQTY
	) ERQTY, 
	---build in transfer conversion here.
	--A2 is going to be either the BOM uom in the source plant (or consumption plant if none) or the uom of the parent part in the transfer plant if pass-through
	CASE PP.V6RPLN 
		WHEN 1 THEN 
			A2.V6UNTI
		ELSE
			PP.V6UNTI 
	END UNIT,
	COALESCE(M.AQUNIT,A2.V6UNTI) BUOM, 
	FLOAT (COALESCE (U.MULT_BY, 1)) * FLOAT (COALESCE (U2.MULT_BY, 1)) * PSE.CONV CONV, 
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
	SUBSTR (CC.A215, 152, 2), 
	SUBSTR (SC.A215, 152, 2), 
	B86SRTE * PSE.FXR 
FROM 
	PSE PSE 
	---join last leaf on tree to its procurement path
	INNER JOIN LGDAT.STKA PP ON
		PP.V6PART = PSE.CHLD AND
		PP.V6PLNT = PSE.SPLNT
	---the join to the bill of materials may not be used if transfered through a plant
	---if just tranfering through a plant, need to accomodate change in unit of measure !!!!
	---		-> get unit of measure in source plant and apply conversion?
	---			-> could possibly use the existing a2 table to join on a switch (either a pass-through or BOM component)
	LEFT OUTER JOIN LGDAT.METHDM M ON 
		M.AQPART = PSE.CHLD AND 
		M.AQPLNT = PSE.SPLNT AND 
		M.AQSEQ# = IFNULL (PSE.SEQ, M.AQSEQ#) AND 
		PP.V6RPLN = 1
		--this is going to have to accomodate type 1's that don't have a BOM in order to stop the explosion, otherwise it will recurse infinately
	---join the the procurement path of the BOM children
	LEFT OUTER JOIN LGDAT.STKA A ON 
		A.V6PART = M.AQMTLP AND 
		A.V6PLNT = M.AQPLNT 
	---join to the procurement of the BOM child in the source plant if different from the consumption plant to get the unit of measure there
	LEFT OUTER JOIN LGDAT.STKA A2 ON 
		A2.V6PART = CASE PP.V6RPLN 
						WHEN 3 THEN PSE.CHLD
						WHEN 1 THEN M.AQMTLP
						ELSE PP.V6PART
					END AND
		A2.V6PLNT = CASE PP.V6RPLN
						WHEN 3 THEN PP.V6TPLN 
						WHEN 1 THEN	
							CASE A.V6RPLN
								WHEN 3 THEN A.V6TPLN
								ELSE A.V6PLNT
							END
						ELSE PP.V6PLNT
					END
	LEFT OUTER JOIN LGDAT.METHDR ON 
		AOPART = M.AQMTLP AND 
		AOPLNT = CASE A.V6TPLN WHEN '' THEN A.V6PLNT ELSE A.V6TPLN END AND
		PP.V6RPLN = 1
	LEFT OUTER JOIN LGDAT.METHDO ON 
		APPART = M.AQMTLP AND 
		APPLNT = CASE A.V6TPLN WHEN '' THEN A.V6PLNT ELSE A.V6TPLN END AND 
		PP.V6RPLN = 1 
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
	) U2 ON 
		LTRIM (RTRIM (U2.UNT1)) = A.V6UNTI AND 
		LTRIM (RTRIM (U2.UNT2)) = A2.V6UNTI 
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
	AND PSE.REPL <> '2' 
) 
  
SELECT 
	MAST, 
	MPLT, 
	REPEAT ('.  ', LVL) || LVL AS TLVL, 
	REPEAT ('.  ', LVL) || CHLD TPART, 
	REPEAT ('.  ', LVL) || COALESCE (AWDES1, AVDES1) DESCR, 
	PLINE, 
	CLINE, 
	PSE.CHLD PART, 
	CPLNT, 
	STAT, REPL, SPLNT, SEQ, AAOSRV OUTS, DEP, RESC, OPC, AOREPP, 
	REFF, XREFF, 
	RQBY, BACK, 
	IFNULL (MM.AVMAJG, MP.AWMAJG) MAJG, 
	IFNULL (MM.AVMING, MP.AWMING) || ' - ' || RTRIM (MMGP.BRDES) MING, 
	IFNULL (MM.AVGLCD, MP.AWGLDC) GLCD, 
	IFNULL (MM.AVGLED, MP.AWGLED) GLED, 
	SCRP, 
	 --QTY, BQTY, 
	RQTY, 
	ERQTY, 
	ERQTY * (1 / XREFF - 1) ERQTYS, 
	UNTI, BUOM, CONV, 
	CPC, SPC, 
	 --FXR, 
	 --COALESCE(IP.CHCURR, IR.Y0FUT1) AS CURR, 
	CHAR (COALESCE (IP.CHSDAT, IR.Y0SDAT, IM.CGSDAT)) DT, 
	IP.CHSUC BASE, 
	IP.CHSFC FRT, 
	IP.CHSDC DUTY, 
	IP.CHS1C MISC1, 
	IP.CHS2C MISC2, 
	 -------------------------MOD 10/20/15----------------------------- 
	CASE REPL WHEN '2' THEN IP.CHSCC WHEN '3' THEN IR.Y0SOC ELSE 0 END AS CURR, 
	IR.Y0SSHC "S&H", 
	APFCSO "FRT-TO", 
	APFCSI "FRT-FROM", 
	APUNCS SUBC, 
	AORUNS RUNTIME, 
	AO#MEN / AO#MCH RUNCREW, 
	AOSETP SETTIME, 
	V6OPTR RUNSIZE, 
	AOSCRW SETCREW, 
	CASE ABLABR WHEN 0 THEN AASTDR ELSE ABLABR END LABRATE, 
	CASE ABBRDR WHEN 0 THEN AABRDR ELSE ABBRDR END FIXRATE, 
	CASE ABVBRD WHEN 0 THEN AAVBRD ELSE ABVBRD END VARRATE, 
	CASE ABLABR WHEN 0 THEN AASTDR ELSE ABLABR END / AORUNS * AO#MEN / AO#MCH LABRUN, 
	CASE ABBRDR WHEN 0 THEN AABRDR ELSE ABBRDR END / AORUNS FIXRUN, 
	CASE ABVBRD WHEN 0 THEN AAVBRD ELSE ABVBRD END / AORUNS VARRUN, 
	CASE ABLABR WHEN 0 THEN AASTDR ELSE ABLABR END * AOSETP * AOSCRW / V6OPTR LABSET, 
	CASE ABBRDR WHEN 0 THEN AABRDR ELSE ABBRDR END * AOSETP / V6OPTR FIXSET, 
	CASE ABVBRD WHEN 0 THEN AAVBRD ELSE ABVBRD END * AOSETP / V6OPTR VARSET, 
	 ----------EXTENDED VALUES---------- 
	IP.CHSUC * ERQTY BASEX, 
	IP.CHSFC * ERQTY FRTX, 
	CASE REPL WHEN '2' THEN IP.CHSCC WHEN '3' THEN IR.Y0SOC ELSE 0 END * ERQTY AS CURRX, 
	(IP.CHSDC + IP.CHS1C + IP.CHS2C + IR.Y0SSHC + APFCSO + APFCSI) * ERQTY OTHMX, 
	APUNCS * ERQTY SUBCX, 
	CASE ABLABR WHEN 0 THEN AASTDR ELSE ABLABR END / AORUNS * AO#MEN / AO#MCH * ERQTY LABRX, 
	CASE ABBRDR WHEN 0 THEN AABRDR ELSE ABBRDR END / AORUNS * ERQTY FIXRX, 
	CASE ABVBRD WHEN 0 THEN AAVBRD ELSE ABVBRD END / AORUNS * ERQTY VARRX, 
	CASE ABLABR WHEN 0 THEN AASTDR ELSE ABLABR END * AOSETP * AOSCRW / V6OPTR * ERQTY LABSX, 
	CASE ABBRDR WHEN 0 THEN AABRDR ELSE ABBRDR END * AOSETP / V6OPTR * ERQTY FIXSX, 
	CASE ABVBRD WHEN 0 THEN AAVBRD ELSE ABVBRD END * AOSETP / V6OPTR * ERQTY VARSX, 
	 --------SCRAP---------- 
	IP.CHSUC * ERQTY * (1 / XREFF - 1) BASEXS, 
	IP.CHSFC * ERQTY * (1 / XREFF - 1) FRTXS, 
	CASE PSE.LVL WHEN '0' THEN 0 ELSE CASE REPL WHEN '2' THEN IP.CHSCC WHEN '3' THEN IR.Y0SOC ELSE 0 END * ERQTY * (1 / XREFF - 1) END AS CURRXS, 
	(IP.CHSDC + IP.CHS1C + IP.CHS2C + IR.Y0SSHC + APFCSO + APFCSI) * ERQTY * (1 / XREFF - 1) OTHMXS, 
	APUNCS * ERQTY * (1 / XREFF - 1) SUBCXS, 
	CASE ABLABR WHEN 0 THEN AASTDR ELSE ABLABR END / AORUNS * AO#MEN / AO#MCH * ERQTY * (1 / XREFF - 1) LABRXS, 
	CASE ABBRDR WHEN 0 THEN AABRDR ELSE ABBRDR END / AORUNS * ERQTY * (1 / XREFF - 1) FIXRXS, 
	CASE ABVBRD WHEN 0 THEN AAVBRD ELSE ABVBRD END / AORUNS * ERQTY * (1 / XREFF - 1) VARRXS, 
	CASE ABLABR WHEN 0 THEN AASTDR ELSE ABLABR END * AOSETP * AOSCRW / V6OPTR * ERQTY * (1 / XREFF - 1) LABSXS, 
	CASE ABBRDR WHEN 0 THEN AABRDR ELSE ABBRDR END * AOSETP / V6OPTR * ERQTY * (1 / XREFF - 1) FIXSXS, 
	CASE ABVBRD WHEN 0 THEN AAVBRD ELSE ABVBRD END * AOSETP / V6OPTR * ERQTY * (1 / XREFF - 1) VARSXS 
FROM 
	PSE PSE 
	LEFT OUTER JOIN LGDAT.ICSTM IM ON 
		IM.CGPART = PSE.CHLD AND 
		IM.CGPLNT = PSE.SPLNT 
	LEFT OUTER JOIN LGDAT.ICSTP IP ON 
		IP.CHPART = PSE.CHLD AND 
		IP.CHPLNT = PSE.SPLNT 
	LEFT OUTER JOIN LGDAT.ICSTR IR ON 
		IR.Y0PART = PSE.CHLD AND 
		IR.Y0PLNT = PSE.CPLNT 
	LEFT OUTER JOIN LGDAT.METHDO ON 
		APPART = CHLD AND 
		APPLNT = SPLNT AND 
		APSEQ# = SEQ AND 
		APVEND = RESC 
	LEFT OUTER JOIN LGDAT.METHDR ON 
		AOPART = CHLD AND 
		AOPLNT = SPLNT AND 
		AOSEQ# = SEQ 
	LEFT OUTER JOIN LGDAT.STKA ON 
		V6PART = CHLD AND 
		V6PLNT = SPLNT 
	LEFT OUTER JOIN LGDAT.RESRE ON 
		ABPLNT = SPLNT AND 
		ABDEPT = PSE.DEP AND 
		ABRESC = RESC 
	LEFT OUTER JOIN LGDAT.DEPTS ON 
		AODEPT = AADEPT 
	LEFT OUTER JOIN LGDAT.STKMM MM ON 
		MM.AVPART = PSE.CHLD 
	LEFT OUTER JOIN LGDAT.STKMP MP ON 
		MP.AWPART = PSE.CHLD 
	LEFT OUTER JOIN LGDAT.MMGP MMGP ON 
		MMGP.BRMGRP = COALESCE (AWMING, AVMING) AND 
		MMGP.BRGRP = COALESCE (AWMAJG, AVMAJG) 
ORDER BY CLINE ASC 

