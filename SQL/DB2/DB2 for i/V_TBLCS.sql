--  Generate SQL 
--  Version:                   	V7R1M0 100423 
--  Generated on:              	06/22/16 11:12:24 
--  Relational Database:       	S7830956 
--  Standards Option:          	DB2 for i 
CREATE VIEW RLARP.V_TBLCS ( 
	COMP , 
	PLNT , 
	ACCT , 
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
			ACC ACCT,  
			SUBSTR(ACC,7,4) PRIME,  
			AZTITL,  
			AZSTAT INACTIVE,  
			AZFUT3 GLCC,  
			RTRIM(D35DES3) ELIM_TYPE,  
			RTRIM(D35USR1) ELIM_REL,  
			RTRIM(D35USR2) ELIM_DFGRP, 
			SUBSTR(DIGITS(D35USR4),9,2) ELIM_CO, 
			B.PERD FSPR,  
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
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  			B.OB OPEN_LOCAL,  
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             			B.NT NET_LOCAL,  
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              			B.EB END_LOCAL,  
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              			B.BG BDGT_LOCAL,  
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             			B.OB * RATE USD_OPEN,  
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        			B.NT * RATE USD_NET,  
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         			B.EB * RATE USD_END,  
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         			B.BG * RATE USD_BDGT  
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         		FROM 	  
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        			( 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             				SELECT  
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      					AJ4CCYY, P.ACC, AZTITL, AZSTAT, AZATYP, AZGROP, AZFUT3, AZFUT2, P.PERD, P.OB, P.NT, P.EB, P.BG, P.FC  
                                                                                                                                                                                                                                                                                                                                                                                                       				FROM  
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        					LGDAT.GLMT B,  
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              					LGDAT.MAST M,  
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              					TABLE ( VALUES  
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             						(AJ4COMP||DIGITS(AJ4GL#1)||DIGITS(AJ4GL#2), SUBSTR(DIGITS(AJ4CCYY),3,2)||'01', AJ4OB01, AJ4TT01, AJ4OB01+AJ4TT01, AJ4CB01, AJ4FR01),  
						(AJ4COMP||DIGITS(AJ4GL#1)||DIGITS(AJ4GL#2), SUBSTR(DIGITS(AJ4CCYY),3,2)||'02', AJ4OB02, AJ4TT02, AJ4OB02+AJ4TT02, AJ4CB02, AJ4FR02),  
						(AJ4COMP||DIGITS(AJ4GL#1)||DIGITS(AJ4GL#2), SUBSTR(DIGITS(AJ4CCYY),3,2)||'03', AJ4OB03, AJ4TT03, AJ4OB03+AJ4TT03, AJ4CB03, AJ4FR03),  
						(AJ4COMP||DIGITS(AJ4GL#1)||DIGITS(AJ4GL#2), SUBSTR(DIGITS(AJ4CCYY),3,2)||'04', AJ4OB04, AJ4TT04, AJ4OB04+AJ4TT04, AJ4CB04, AJ4FR04),  
						(AJ4COMP||DIGITS(AJ4GL#1)||DIGITS(AJ4GL#2), SUBSTR(DIGITS(AJ4CCYY),3,2)||'05', AJ4OB05, AJ4TT05, AJ4OB05+AJ4TT05, AJ4CB05, AJ4FR05),  
						(AJ4COMP||DIGITS(AJ4GL#1)||DIGITS(AJ4GL#2), SUBSTR(DIGITS(AJ4CCYY),3,2)||'06', AJ4OB06, AJ4TT06, AJ4OB06+AJ4TT06, AJ4CB06, AJ4FR06),  
						(AJ4COMP||DIGITS(AJ4GL#1)||DIGITS(AJ4GL#2), SUBSTR(DIGITS(AJ4CCYY),3,2)||'07', AJ4OB07, AJ4TT07, AJ4OB07+AJ4TT07, AJ4CB07, AJ4FR07),  
						(AJ4COMP||DIGITS(AJ4GL#1)||DIGITS(AJ4GL#2), SUBSTR(DIGITS(AJ4CCYY),3,2)||'08', AJ4OB08, AJ4TT08, AJ4OB08+AJ4TT08, AJ4CB08, AJ4FR08),  
						(AJ4COMP||DIGITS(AJ4GL#1)||DIGITS(AJ4GL#2), SUBSTR(DIGITS(AJ4CCYY),3,2)||'09', AJ4OB09, AJ4TT09, AJ4OB09+AJ4TT09, AJ4CB09, AJ4FR09),  
						(AJ4COMP||DIGITS(AJ4GL#1)||DIGITS(AJ4GL#2), SUBSTR(DIGITS(AJ4CCYY),3,2)||'10', AJ4OB10, AJ4TT10, AJ4OB10+AJ4TT10, AJ4CB10, AJ4FR0A),  
						(AJ4COMP||DIGITS(AJ4GL#1)||DIGITS(AJ4GL#2), SUBSTR(DIGITS(AJ4CCYY),3,2)||'11', AJ4OB11, AJ4TT11, AJ4OB11+AJ4TT11, AJ4CB11, AJ4FR0B),  
						(AJ4COMP||DIGITS(AJ4GL#1)||DIGITS(AJ4GL#2), SUBSTR(DIGITS(AJ4CCYY),3,2)||'12', AJ4OB12, AJ4TT12, AJ4OB12+AJ4TT12, AJ4CB12, AJ4FR0C),  
						(AJ4COMP||DIGITS(AJ4GL#1)||DIGITS(AJ4GL#2), SUBSTR(DIGITS(AJ4CCYY),3,2)||'13', AJ4OB13, AJ4TT13, AJ4OB13+AJ4TT13, AJ4CB13, AJ4FR0D),  
						(AJ4COMP||DIGITS(AJ4GL#1)||DIGITS(AJ4GL#2), SUBSTR(DIGITS(AJ4CCYY),3,2)||'14', AJ4OB14, AJ4TT14, AJ4OB14+AJ4TT14, AJ4CB14, AJ4FR0E),  
						(AJ4COMP||DIGITS(AJ4GL#1)||DIGITS(AJ4GL#2), SUBSTR(DIGITS(AJ4CCYY),3,2)||'15', AJ4OB15, AJ4TT15, AJ4OB15+AJ4TT15, AJ4CB15, AJ4FR0F)  
					) AS P(ACC, PERD, OB, NT, EB, BG, FC)  
				WHERE  
					AJ4CCYY >= 2015 AND 
					AZCOMP = AJ4COMP AND  
					AZGL#1 = AJ4GL#1 AND  
					AZGL#2 = AJ4GL#2 AND  
					(P.OB <> 0 OR P.NT <> 0 OR P.EB <> 0 OR P.BG <> 0 OR P.FC <> 0)  
			) B 
			LEFT OUTER JOIN LGDAT.GGTP ON  
				D35GCDE = AZFUT3  
			LEFT OUTER JOIN LGDAT.NAME N ON  
				SUBSTR(N.A7,7,1) = SUBSTR(LTRIM(D35USR2)||AZGROP,1,1) AND  
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
				X.PERD = B.PERD AND  
				X.FCUR = AZFUT2 AND  
				X.TCUR = 'US' AND  
				X.RTYP = CASE WHEN AZATYP <= 3 THEN 'ME' ELSE 'MA' END  
			LEFT OUTER JOIN RLARP.VW_FFGLPD ON  
				COMP = SUBSTR(ACC,1,2) AND  
				FSPR = B.PERD ; 
  
LABEL ON COLUMN RLARP.V_TBLCS 
( AZTITL IS 'Account Title' , 
	INACTIVE IS 'Account             Status              Code' , 
	GLCC IS 'Future Use          Fut3' , 
	SDAT IS 'Starting            Date ' , 
	EDAT IS 'Ending              Date ' , 
	CURR IS 'Currency            Code' ) ; 
  
LABEL ON COLUMN RLARP.V_TBLCS 
( AZTITL TEXT IS 'Account Title' , 
	INACTIVE TEXT IS 'Account Status Code' , 
	GLCC TEXT IS 'Future Use Fut3' , 
	SDAT TEXT IS 'Starting Date' , 
	EDAT TEXT IS 'Ending Date' , 
	CURR TEXT IS 'Currency Code' ) ; 
  
GRANT ALTER , REFERENCES , SELECT   
ON RLARP.V_TBLCS TO PTROWBRIDG WITH GRANT OPTION ;
