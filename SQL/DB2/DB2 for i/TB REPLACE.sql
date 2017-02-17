--  Generate SQL 
--  Version:                   	V7R1M0 100423 
--  Generated on:              	06/15/16 13:59:23 
--  Relational Database:       	S7830956 
--  Standards Option:          	DB2 for i 
CREATE VIEW RLARP.VW_FFTBLCS ( 
	COMP , 
	PLNT , 
	ACC , 
	PRIME , 
	AZTITL , 
	INACTIVE , 
	GLCC , 
	ELIM_TYPE , 
	ELIM_REL , 
	ELIM_DFGRP , 
	ELIM_CO , 
	FSPR , 
	CAPR , 
	SDAT , 
	EDAT , 
	FGRP , 
	STMT , 
	LVL0 , 
	LVL1 , 
	LVL2 , 
	LVL3 , 
	EBITDA , 
	DEPARTMENT , 
	DEP_GRP , 
	CURR , 
	OPEN_LOCAL , 
	NET_LOCAL , 
	END_LOCAL , 
	BDGT_LOCAL , 
	USD_OPEN , 
	USD_NET , 
	USD_END , 
	USD_BDGT ) 
	AS 
	SELECT  
			SUBSTR(ACC,1,2) AS COMP,  
			SUBSTR(ACC,3,2) PLNT,  
			ACC,  
			SUBSTR(ACC,7,4) PRIME,  
			AZTITL,  
			AZSTAT INACTIVE,  
			AZFUT3 GLCC,  
			RTRIM(D35DES3) ELIM_TYPE,  
			RTRIM(D35USR1) ELIM_REL,  
			RTRIM(D35USR2) ELIM_DFGRP, 
			SUBSTR(DIGITS(D35USR4),9,2) ELIM_CO, 
			PERIOD FSPR,  
			CAPR,  
			SDAT,  
			EDAT,  
			SUBSTR(LTRIM(D35USR2)||AZGROP,1,7)||' - '||RTRIM(TL.BQ1TITL) FGRP,  
			CASE WHEN AZATYP <= 3  
				THEN 'BALANCE SHEET'  
				ELSE 'INCOME STATEMENT'  
			END STMT,  
			SUBSTR(SUBSTR(LTRIM(D35USR2)||AZGROP,1,7),1,1)||' - '||RTRIM(SUBSTR(A249,1,30)) LVL0,  
			CASE LENGTH(RTRIM(SUBSTR(LTRIM(D35USR2)||AZGROP,1,7)))  
			WHEN 3 THEN SUBSTR(TL.BQ1GRP,2,2)||' - '||RTRIM(TL.BQ1TITL)  
			ELSE SUBSTR(FA.BQ1GRP,2,2)||' - '||RTRIM(FA.BQ1TITL)  
			END LVL1,  
			CASE LENGTH(RTRIM(SUBSTR(LTRIM(D35USR2)||AZGROP,1,7)))  
			WHEN 3 THEN ''  
			WHEN 5 THEN SUBSTR(TL.BQ1GRP,4,2)||' - '||RTRIM(TL.BQ1TITL)  
			ELSE SUBSTR(FB.BQ1GRP,4,2)||' - '||RTRIM(FB.BQ1TITL)  
			END LVL2,  
			CASE LENGTH(RTRIM(SUBSTR(LTRIM(D35USR2)||AZGROP,1,7)))  
			WHEN 3 THEN ''  
			WHEN 5 THEN ''  
			ELSE SUBSTR(TL.BQ1GRP,6,2)||' - '||RTRIM(TL.BQ1TITL)  
			END LVL3,  
			RTRIM(D35DES1) EBITDA,  
			RTRIM(SUBSTR(ACC,5,2)||CASE WHEN LENGTH(RTRIM(D35DES2)) >0 THEN ' - '||D35DES2 ELSE '' END) DEPARTMENT,  
			RTRIM(D35USR3) DEP_GRP,  
			AZFUT2 CURR, 
			OPEN OPEN_LOCAL,  
			NET NET_LOCAL,  
			END END_LOCAL,  
			BDGT BDGT_LOCAL,  
			OPEN * RATE USD_OPEN,  
			NET * RATE USD_NET,  
			END * RATE USD_END,  
			BDGT * RATE USD_BDGT  
		FROM 
			RLARP.V_GLMT B
			LEFT OUTER JOIN LGDAT.GGTP G,
				D35GCDE = B.AZFUT3  
			LEFT OUTER JOIN LGDAT.NAME N ON  
				SUBSTR(N.A7,7,1) = SUBSTR(LTRIM(D35USR2)||B.AZGROP,1,1) AND  
				SUBSTR(N.A7,1,1) = 'A'  
			LEFT OUTER JOIN LGDAT.FGRP TL ON  
				TL.BQ1GRP = SUBSTR(LTRIM(D35USR2)||AZGROP,1,7)  
			LEFT OUTER JOIN LGDAT.FGRP FA ON  
				FA.BQ1GRP = SUBSTR(TL.BQ1GRP,1,3) AND  
				LENGTH(RTRIM(TL.BQ1GRP)) >=5  
			LEFT OUTER JOIN LGDAT.FGRP FB ON  
				FB.BQ1GRP = SUBSTR(TL.BQ1GRP,1,5) AND  
				LENGTH(RTRIM(TL.BQ1GRP)) >=7  
			LEFT OUTER JOIN RLARP.FFCRET X ON  
				X.PERD = PERIOD AND  
				X.FCUR = AZFUT2 AND  
				X.TCUR = 'US' AND  
				X.RTYP = CASE WHEN AZATYP <= 3 THEN 'ME' ELSE 'MA' END  
			LEFT OUTER JOIN RLARP.VW_FFGLPD ON  
				COMP = SUBSTR(ACC,1,2) AND  
				FSPR = PERIOD  
		WHERE  
			(  
			OPEN <> 0 OR  
			NET <> 0 OR  
			END <> 0  
			)   
	RCDFMT VW_FFTBLCS ; 
  
