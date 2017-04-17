CREATE TABLE QGPL.FFBSMRPC(
    MAST VARCHAR(20), 
	MPLT VARCHAR(3), 
	TLVL VARCHAR(255), 
	TPART VARCHAR(255), 
	DESCR VARCHAR(255), 
	PLINE VARCHAR(255), 
	CLINE VARCHAR(255), 
	PART VARCHAR(255), 
	CPLNT VARCHAR(255), 
	STAT VARCHAR(255), 
    REPL VARCHAR(255), 
    SPLNT VARCHAR(255), 
    SEQ NUMERIC(3,0), 
    OUTS VARCHAR(255), 
    DEP VARCHAR(255), 
    RESC VARCHAR(255), 
    OPC VARCHAR(255), 
    AOREPP VARCHAR(255), 
	REFF FLOAT, 
    XREFF FLOAT, 
	RQBY VARCHAR(1), 
    BACK VARCHAR(1), 
	MAJG VARCHAR(255), 
	MING VARCHAR(255), 
	GLCD VARCHAR(255), 
	GLED VARCHAR(255), 
	SCRP FLOAT, 
	RQTY FLOAT, 
	ERQTY FLOAT, 
	ERQTYS FLOAT, 
	UNTI VARCHAR(255),
    BUOM VARCHAR(255),
    CONV FLOAT, 
	CPC VARCHAR(255), 
    SPC VARCHAR(255), 
	DT DATE, 
	BASE FLOAT, 
	FRT FLOAT, 
	DUTY FLOAT, 
	MISC1 FLOAT, 
	MISC2 FLOAT, 
	CURR FLOAT, 
	"S&H" FLOAT, 
	"FRT-TO" FLOAT, 
	"FRT-FROM" FLOAT, 
	SUBC FLOAT, 
	RUNTIME FLOAT, 
	RUNCREW FLOAT, 
	SETTIME FLOAT, 
	RUNSIZE FLOAT, 
	SETCREW FLOAT, 
	LABRATE FLOAT, 
	FIXRATE FLOAT, 
	VARRATE FLOAT, 
	LABRUN FLOAT, 
	FIXRUN FLOAT, 
	VARRUN FLOAT, 
	LABSET FLOAT, 
	FIXSET FLOAT, 
	VARSET FLOAT, 
	BASEX FLOAT, 
	FRTX FLOAT, 
	CURRX FLOAT, 
	OTHMX FLOAT, 
	SUBCX FLOAT, 
	LABRX FLOAT, 
	FIXRX FLOAT, 
	VARRX FLOAT, 
	LABSX FLOAT, 
	FIXSX FLOAT, 
	VARSX FLOAT, 
	BASEXS FLOAT, 
	FRTXS FLOAT, 
	CURRXS FLOAT, 
	OTHMXS FLOAT, 
	SUBCXS FLOAT, 
	LABRXS FLOAT, 
	FIXRXS FLOAT, 
	VARRXS FLOAT, 
	LABSXS FLOAT, 
	FIXSXS FLOAT, 
	VARSXS FLOAT

);

CREATE TABLE QGPL.FFBSUPP(PLNT VARCHAR(3), PART VARCHAR(20), SEQ INT);

INSERT INTO 
	QGPL.FFBSUPP
SELECT
	PLNT,
	PART,
	ROW_NUMBER() OVER (ORDER BY PLNT, PART)
FROM
	QGPL.FFBS0403
WHERE
	SUBSTR(GLEC,1,1) IN ('1','2') AND
	B_SHIPDATE + I_SHIPDATE DAYS >= '2017-06-01' AND
	B_SHIPDATE + I_SHIPDATE DAYS < '2018-06-01'
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

INSERT INTO
    QGPL.FFBSMRPC