LABEL ON TABLE RLARP.VW_FFTBLCS 
	IS 'Acct - Trial Balance - Logical Consolidation' ; 
  
LABEL ON COLUMN RLARP.VW_FFTBLCS 
( COMP IS 'Company' , 
	PLNT IS 'Plant' , 
	ACC IS 'Accoun' , 
	PRIME IS 'Prime' , 
	AZTITL IS 'Title' , 
	INACTIVE IS 'Status' , 
	GLCC IS 'GL Category Code' , 
	ELIM_TYPE IS 'Elimiatation Type' , 
	ELIM_REL IS 'Elimination Relationship' , 
	ELIM_DFGRP IS 'Destination Account Group' , 
	ELIM_CO IS 'Eliminating Company' , 
	FSPR IS 'Fiscal Period' , 
	CAPR IS 'Calendar Period' , 
	SDAT IS 'Start Date' , 
	EDAT IS 'End Date' , 
	FGRP IS 'Account Group' , 
	STMT IS 'Statement' , 
	LVL0 IS 'Level 0' , 
	LVL1 IS 'Level 1' , 
	LVL2 IS 'Level 2' , 
	LVL3 IS 'Level 3' , 
	EBITDA IS 'EBITDA Categorization' , 
	DEPARTMENT IS 'Department & Description' , 
	DEP_GRP IS 'Department Group' , 
	CURR IS 'Currency' , 
	OPEN_LOCAL IS 'Openign Balance in Local Currency' , 
	NET_LOCAL IS 'Net Activity in Local Currency' , 
	END_LOCAL IS 'Ending Balance in Local Currency' , 
	BDGT_LOCAL IS 'Budget in Local Currency' , 
	USD_OPEN IS 'Openign Balance in USD' , 
	USD_NET IS 'Net Activtiy in USD' , 
	USD_END IS 'Ending Balance in USD' , 
	USD_BDGT IS 'Budget in USD' ) ; 
  
LABEL ON COLUMN RLARP.VW_FFTBLCS 
( COMP TEXT IS 'Company' , 
	PLNT TEXT IS 'Plant' , 
	ACC TEXT IS 'Accoun' , 
	PRIME TEXT IS 'Prime' , 
	AZTITL TEXT IS 'Title' , 
	INACTIVE TEXT IS 'Status' , 
	GLCC TEXT IS 'GL Category Code' , 
	ELIM_TYPE TEXT IS 'Elimiatation Type' , 
	ELIM_REL TEXT IS 'Elimination Relationship' , 
	ELIM_DFGRP TEXT IS 'Destination Account Group' , 
	ELIM_CO TEXT IS 'Eliminating Company' , 
	FSPR TEXT IS 'Fiscal Period' , 
	CAPR TEXT IS 'Calendar Period' , 
	SDAT TEXT IS 'Start Date' , 
	EDAT TEXT IS 'End Date' , 
	FGRP TEXT IS 'Account Group' , 
	STMT TEXT IS 'Statement' , 
	LVL0 TEXT IS 'Level 0' , 
	LVL1 TEXT IS 'Level 1' , 
	LVL2 TEXT IS 'Level 2' , 
	LVL3 TEXT IS 'Level 3' , 
	EBITDA TEXT IS 'EBITDA Categorization' , 
	DEPARTMENT TEXT IS 'Department & Description' , 
	DEP_GRP TEXT IS 'Department Group' , 
	CURR TEXT IS 'Currency' , 
	OPEN_LOCAL TEXT IS 'Openign Balance in Local Currency' , 
	NET_LOCAL TEXT IS 'Net Activity in Local Currency' , 
	END_LOCAL TEXT IS 'Ending Balance in Local Currency' , 
	BDGT_LOCAL TEXT IS 'Budget in Local Currency' , 
	USD_OPEN TEXT IS 'Openign Balance in USD' , 
	USD_NET TEXT IS 'Net Activtiy in USD' , 
	USD_END TEXT IS 'Ending Balance in USD' , 
	USD_BDGT TEXT IS 'Budget in USD' ) ; 
  
GRANT ALTER , REFERENCES , SELECT   
ON RLARP.VW_FFTBLCS TO PTROWBRIDG WITH GRANT OPTION ; 
  
GRANT SELECT   
ON RLARP.VW_FFTBLCS TO PUBLIC ;