WITH
	RECURSIVE PSE 
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
	VARCHAR (SUBSTR (DIGITS (INT (RANK () OVER (ORDER BY A.V6PART ASC, A.V6PLNT ASC))), 6, 5), 100) || 
	CASE WHEN AOSEQ# < 10 
		THEN SUBSTR (DIGITS (- AOSEQ# + 9), 2, 3) 
		ELSE '' 
	END AS PLINE, 
	VARCHAR (SUBSTR (DIGITS (INT (RANK () OVER (ORDER BY A.V6PART ASC, A.V6PLNT ASC))), 6, 5), 100) || SUBSTR (DIGITS (- AOSEQ# + 10), 2, 3) AS CLINE, 
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
	QGPL.FFBSUPP SALES
	LEFT OUTER JOIN LGDAT.STKA A ON
		V6PART = SALES.PART AND
		V6PLNT = SALES.PLNT
	LEFT OUTER JOIN LGDAT.METHDR ON 
		AOPART = A.V6PART AND 
		AOPLNT = CASE A.V6RPLN WHEN '3' THEN A.V6TPLN ELSE A.V6PLNT END 
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
  
UNION ALL 
  
SELECT 
	PSE.LVL + 1, 
	CASE WHEN AOSEQ# < 10 
		THEN PSE.CLINE || '-' || REPEAT ('0', 3 - LENGTH (VARCHAR (M.AQLIN#))) || VARCHAR (M.AQLIN#) || SUBSTR (DIGITS (COALESCE (- AOSEQ# + 9, AQSEQ#)), 2, 3) 
		ELSE VARCHAR (PSE.CLINE, 100) 
	END, 
	PSE.CLINE || '-' || REPEAT ('0', 3 - LENGTH (VARCHAR (M.AQLIN#))) || VARCHAR (M.AQLIN#) || SUBSTR (DIGITS (COALESCE (- AOSEQ# + 10, AQSEQ#)), 2, 3), 
	PSE.MAST, 
	PSE.MPLT, 
	PSE.CHLD, 
	M.AQMTLP, 
	A.V6STAT, 
	A.V6RPLN, 
	COALESCE (AOSEQ#, AQSEQ#), 
	AODEPT, 
	COALESCE (APVEND, AORESC), 
	COALESCE (APODES, AOOPNM), 
	AOREPP, 
	ROUND (FLOAT (1 / IFNULL (AOEFC1, 1)), 8), 
	ROUND (FLOAT (1 / IFNULL (AOEFC1, 1)), 8) * PSE.XREFF, 
	M.AQRQBY, 
	M.AQBACK, 
	FLOAT (1 - M.AQSCRP / 100), 
	1, 
	M.AQQPPC, 
	M.AQQTYM, 
	FLOAT (M.AQQPPC / M.AQQTYM) / FLOAT (1 - M.AQSCRP / 100) * CASE M.AQRQBY WHEN 'B' THEN - 1 ELSE 1 END, 
	FLOAT (M.AQQPPC / M.AQQTYM) * FLOAT (PSE.ERQTY) / FLOAT (1 - M.AQSCRP / 100) * CASE M.AQRQBY WHEN 'B' THEN - 1 ELSE 1 END, 
	A.V6UNTI, 
	M.AQUNIT, 
	FLOAT (COALESCE (U.MULT_BY, 1)) * FLOAT (COALESCE (U2.MULT_BY, 1)) * PSE.CONV, 
	M.AQPLNT, 
	CASE A.V6RPLN WHEN '3' THEN A.V6TPLN ELSE M.AQPLNT END, 
	SUBSTR (CC.A215, 152, 2), 
	SUBSTR (SC.A215, 152, 2), 
	B86SRTE * PSE.FXR 
FROM 
	PSE PSE 
	INNER JOIN LGDAT.METHDM M ON 
		M.AQPART = PSE.CHLD AND 
		M.AQPLNT = PSE.SPLNT AND 
		M.AQSEQ# = IFNULL (PSE.SEQ, M.AQSEQ#) AND 
		 ----------MOD 10/20/15------------- 
		PSE.REPL <> '2' 
	LEFT OUTER JOIN LGDAT.STKA A ON 
		A.V6PART = M.AQMTLP AND 
		A.V6PLNT = M.AQPLNT 
	LEFT OUTER JOIN LGDAT.STKA A2 ON 
		A2.V6PART = M.AQMTLP AND 
		A2.V6PLNT = A.V6TPLN 
	LEFT OUTER JOIN LGDAT.METHDR ON 
		AOPART = M.AQMTLP AND 
		AOPLNT = CASE A.V6TPLN WHEN '' THEN A.V6PLNT ELSE A.V6TPLN END AND
		A.V6RPLN = 1
	LEFT OUTER JOIN LGDAT.METHDO ON 
		APPART = M.AQMTLP AND 
		APPLNT = CASE A.V6TPLN WHEN '' THEN A.V6PLNT ELSE A.V6TPLN END AND 
		A.V6RPLN = 1 
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
		CP.YAPLNT = M.AQPLNT 
	LEFT OUTER JOIN LGDAT.PLNT SP ON 
		SP.YAPLNT = CASE A.V6RPLN WHEN '3' THEN A.V6TPLN ELSE M.AQPLNT END 
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
	AND PSE.REPL <> '4' 
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

FETCH FIRST 10000 ROWS ONLY