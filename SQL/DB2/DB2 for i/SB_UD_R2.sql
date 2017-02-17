--  Generate SQL 
--  Version:                   	V7R1M0 100423 
--  Generated on:              	10/25/16 11:46:44 
--  Relational Database:       	S7830956 
--  Standards Option:          	DB2 for i 
SET PATH "QSYS","QSYS2","SYSPROC","SYSIBMADM","PTROWBRIDG" ; 
  
CREATE PROCEDURE RLARP.SB_UD_R2 ( 
	IN VPERD VARCHAR(4) ) 
	DYNAMIC RESULT SETS 1 
	LANGUAGE SQL 
	SPECIFIC RLARP.SB_UD_R2 
	NOT DETERMINISTIC 
	MODIFIES SQL DATA 
	CALLED ON NULL INPUT 
	SET OPTION  ALWBLK = *ALLREAD , 
	ALWCPYDTA = *OPTIMIZE , 
	COMMIT = *NONE , 
	DECRESULT = (31, 31, 00) , 
	DFTRDBCOL = *NONE , 
	DYNDFTCOL = *NO , 
	DYNUSRPRF = *USER , 
	SRTSEQ = *HEX   
	BEGIN 
	 
------------------------------------------------------------------------------------------------------------------------------------------------------ 
		DECLARE V_ERROR INTEGER ; 
		DECLARE MSG_VAR VARCHAR ( 255 ) ; 
		DECLARE RETRN_STATUS INTEGER ; 
		DECLARE C1 CURSOR WITH RETURN TO CLIENT FOR SELECT * FROM TABLE ( RLARP . FN_ISB ( VPERD ) ) AS X ; 
		 
		DECLARE EXIT HANDLER FOR SQLEXCEPTION  --,SQLWARNING 
		BEGIN 
			SET V_ERROR = SQLCODE ; 
			GET DIAGNOSTICS RETRN_STATUS = RETURN_STATUS ; 
		 
			IF ( V_ERROR IS NULL ) OR ( V_ERROR <> 0 AND V_ERROR <> 466 ) OR ( RETRN_STATUS > 3 ) 
			THEN 
				SET MSG_VAR = 'PROC: ' || 'RLARP.SB_UD' || ', ' || COALESCE ( MSG_VAR , '' ) || ', SQLCODE: ' || CHAR ( V_ERROR ) || ', PARAMS: ' ; 
				 --ROLLBACK; 
				 --COMMIT; 
				SET RETRN_STATUS = - 1 ; 
				SIGNAL SQLSTATE '75001' SET MESSAGE_TEXT = MSG_VAR ; 
			ELSE 
				SET V_ERROR = 0 ; 
			END IF ; 
		END ; 
		 
	 ------------------------------------------------------------------------------------------------------------------------------------------------------ 
	 ------------------------------------------------------------------------------------------------------------------------------------------------------ 
		DELETE FROM RLARP . FFSBGLR1 WHERE PERD = VPERD ; 
		 
	 ------------------------------------------------------------------------------------------------------------------------------------------------------ 
		DELETE FROM RLARP . FFSBGLWF ; 
  
	 ------------------------------------------------------------------------------------------------------------------------------------------------------ 
		DELETE FROM RLARP . FFSBGLR1_E ; 
  
	 ------------------------------------------------------------------------------------------------------------------------------------------------------ 
	 --																Unkown																				-- 
	 -- some kind of purge entry, not sure of the nature																									-- 
	 ------------------------------------------------------------------------------------------------------------------------------------------------------ 
		INSERT INTO 
			RLARP . FFSBGLWF 
		SELECT 
			DKSRCE || DKQUAL AS MODULE , 
			DIGITS ( DKBTC# ) AS BATCH , 
			DIGITS ( DKFSYY ) || DIGITS ( DKFSPR ) , 
			CHAR ( DKTDAT ) AS TDATE , 
			CHAR ( DKPDAT ) AS PDATE , 
			DIGITS ( DKACC# ) AS ACCT , 
			DKAMT AS AMT , 
			DKPJNM AS PROJ , 
			DKFUT4 AS USRN , 
			DKREV AS REV , 
			UPPER ( LTRIM ( RTRIM ( DKREFD ) ) ) AS CUSMOD , 
			DKKEYN AS CUSKEY1 , 
			'VOUCHER' AS CUSKEY1D , 
			'' AS KEY2 , 
			'' AS KEY2D , 
			'' AS KEY3 , 
			'' AS KEY3D , 
			'' AS KEY4 , 
			'' AS KEY4D , 
			LTRIM ( RTRIM ( SUBSTR ( DKADDD , 7 , 25 ) ) ) AS CUSVEND , 
			'' AS CUSCUST , DIGITS ( DKRCID ) AS RECID 
		FROM 
			LGDAT . GLSBAP 
		WHERE 
			DKSRCE || DKQUAL = 'AP' AND 
			DKFSYR = 20 AND 
			DIGITS ( DKFSYY ) || DIGITS ( DKFSPR ) = VPERD ; 
	/* 
	+---------------------------------------------------------------------------------------------------------------------------------------------------+ 
	|														Unmatched Receipts Accrual																	| 
	|___________________________________________________________________________________________________________________________________________________|				 
	|This is the entry that posts for the unmatched receipts in PORCAP. PORCAP receipts do not trigger any GL activity at creation unless they are 	 	| 
	|inventory related, thus this month-end only entry. Not sure what happens if you post multiple time. This section below leaves as-is given that	 	| 
	|the required information might not exist at time of execution. A later block addresses this.														| 																																				| 
	+---------------------------------------------------------------------------------------------------------------------------------------------------+ 
	*/ 
  
		INSERT INTO 
			RLARP . FFSBGLWF	 
		SELECT 
			DKSRCE || DKQUAL AS MODULE , 
			DIGITS ( DKBTC# ) AS BATCH , 
			DIGITS ( DKFSYY ) || DIGITS ( DKFSPR ) , 
			CHAR ( DKTDAT ) AS TDATE , 
			CHAR ( DKPDAT ) AS PDATE , 
			DIGITS ( DKACC# ) AS ACCT , 
			DKAMT AS AMT , 
			DKPJNM AS PROJ , 
			DKFUT4 AS USRN , 
			DKREV AS REV , 
			UPPER ( DKREFD ) AS CUSMOD , 
			DKKEYN AS CUSKEY1 , 
			'ITEM' AS CUSKEY1D , 
			'' AS KEY2 , 
			'' AS KEY2D , 
			'' AS KEY3 , 
			'' AS KEY3D , 
			'' AS KEY4 , 
			'' AS KEY4D , 
			'' AS CUSVEND , 
			'' AS CUSCUST , DIGITS ( DKRCID ) AS RECID 
		FROM 
			LGDAT . GLSBAP 
		WHERE 
			DKSRCE || DKQUAL = 'APAC' AND 
			DKFSYR = 20 AND 
			DIGITS ( DKFSYY ) || DIGITS ( DKFSPR ) = VPERD ; 
		 
		 
	/* 
	+---------------------------------------------------------------------------------------------------------------------------------------------------+ 
	|																	Check Runs																		| 
	|___________________________________________________________________________________________________________________________________________________|				 
	|Check runs post at the run# level only. In the GL inquirey you can press F3 and get a check list, but these records are not actually on the ledger	| 
	|This is not a sufficient level of detail for reporting purposes but does accurately reflect the value												| 
	|The anchor point here is the ledger itself. Other linked components are:																			| 
	| - CHQR - Check details file																														| 
	| - AVTX - Open AP transaction file																													| 
	| - VCHR - Voucher file																																| 
	| - CHQ  - This is a subquery aggreagting check# totals for gross and discounts taken. There *shouldn't* be duplicates but technically the same		| 
	|		   check number could be issued under different bank codes. Since the anchor table is the ledger, we have no way to join on that field and	| 
	|		   so to eliminate chance of duplication, we must first aggregate the target table to the joining fields level								| 
	| - CHE  - Subquery aggregating gross and discounts taken by run number																				|	   
	+---------------------------------------------------------------------------------------------------------------------------------------------------+ 
	*/ 
  
  
		INSERT INTO 
			RLARP . FFSBGLWF	 
		SELECT 
			DKSRCE || DKQUAL AS MODULE , 
			DIGITS ( DKBTC# ) AS BATCH , 
			DIGITS ( DKFSYY ) || DIGITS ( DKFSPR ) , 
			CHAR ( DKTDAT ) AS TDATE , 
			CHAR ( DKPDAT ) AS PDATE , 
			DIGITS ( DKACC# ) AS ACCT , 
			ROUND ( CASE 
				 --assumption is that there are 3 possible ledger values, gross, discount, or net, all which have ben broked out by check & invoice 
				WHEN ABS ( DKAMT ) = CHR . GROS - CHR . DISC THEN AVTVAM - AVTDIS	 --break out net on ledger 
				WHEN ABS ( DKAMT ) = CHR . GROS THEN AVTVAM					 --break out gross on ledger 
				WHEN ABS ( DKAMT ) = CHR . DISC THEN AVTDIS					 --break out discount on ledger 
				ELSE ABS ( DKAMT ) * ( AVTVAM / CHR . GROS )						 --if not matched to any value apply check level detail prorata 
			END * CASE 
				WHEN DKAMT < 0 THEN - 1 
				ELSE 1 
			END , 2 ) AS AMT , 
			DKPJNM AS PROJ , 
			DKFUT4 AS USRN , 
			DKREV AS REV , 
			'CHECK RUN' AS CUSMOD , 
			DKKEYN AS CUSKEY1 , 
			'CHECK TRANSACTION' AS CUSKEY1D , 
			IGCHQ# AS KEY2 , 
			'CHECK NUMBER' AS CUSKEY2D , 
			AVTVH# AS CUSKEY3 ,											 
			'VOUCHER' AS CUSKEY3D , 
			IDINV# AS CUSKEY4 , 
			'INVOICE' AS CUSKEY4D , 
			IGVEN# AS CUSVEND , 
			'' AS CUSCUST , DKRCID 
		FROM 
			LGDAT . GLSBAP						 --DK (anchor file is AP subledger with limiter on source & fiscal) 
			LEFT OUTER JOIN LGDAT . CHQR ON		 --IG (need check#'s in run for link to AVTX, grab check IGCHQ#, vendor IGVEN#) 
				IGTXR# = DKKEYN AND 
				IGFSYY = DKFSYY AND 
				IGFSPP = DKFSPR 
			LEFT OUTER JOIN LGDAT . AVTX ON		 --AV (need for amount by check, also grab voucher# AVTVH#, gross paid AVTVAM, discount taken AVTDIS) 
				AVTCO# = IGCOM# AND 
				AVTCHQ = IGCHQ# AND 
				AVTCHB = IGBNK# AND AVTTYP IN ( ' 4' , ' 5' ) 
			LEFT OUTER JOIN LGDAT . VCHR ON		 --ID (need for invoice#) 
				IDCOM# = IGCOM# AND 
				IDBNK# = IGBNK# AND 
				IDVCH# = AVTVH# 
			LEFT OUTER JOIN 
			( 
				SELECT 
					IGCOM# AS COMP , IGTXR# AS TXR , IGCHQ# AS CHQN , IGFSYY AS YY , IGFSPP AS PP , SUM ( IGGROS ) AS GROS , SUM ( IGDISC ) AS DISC 
				FROM 
					LGDAT . CHQR 
				WHERE 
					 --inner most select is a unique list of check run numbers direct from GL. does NOT key off of indexed fields but still runs really fast 
					IGTXR# IN ( SELECT DISTINCT DKKEYN FROM LGDAT . GLSBAP WHERE DKSRCE = 'AP' AND DKQUAL = 'CQ' AND DKFSYR = 20 AND DIGITS ( DKFSYY ) || DIGITS ( DKFSPR ) = VPERD ) 
				GROUP BY 
					IGCOM# , IGTXR# , IGCHQ# , IGFSYY , IGFSPP 
			) CHQ ON 
				CHQ . COMP = SUBSTR ( DKACC# , 1 , 2 ) AND 
				CHQ . TXR = DKKEYN AND 
				CHQ . YY = DKFSYY AND 
				CHQ . PP = DKFSPR AND 
				CHQN = IGCHQ# 
			LEFT OUTER JOIN 
			( 
				SELECT 
					IGCOM# AS COMP , IGTXR# AS TXR , IGFSYY AS YY , IGFSPP AS PP , SUM ( IGGROS ) AS GROS , SUM ( IGDISC ) AS DISC 
				FROM 
					LGDAT . CHQR 
				WHERE 
					IGTXR# IN ( SELECT DISTINCT DKKEYN FROM LGDAT . GLSBAP WHERE DKSRCE = 'AP' AND DKQUAL = 'CQ' AND DKFSYR = 20 AND DIGITS ( DKFSYY ) || DIGITS ( DKFSPR ) = VPERD ) 
				GROUP BY 
					IGCOM# , IGTXR# , IGFSYY , IGFSPP 
			) CHR ON 
				CHR . COMP = SUBSTR ( DKACC# , 1 , 2 ) AND 
				CHR . TXR = DKKEYN AND 
				CHR . YY = DKFSYY AND 
				CHR . PP = DKFSPR 
		WHERE 
			DKSRCE = 'AP' AND 
			DKQUAL = 'CQ' AND 
			DKFSYR = 20 AND 
			DIGITS ( DKFSYY ) || DIGITS ( DKFSPR ) = VPERD ; 
	 
	/* 
	+---------------------------------------------------------------------------------------------------------------------------------------------------+ 
	|																	Void Checks																		| 
	|___________________________________________________________________________________________________________________________________________________|				 
	|Voided check transactions APVC post to the anchor file GLSBAP with a hook to the check number whihc is used to go back and embed voucher & invoice	| 
	|The data natively exists with the appropriate level of granularity for reporting and is also accurate												| 
	+---------------------------------------------------------------------------------------------------------------------------------------------------+ 
	*/ 
  
  
		INSERT INTO 
			RLARP . FFSBGLWF 
		SELECT 
			DKSRCE || DKQUAL AS MODULE , 
			DIGITS ( DKBTC# ) AS BATCH , DIGITS ( DKFSYY ) || DIGITS ( DKFSPR ) AS PERD , 
			CHAR ( DKTDAT ) AS TDATE , 
			CHAR ( DKPDAT ) AS PDATE , 
			DIGITS ( DKACC# ) AS ACCT , 
			ROUND ( CASE 
			WHEN ABS ( DKAMT ) < IGGROS THEN ABS ( DKAMT ) / IGGROS 
			ELSE 1 
			END * CASE WHEN DKAMT < 0 THEN - 1 ELSE 1 END * AVTAMT , 2 ) AS AMT , 
			DKPJNM AS PROJ , 
			DKFUT4 AS USRN , 
			DKREV AS REV , 
			UPPER ( LTRIM ( RTRIM ( SUBSTR ( DKREFD , 1 , 9 ) ) ) ) AS CUSMOD , 
			IGTXR# AS CUSKEY1 , 
			'CHECK TRANSACTION' AS CUSKEY1D , 
			IGCHQ# AS KEY2 , 
			'CHECK NUMBER' AS CUSKEY2D , 
			DIGITS ( AVTVH# ) AS CUSKEY3 , 
			'VOUCHER' AS CUSKEY3D , 
			IDINV# AS CUSKEY4 , 
			'INVOICE' AS CUSKEY4D , 
			IGVEN# AS CUSVEND , 
			'' AS CUSCUST , DIGITS ( DKRCID ) AS RECID 
		FROM 
			LGDAT . GLSBAP 
			LEFT OUTER JOIN LGDAT . AVTX ON 
				AVTCO# = SUBSTR ( DKACC# , 1 , 2 ) AND 
				AVTCHQ = DKKEYN AND 
				AVTTYP = 7 AND 
				AVTFIS = DKFSYR || DKFSYY || DIGITS ( DKFSPR ) 
			LEFT OUTER JOIN LGDAT . CHQR ON 
				IGCOM# = AVTCO# AND 
				IGBNK# = AVTCHB AND 
				IGCHQ# = AVTCHQ 
			LEFT OUTER JOIN LGDAT . VCHR ON 
				IDCOM# = IGCOM# AND 
				IDBNK# = IGBNK# AND 
				IDVCH# = AVTVH# 
			WHERE 
				DKSRCE || DKQUAL = 'APVC' AND 
				DKFSYR = 20 AND 
				DIGITS ( DKFSYY ) || DIGITS ( DKFSPR ) = VPERD ; 
  
	/* 
	+---------------------------------------------------------------------------------------------------------------------------------------------------+ 
	|																	Voucher Posting																	| 
	|___________________________________________________________________________________________________________________________________________________|				 
	|Voucher postings are transacted without reference to the 3-way match data																			| 
	|this module currently only gets half way there because of complications around manually changing the accounts or amounts involved in the voucher	| 
	|The PO & description are linked in, but ideally we would have the master receipt key which is the common thread for reporting						| 
	+---------------------------------------------------------------------------------------------------------------------------------------------------+ 
	*/ 
	 -----need to look at a new approach where the POMVAR linkage is setup if matching was used, otherwise default to this logic 
	INSERT INTO	 
		RLARP . FFSBGLWF 
	SELECT 
		MODULE , BATCH , PERD , TDATE , PDATE , ACCT , 
		SUM ( AMT ) AMT , 
		PROJ , USRN , REV , CUSMOD , CUSKEY1 , CUSKEY1D , CUSKEY2 , CUSKEY2D , CUSKEY3 , CUSKEY3D , CUSKEY4 , CUSKEY4D , CUSVEND , CUSCUST , RECID 
	FROM 
		( 
		SELECT 
			DKSRCE || DKQUAL AS MODULE , 
			DIGITS ( DKBTC# ) AS BATCH , 
			DIGITS ( DKFSYY ) || DIGITS ( DKFSPR ) PERD , 
			CHAR ( DKTDAT ) AS TDATE , 
			CHAR ( DKPDAT ) AS PDATE , 
			DIGITS ( DKACC# ) AS ACCT , 
			CASE WHEN PPV_DET IS NULL 
				THEN DKAMT 
				ELSE ROUND ( DKAMT * PPV_DET , 2 ) 
			END AMT , 
			DKPJNM AS PROJ , 
			DKFUT4 AS USRN , 
			DKREV AS REV , 
			'VOUCHER POSTING' CUSMOD , 
			DKKEYN AS CUSKEY1 , 
			'VOUCHER NUMBER' AS CUSKEY1D , 
			IDINV# AS CUSKEY2 , 
			'INVOICE' AS CUSKEY2D , 
			CASE WHEN PPV_DET IS NULL THEN IDVDES ELSE DIGITS ( LBRKEY ) END AS CUSKEY3 , 
			CASE WHEN PPV_DET IS NULL THEN 'DESCR' ELSE 'RKEY' END AS CUSKEY3D , 
			LBPT# AS CUSKEY4 , 
			CASE WHEN COALESCE ( LBPT# , '' ) = '' THEN '' ELSE 'PART' END AS CUSKEY4D , 
			IDVEN# AS CUSVEND , 
			'' AS CUSCUST , 
			DIGITS ( DKRCID ) AS RECID 
		FROM 
			LGDAT . GLSBAP 
			LEFT OUTER JOIN LGDAT . VCHR ON 
				IDCOM# = SUBSTR ( DKACC# , 1 , 2 ) AND 
				IDVCH# = DKKEYN AND 
				IDFISY = DKFSYY AND 
				IDFISP = DKFSPR 
				 --an assumption is that given a fiscal period all voucher numbers are different, however this could be violated due to bank codes 
				 --not being differentiated on the ledger and the account code may not reflect the bank code granularity and there is no history 
				 --file on the bank master data so it doesn't matter anyways 
			LEFT OUTER JOIN 
			( 
				SELECT 
					X . COMP COMP , X . VCHR VCHR , X . ACCT ACCT , X . PPV PPV , X . CNT CNT , X . TOT TOT , LBRKEY , LBPT# , LBEXT , LBCOM# || Y1PRVR PPVACCT , LBPPV , 
					CASE X . PPV 
						WHEN 0 THEN 
							CASE X . TOT 
								WHEN 0 THEN FLOAT ( 1 ) / FLOAT ( X . CNT ) 
								ELSE LBEXT / X . TOT 
							END 
						ELSE LBPPV / X . PPV 
					END PPV_DET 
				FROM	 
					LGDAT . POMVAR 
					LEFT OUTER JOIN LGDAT . STKMM ON 
						AVPART = LBPT# 
					LEFT OUTER JOIN LGDAT . STKMP ON 
						AWPART = LBPT# 
					LEFT OUTER JOIN LGDAT . GLIE ON 
						Y1PLNT = LBPLNT AND 
						Y1GLEC = COALESCE ( AVGLED , AWGLED ) 
					LEFT OUTER JOIN LGDAT . POI ON 
						KBPO# = LBPO# AND 
						KBITM# = LBPOI# 
					LEFT OUTER JOIN 
					( 
						SELECT 
							LBCOM# COMP , LBVCH# VCHR , 
							LBCOM# || COALESCE ( Y1PRVR , KBGL# ) ACCT ,  --if the ppv account is null, then use the expense account from the PO 
							SUM ( LBPPV ) PPV , COUNT ( LBRKEY ) CNT , SUM ( LBEXT ) TOT 
						FROM	 
							LGDAT . POMVAR 
							LEFT OUTER JOIN LGDAT . STKMM ON 
								AVPART = LBPT# 
							LEFT OUTER JOIN LGDAT . STKMP ON 
								AWPART = LBPT# 
							LEFT OUTER JOIN LGDAT . GLIE ON 
								Y1PLNT = LBPLNT AND 
								Y1GLEC = COALESCE ( AVGLED , AWGLED ) 
							LEFT OUTER JOIN LGDAT . POI ON 
								KBPO# = LBPO# AND 
								KBITM# = LBPOI# 
								 
						WHERE 
							DIGITS ( LBFSYY ) || DIGITS ( LBFSPP ) = VPERD 
							 --may need to consider excluding .00001 cost items 
						GROUP BY 
							LBCOM# , LBVCH# , LBCOM# || COALESCE ( Y1PRVR , KBGL# ) 
					) X ON 
						X . COMP = LBCOM# AND	 
						X . VCHR = LBVCH# AND 
						X . ACCT = LBCOM# || COALESCE ( Y1PRVR , KBGL# ) 
				WHERE 
					DIGITS ( LBFSYY ) || DIGITS ( LBFSPP ) = VPERD 
			) SPLIT ON	 
				SPLIT . COMP = SUBSTR ( DKACC# , 1 , 2 ) AND	 
				SPLIT . VCHR = DKKEYN AND 
				SPLIT . ACCT = DKACC# 
		WHERE 
			DKSRCE = 'AP' AND 
			DKQUAL = 'VN' AND 
			DKFSYR = 20 AND 
			DIGITS ( DKFSYY ) || DIGITS ( DKFSPR ) = VPERD 
		) AGG 
	GROUP BY 
		MODULE , BATCH , PERD , TDATE , PDATE , ACCT , 
		PROJ , USRN , REV , CUSMOD , CUSKEY1 , CUSKEY1D , CUSKEY2 , CUSKEY2D , CUSKEY3 , CUSKEY3D , CUSKEY4 , CUSKEY4D , CUSVEND , CUSCUST , RECID ; 
		 
	 ------------------------------------------------------------------------------------------------------------------------------------------------------	 
		INSERT INTO 
			RLARP . FFSBGLWF 
		SELECT 
			BL8SRCE || BL8QUAL , 
			DIGITS ( BL8BTC# ) , 
			BL8FSYY || DIGITS ( BL8FSPR ) , 
			CHAR ( BL8TRDAT ) , 
			CHAR ( BL8PDAT ) , 
			BL8ACC# , 
			BL8AMT , 
			BL8PJNB , 
			BL8USER , 
			BL8REV , 
			CASE DKQUAL 
				WHEN '' THEN UPPER ( LTRIM ( RTRIM ( SUBSTR ( BL8REFD , 1 , 14 ) ) ) ) 
				WHEN 'IN' THEN 'CREDIT MEMO' 
				WHEN 'RC' THEN UPPER ( LTRIM ( RTRIM ( SUBSTR ( BL8REFD , 1 , 14 ) ) ) ) 
				ELSE 'NOT MAPPED' 
			END CUSMOD , 
			CASE DKQUAL 
				WHEN '' THEN BL8REFB 
				WHEN 'IN' THEN CASE SUBSTR ( BL8KEYN , 1 , 1 ) WHEN 'D' THEN SUBSTR ( BL8KEYN , 2 , 5 ) ELSE BL8KEYN END 
				WHEN 'RC' THEN 
				CASE UPPER ( LTRIM ( RTRIM ( SUBSTR ( BL8REFD , 1 , 14 ) ) ) ) 
					WHEN 'ADJUSTMENT' THEN CASE SUBSTR ( BL8KEYN , 1 , 1 ) WHEN 'D' THEN SUBSTR ( BL8KEYN , 2 , 5 ) ELSE BL8KEYN END 
					WHEN 'CASH RECEIPINV' THEN CASE SUBSTR ( BL8REFD , 16 , 1 ) WHEN 'D' THEN SUBSTR ( BL8REFD , 17 , 5 ) ELSE SUBSTR ( BL8REFD , 16 , 6 ) END 
					WHEN 'DISCOUNT' THEN CASE SUBSTR ( BL8KEYN , 1 , 1 ) WHEN 'D' THEN SUBSTR ( BL8KEYN , 2 , 5 ) ELSE BL8KEYN END 
					WHEN 'MISC CASH ENTR' THEN BL8ADDD 
					ELSE '' 
				END 
				ELSE 'NOT MAPPED' 
			END CUSKEY1 , 
			CASE DKQUAL 
				WHEN '' THEN 'DESCR1' 
				WHEN 'IN' THEN CASE SUBSTR ( BL8KEYN , 1 , 1 ) WHEN 'D' THEN 'DEBIT NOTE-CCRH' ELSE 'INVOICE-OIH' END 
				WHEN 'RC' THEN 
				CASE UPPER ( LTRIM ( RTRIM ( SUBSTR ( BL8REFD , 1 , 14 ) ) ) ) 
					WHEN 'ADJUSTMENT' THEN CASE SUBSTR ( BL8KEYN , 1 , 1 ) WHEN 'D' THEN 'DEBIT MEMO-X' ELSE 'INVOICE-OIH' END 
					WHEN 'CASH RECEIPINV' THEN CASE SUBSTR ( BL8REFD , 16 , 1 ) WHEN 'D' THEN 'DEBIT MEMO-X' ELSE 'INVOICE-OIH' END 
					WHEN 'DISCOUNT' THEN CASE SUBSTR ( BL8KEYN , 1 , 1 ) WHEN 'D' THEN 'DEBIT MEMO-X' ELSE 'INVOICE-OIH' END 
					WHEN 'MISC CASH ENTR' THEN 'DESCRIPTION-X' 
					ELSE '' 
				END 
				ELSE 'NOT MAPPED' 
			END CUSKEY1D , 
			CASE DKQUAL 
				WHEN '' THEN BL8ADDD 
				WHEN 'IN' THEN BL8REF 
				WHEN 'RC' THEN 
				CASE UPPER ( LTRIM ( RTRIM ( SUBSTR ( BL8REFD , 1 , 14 ) ) ) ) 
					WHEN 'CASH RECEIPINV' THEN BL8KEYN 
					WHEN 'CASH RECEIPT' THEN BL8KEYN 
					ELSE '' 
				END 
				ELSE 'NOT MAPPED' 
			END CUSKEY2 , 
			CASE DKQUAL 
				WHEN '' THEN 'DESCR2' 
				WHEN 'IN' THEN 'OFFSET&DESCR' 
				WHEN 'RC' THEN 
				CASE UPPER ( LTRIM ( RTRIM ( SUBSTR ( BL8REFD , 1 , 14 ) ) ) ) 
					WHEN 'CASH RECEIPINV' THEN 'CHEQUE-ARTRN' 
					WHEN 'CASH RECEIPT' THEN 'CHEQUE-ARTRN' 
					ELSE '' 
				END 
				ELSE 'NOT MAPPED' 
			END CUSKEY2D , 
			DIGITS ( BL8BTCH ) AS CUSKEY3 , 
			'AR BATCH' AS CUSKEY3D , 
			'' AS CUSKEY4 , 
			'' AS CUSKEY4D , 
			'' AS CUSVEND , 
			BL8CUST , '0' RECID 
		FROM 
			LGDAT . AROPT 
			INNER JOIN ( SELECT DISTINCT DKACC# , DKFSYY , DKFSPR , DKSRCE , DKQUAL FROM LGDAT . GLSBAR WHERE DIGITS ( DKFSYY ) || DIGITS ( DKFSPR ) = VPERD AND DKSRCE = 'AR' ) X ON 
				DKACC# = BL8ACC# AND 
				BL8SRCE = DKSRCE AND 
				BL8QUAL = DKQUAL AND 
				BL8FSYY = DKFSYY AND 
				BL8FSPR = DKFSPR ; 
		 
	 ------------------------------------------------------------------------------------------------------------------------------------------------------ 
		INSERT INTO 
			RLARP . FFSBGLWF 
		SELECT 
			DKSRCE || DKQUAL , 
			DIGITS ( DKBTC# ) , 
			DKFSYY || DIGITS ( DKFSPR ) , 
			CHAR ( DKTDAT ) , 
			CHAR ( DKPDAT ) , 
			DKACC# , 
			DKAMT , 
			DKPJNM , 
			DKFUT4 , 
			DKREV , 
			UPPER ( RTRIM ( SUBSTR ( DKREFD , 1 , 15 ) ) ) CUSMOD , 
			DKKEYN AS CUSKEY1 , 
			'ITEM' AS CUSKEY1D , 
			DKADDD AS CUSKEY2 , 
			'DESCR' AS CUSKEY2D , 
			'' AS CUSKEY3 , 
			'' AS CUSKEY3D , 
			'' AS CUSKEY4 , 
			'' AS CUSKEY4D , 
			'' AS CUSVEND , 
			'' , DKRCID RECID 
		FROM 
			LGDAT . GLSBAR 
		WHERE 
			DIGITS ( DKFSYY ) || DIGITS ( DKFSPR ) = VPERD AND 
			DKSRCE = 'AR' AND 
			DKQUAL = 'RC' AND 
			DKREFD = 'MISC CASH ENTRY' ; 
		 
	 ------------------------------------------------------------------------------------------------------------------------------------------------------ 
		INSERT INTO 
			RLARP . FFSBGLWF	 
		SELECT 
			DKSRCE || DKQUAL , 
			DIGITS ( DKBTC# ) , DIGITS ( DKFSYY ) || DIGITS ( DKFSPR ) AS PERD , 
			CHAR ( DKTDAT ) , 
			CHAR ( DKPDAT ) , 
			DIGITS ( DKACC# ) , 
			DKAMT , 
			DKPJNM , 
			DKFUT4 , 
			DKREV , 
			LTRIM ( RTRIM ( UPPER ( SUBSTR ( DKADDD , 1 , 4 ) ) ) ) AS CUSMOD , 
			DKPART AS CUSKEY1 , 
			'PART' AS CUSKEY1D , 
			LTRIM ( RTRIM ( SUBSTR ( DKADDD , 13 , 14 ) ) ) AS CUSKEY2 , 
			'QTY' AS CUSKEY2D , 
			LTRIM ( RTRIM ( SUBSTR ( DKADDD , 28 , 2 ) ) ) AS CUSKEY3 , 
			'UOM' AS CUSKEY3D , 
			'' AS CUSKEY4 , 
			'' AS CUSKEY4D , 
			'' AS CUSVEND , 
			'' AS CUSCUST , DIGITS ( DKRCID ) AS RECID 
		FROM 
			LGDAT . GLSBIV GLSBIV 
		WHERE 
			DKFSYR = 20 AND 
			DIGITS ( DKFSYY ) || DIGITS ( DKFSPR ) = VPERD AND 
			DKSRCE = 'IC' AND 
			DKQUAL = '' ; 
  
	 ------------------------------------------------------------------------------------------------------------------------------------------------------ 
		INSERT INTO 
			RLARP . FFSBGLWF 
		SELECT 
			DKSRCE || DKQUAL , 
			DIGITS ( DKBTC# ) , DIGITS ( DKFSYY ) || DIGITS ( DKFSPR ) AS PERD , 
			CHAR ( DKTDAT ) , 
			CHAR ( DKPDAT ) , 
			DIGITS ( DKACC# ) , 
			DKAMT , 
			DKPJNM , 
			DKFUT4 , 
			DKREV , 
			LTRIM ( RTRIM ( UPPER ( SUBSTR ( DKADDD , 1 , 14 ) ) ) ) AS CUSMOD , 
			DKKEYN AS CUSKEY1 , 
			'INVOICE' AS CUSKEY1D , 
			DKFUT9 AS CUSKEY2 , 
			'INVOICE LINE' AS CUSKEY2D , 
			DHPLNT AS CUSKEY3 , 
			'SHIP PLNT' AS CUSKEY3D , 
			'' AS CUSKEY4 , 
			'' AS CUSKEY4D , 
			'' AS CUSVEND , 
			DHBCS# AS CUSCUST , DIGITS ( DKRCID ) AS RECID 
		FROM 
			LGDAT . GLSBIV GLSBIV 
			LEFT OUTER JOIN LGDAT . OIH ON 
				DHINV# = DKKEYN 
		WHERE 
			DKFSYR = 20 AND 
			DIGITS ( DKFSYY ) || DIGITS ( DKFSPR ) = VPERD AND 
			DKSRCE = 'IC' AND 
			DKQUAL = 'IN' ; 
		 
	 ------------------------------------------------------------------------------------------------------------------------------------------------------ 
		INSERT INTO 
			RLARP . FFSBGLWF 
		SELECT 
			DKSRCE || DKQUAL , 
			DIGITS ( DKBTC# ) , DIGITS ( DKFSYY ) || DIGITS ( DKFSPR ) AS PERD , 
			CHAR ( DKTDAT ) , 
			CHAR ( DKPDAT ) , 
			DIGITS ( DKACC# ) , 
			DKAMT , 
			DKPJNM , 
			DKFUT4 , 
			DKREV , 
			LTRIM ( RTRIM ( UPPER ( SUBSTR ( DKADDD , 1 , 4 ) ) ) ) AS CUSMOD , 
			DKKEYN AS CUSKEY1 , 
			'BYTRAN' AS CUSKEY1D , 
			BYREAS AS CUSKEY2 , 
			'REASON' AS CUSKEY2D , 
			BYDREF AS CUSKEY3 , 
			'DESCR' AS CUSKEY3D , 
			BYPART AS CUSKEY4 , 
			'PART' AS CUSKEY4D , 
			'' AS CUSVEND , 
			'' AS CUSCUST , DIGITS ( DKRCID ) AS RECID 
		FROM 
			LGDAT . GLSBIV GLSBIV 
			LEFT OUTER JOIN LGDAT . STKT ON 
				BYTRAN = INT ( DKKEYN ) 
		WHERE 
			DKFSYR = 20 AND 
			DIGITS ( DKFSYY ) || DIGITS ( DKFSPR ) = VPERD AND 
			DKSRCE = 'IC' AND 
			DKQUAL = 'IT' ; 
		 
	 ------------------------------------------------------------------------------------------------------------------------------------------------------ 
		INSERT INTO 
			RLARP . FFSBGLWF 
		SELECT 
			DKSRCE || DKQUAL , 
			DIGITS ( DKBTC# ) , DIGITS ( DKFSYY ) || DIGITS ( DKFSPR ) AS PERD , 
			CHAR ( DKTDAT ) , 
			CHAR ( DKPDAT ) , 
			DIGITS ( DKACC# ) , 
			DKAMT , 
			DKPJNM , 
			DKFUT4 , 
			DKREV , 
			'GOODS RECEIPT' AS CUSMOD , 
			DKKEYN AS CUSKEY1 , 
			'REC LOG' AS CUSKEY1D , 
			DKPART AS CUSKEY2 , 
			'PART' AS CUSTKEY2D , 
			'' AS CUSKEY3 , 
			'' AS CUSKEY3D , 
			'' AS CUSKEY4 , 
			'' AS CUSKEY4D , 
			'' AS CUSVEND , 
			'' AS CUSCUST , DIGITS ( DKRCID ) AS RECID 
		FROM 
			LGDAT . GLSBIV GLSBIV 
		WHERE 
			DKFSYR = 20 AND 
			DIGITS ( DKFSYY ) || DIGITS ( DKFSPR ) = VPERD	AND 
			DKSRCE = 'IC' AND 
			DKQUAL = 'RL' ; 
		 
	 ------------------------------------------------------------------------------------------------------------------------------------------------------ 
		INSERT INTO 
			RLARP . FFSBGLWF 
		SELECT 
			DKSRCE || DKQUAL AS MODULE , 
			DIGITS ( DKBTC# ) AS BATCH , 
			DIGITS ( DKFSYY ) || DIGITS ( DKFSPR ) , 
			CHAR ( DKTDAT ) AS TDATE , 
			CHAR ( DKPDAT ) AS PDATE , 
			DIGITS ( DKACC# ) AS ACCT , 
			DKAMT AS AMT , 
			DKPJNM AS PROJ , 
			DKFUT4 AS USRN , 
			DKREV AS REV , 
			SUBSTR ( DKADDD , 1 , 12 ) , DKKEYN , 
			'RAN DOC NUM AND ITM' , 
			INRAN# , 
			'RAN' , 
			INCRD# || ' - ' || INITM# , 
			'CREDIT AND ITEM' , 
			DIINV# , 
			'CREDIT INVOICE' , 
			'' , 
			INCUST , 
			DKRCID 
		FROM 
			LGDAT . GLSBIV 
			LEFT OUTER JOIN LGDAT . RANS ON 
				INRNDR = SUBSTR ( DKKEYN , 1 , LOCATE ( '/' , DKKEYN ) - 1 ) AND 
				INRNDI = SUBSTR ( DKKEYN , LOCATE ( '/' , DKKEYN ) + 1 , 1 ) 
			LEFT OUTER JOIN LGDAT . OID ON 
				DIORD# = INCRD# AND 
				DIITM# = INITM# AND 
				DIGITS ( INCRD# ) <> '000000000' 
		WHERE 
			DKFSYR = 20 AND 
			DIGITS ( DKFSYY ) || DIGITS ( DKFSPR ) = VPERD AND 
			DKSRCE = 'IC' AND 
			DKQUAL = 'RT' ; 
		 
	 ------------------------------------------------------------------------------------------------------------------------------------------------------ 
		INSERT INTO 
			RLARP . FFSBGLWF 
		SELECT 
			DKSRCE || DKQUAL , 
			DIGITS ( DKBTC# ) , DIGITS ( DKFSYY ) || DIGITS ( DKFSPR ) AS PERD , 
			CHAR ( DKTDAT ) , 
			CHAR ( DKPDAT ) , 
			DIGITS ( DKACC# ) , 
			DKAMT , 
			DKPJNM , 
			DKFUT4 , 
			DKREV , 
			'GOODS RECEIPT' AS CUSMOD , 
			DKKEYN AS CUSKEY1 , 
			'RETURN TO VENDOR' AS CUSKEY1D , 
			DKPART AS CUSKEY2 , 
			'PART' AS CUSKEY2D , 
			'' AS CUSKEY3 , 
			'' AS CUSKEY3D , 
			'' AS CUSKEY4 , 
			'' AS CUSKEY4D , 
			'' AS CUSVEND , 
			'' AS CUSCUST , DIGITS ( DKRCID ) AS RECID 
		FROM 
			LGDAT . GLSBIV GLSBIV 
		WHERE 
			DKFSYR = 20 AND 
			DIGITS ( DKFSYY ) || DIGITS ( DKFSPR ) = VPERD AND 
			DKSRCE = 'IC' AND 
			DKQUAL = 'VR' ; 
		 
	 ------------------------------------------------------------------------------------------------------------------------------------------------------ 
		INSERT INTO 
			RLARP . FFSBGLWF 
		SELECT 
			DKSRCE || DKQUAL , 
			DIGITS ( DKBTC# ) , DIGITS ( DKFSYY ) || DIGITS ( DKFSPR ) AS PERD , 
			CHAR ( DKTDAT ) , 
			CHAR ( DKPDAT ) , 
			DIGITS ( DKACC# ) , 
			DKAMT , 
			DKPJNM , 
			DKFUT4 , 
			DKREV , 
			UPPER ( LTRIM ( RTRIM ( SUBSTR ( DKREFD , 1 , 14 ) ) ) ) AS CUSMOD , 
			DKKEYN AS CUSKEY1 , 
			'INVOICE' AS CUSKEY1D , 
			DKFUT9 AS CUSKEY2 , 
			'INVOICE LINE' AS CUSKEY2D , 
			DHPLNT AS CUSKEY3 , 
			'INVOICE PLANT' AS CUSKEY3D , 
			DHINCR AS CUSKEY4 , 
			'INC/CRD' AS CUSKEY4D , 
			'' AS CUSVEND , 
			DHBCS# AS CUSCUST , DIGITS ( DKRCID ) AS RECID 
		FROM 
			LGDAT . GLSBAR GLSBAR 
			LEFT OUTER JOIN LGDAT . OIH ON 
				DHINV# = DKKEYN 
		WHERE 
			GLSBAR . DKFSYR = 20 AND 
			DIGITS ( DKFSYY ) || DIGITS ( DKFSPR ) = VPERD AND 
			DKSRCE = 'OE' AND 
			DKQUAL = 'IN' ; 
		 
	 ------------------------------------------------------------------------------------------------------------------------------------------------------ 
		INSERT INTO 
			RLARP . FFSBGLWF 
		SELECT 
			DKSRCE || DKQUAL , 
			DIGITS ( DKBTC# ) , 
			DIGITS ( DKFSYY ) || DIGITS ( DKFSPR ) AS PERD , 
			CHAR ( DKTDAT ) , 
			CHAR ( DKPDAT ) , 
			DIGITS ( DKACC# ) , 
			SUM ( DKAMT ) , 
			DKPJNM , 
			DKFUT4 , 
			DKREV , 
			'PRODUCTION REPORTING' AS CUSMOD , 
			'' AS CUSKEY1 , 
			'' AS CUSKEY1D , 
			'' AS CUSKEY2 , 
			'' AS CUSKEY2D , 
			UPPER ( CASE WHEN SUBSTR ( DKREFD , 1 , 7 ) IN ( 'COMPLET' , 'CP- PO#' , 'WIP ADJ' , 'VOID CO' , 'REV WIP' ) THEN SUBSTR ( DKREFD , 1 , 7 ) ELSE SUBSTR ( DKADDD , 1 , 24 ) END ) AS CUSKEY3 , 
			'ACTION' AS CUSKEY3D , 
			'' AS CUSKEY4 , 
			'' AS CUSKEY4D , 
			'' AS CUSVEND , 
			'' AS CUSCUST , '0' AS DKRCID 
		FROM 
			LGDAT . GTRAN GLSBIV 
		WHERE 
			DKFSYR = 20 AND 
			DIGITS ( DKFSYY ) || DIGITS ( DKFSPR ) = VPERD AND 
			DKSRCE = 'PD' 
		GROUP BY 
			DKSRCE || DKQUAL , 
			DIGITS ( DKBTC# ) , 
			DIGITS ( DKFSYY ) || DIGITS ( DKFSPR ) , 
			CHAR ( DKTDAT ) , 
			CHAR ( DKPDAT ) , 
			DIGITS ( DKACC# ) , 
			DKPJNM , 
			DKFUT4 , 
			DKREV , 
			UPPER ( CASE WHEN SUBSTR ( DKREFD , 1 , 7 ) IN ( 'COMPLET' , 'CP- PO#' , 'WIP ADJ' , 'VOID CO' , 'REV WIP' ) THEN SUBSTR ( DKREFD , 1 , 7 ) ELSE SUBSTR ( DKADDD , 1 , 24 ) END ) ; 
			 
	 ------------------------------------------------------------------------------------------------------------------------------------------------------ 
		INSERT INTO 
			RLARP . FFSBGLWF 
		SELECT 
			DKSRCE || DKQUAL , 
			DIGITS ( DKBTC# ) , 
			DIGITS ( DKFSYY ) || DIGITS ( DKFSPR ) AS PERD , 
			CHAR ( DKTDAT ) , 
			CHAR ( DKPDAT ) , 
			DIGITS ( DKACC# ) , 
			SUM ( DKAMT ) , 
			DKPJNM , 
			DKFUT4 , 
			DKREV , 
			'PRODUCTION REPORTING' AS CUSMOD , 
			'' AS CUSKEY1 , 
			'' AS CUSKEY1D , 
			'' AS CUSKEY2 , 
			'' AS CUSKEY2D , 
			UPPER ( CASE WHEN SUBSTR ( DKREFD , 1 , 7 ) IN ( 'COMPLET' , 'CP- PO#' , 'WIP ADJ' , 'VOID CO' , 'REV WIP' ) THEN SUBSTR ( DKREFD , 1 , 7 ) ELSE SUBSTR ( DKADDD , 1 , 24 ) END ) AS CUSKEY3 , 
			'ACTION' AS CUSKEY3D , 
			'' AS CUSKEY4 , 
			'' AS CUSKEY4D , 
			'' AS CUSVEND , 
			'' AS CUSCUST , '0' AS DKRCID 
		FROM 
			LGDAT . GTLYN GLSBIV 
		WHERE 
			DKFSYR = 20 AND 
			DIGITS ( DKFSYY ) || DIGITS ( DKFSPR ) = VPERD AND 
			DKSRCE = 'PD' 
		GROUP BY 
			DKSRCE || DKQUAL , 
			DIGITS ( DKBTC# ) , 
			DIGITS ( DKFSYY ) || DIGITS ( DKFSPR ) , 
			CHAR ( DKTDAT ) , 
			CHAR ( DKPDAT ) , 
			DIGITS ( DKACC# ) , 
			DKPJNM , 
			DKFUT4 , 
			DKREV , 
			UPPER ( CASE WHEN SUBSTR ( DKREFD , 1 , 7 ) IN ( 'COMPLET' , 'CP- PO#' , 'WIP ADJ' , 'VOID CO' , 'REV WIP' ) THEN SUBSTR ( DKREFD , 1 , 7 ) ELSE SUBSTR ( DKADDD , 1 , 24 ) END ) ; 
			 
	 ------------------------------------------------------------------------------------------------------------------------------------------------------ 
		INSERT INTO 
			RLARP . FFSBGLWF 
		SELECT 
			DKSRCE || DKQUAL , 
			DIGITS ( DKBTC# ) , 
			DIGITS ( DKFSYY ) || DIGITS ( DKFSPR ) AS PERD , 
			CHAR ( DKTDAT ) , 
			CHAR ( DKPDAT ) , 
			DIGITS ( DKACC# ) , 
			SUM ( DKAMT ) , 
			DKPJNM , 
			DKFUT4 , 
			DKREV , 
			'PRODUCTION REPORTING' AS CUSMOD , 
			'' AS CUSKEY1 , 
			'' AS CUSKEY1D , 
			'' AS CUSKEY2 , 
			'' AS CUSKEY2D , 
			UPPER ( CASE WHEN SUBSTR ( DKREFD , 1 , 7 ) IN ( 'COMPLET' , 'CP- PO#' , 'WIP ADJ' , 'VOID CO' , 'REV WIP' ) THEN SUBSTR ( DKREFD , 1 , 7 ) ELSE SUBSTR ( DKADDD , 1 , 24 ) END ) AS CUSKEY3 , 
			'ACTION' AS CUSKEY3D , 
			'' AS CUSKEY4 , 
			'' AS CUSKEY4D , 
			'' AS CUSVEND , 
			'' AS CUSCUST , '0' AS DKRCID 
		FROM 
			LGDAT . GNYTR GLSBIV 
		WHERE 
			DKFSYR = 20 AND 
			DIGITS ( DKFSYY ) || DIGITS ( DKFSPR ) = VPERD AND 
			DKSRCE = 'PD' 
		GROUP BY 
			DKSRCE || DKQUAL , 
			DIGITS ( DKBTC# ) , 
			DIGITS ( DKFSYY ) || DIGITS ( DKFSPR ) , 
			CHAR ( DKTDAT ) , 
			CHAR ( DKPDAT ) , 
			DIGITS ( DKACC# ) , 
			DKPJNM , 
			DKFUT4 , 
			DKREV , 
			UPPER ( CASE WHEN SUBSTR ( DKREFD , 1 , 7 ) IN ( 'COMPLET' , 'CP- PO#' , 'WIP ADJ' , 'VOID CO' , 'REV WIP' ) THEN SUBSTR ( DKREFD , 1 , 7 ) ELSE SUBSTR ( DKADDD , 1 , 24 ) END ) ; 
		 
	 ------------------------------------------------------------------------------------------------------------------------------------------------------ 
		INSERT INTO 
			RLARP . FFSBGLWF 
		SELECT 
			DKSRCE || DKQUAL , 
			DIGITS ( DKBTC# ) , DIGITS ( DKFSYY ) || DIGITS ( DKFSPR ) AS PERD , 
			CHAR ( DKTDAT ) , 
			CHAR ( DKPDAT ) , 
			DIGITS ( DKACC# ) , 
			DKAMT , 
			DKPJNM , 
			DKFUT4 , 
			DKREV , 
			'JOURNAL ENTRY' AS CUSMOD , 
			DKADDD AS CUSKEY1 , 
			'BATCH DESCR' AS CUSKEY1D , 
			DKREFD AS CUSKEY2 , 
			'LINE DESCR' AS CUSKEY2D , 
			DKKEYN AS CUSKEY3 , 
			'BATCH' AS CUSKEY3D , 
			DKREF# AS CUSKEY4 , 
			'JOUNAL' AS CUSKEY4D , 
			'' AS CUSVEND , 
			DKBCUS AS CUSCUST , DIGITS ( DKRCID ) AS RECID 
		FROM 
			LGDAT . GTRAN GTRAN 
		WHERE 
			DKFSYR = 20 AND 
			DIGITS ( DKFSYY ) || DIGITS ( DKFSPR ) = VPERD AND 
			DKSRCE IN ( 'GJ' , 'RJ' , 'OS' , 'AU' ) 
  
		UNION ALL 
  
		SELECT 
			DKSRCE || DKQUAL , 
			DIGITS ( DKBTC# ) , DIGITS ( DKFSYY ) || DIGITS ( DKFSPR ) AS PERD , 
			CHAR ( DKTDAT ) , 
			CHAR ( DKPDAT ) , 
			DIGITS ( DKACC# ) , 
			DKAMT , 
			DKPJNM , 
			DKFUT4 , 
			DKREV , 
			'JOURNAL ENTRY' AS CUSMOD , 
			DKADDD AS CUSKEY1 , 
			'BATCH DESCR' AS CUSKEY1D , 
			DKREFD AS CUSKEY2 , 
			'LINE DESCR' AS CUSKEY2D , 
			DKKEYN AS CUSKEY3 , 
			'BATCH' AS CUSKEY3D , 
			DKREF# AS CUSKEY4 , 
			'JOUNAL' AS CUSKEY4D , 
			'' AS CUSVEND , 
			DKBCUS AS CUSCUST , DIGITS ( DKRCID ) AS RECID 
		FROM 
			LGDAT . GTLYN GTRAN 
		WHERE 
			DKFSYR = 20 AND 
			DIGITS ( DKFSYY ) || DIGITS ( DKFSPR ) = VPERD AND 
			DKSRCE IN ( 'GJ' , 'RJ' , 'OS' , 'AU' ) 
  
		UNION ALL 
  
		SELECT 
			DKSRCE || DKQUAL , 
			DIGITS ( DKBTC# ) , DIGITS ( DKFSYY ) || DIGITS ( DKFSPR ) AS PERD , 
			CHAR ( DKTDAT ) , 
			CHAR ( DKPDAT ) , 
			DIGITS ( DKACC# ) , 
			DKAMT , 
			DKPJNM , 
			DKFUT4 , 
			DKREV , 
			'JOURNAL ENTRY' AS CUSMOD , 
			DKADDD AS CUSKEY1 , 
			'BATCH DESCR' AS CUSKEY1D , 
			DKREFD AS CUSKEY2 , 
			'LINE DESCR' AS CUSKEY2D , 
			DKKEYN AS CUSKEY3 , 
			'BATCH' AS CUSKEY3D , 
			DKREF# AS CUSKEY4 , 
			'JOUNAL' AS CUSKEY4D , 
			'' AS CUSVEND , 
			DKBCUS AS CUSCUST , DIGITS ( DKRCID ) AS RECID 
		FROM 
			LGDAT . GNYTR GTRAN 
		WHERE 
			DKFSYR = 20 AND 
			DIGITS ( DKFSYY ) || DIGITS ( DKFSPR ) = VPERD AND 
			DKSRCE IN ( 'GJ' , 'RJ' , 'OS' , 'AU' ) ; 
		 
	 ------------------------------------------------------------------------------------------------------------------------------------------------------ 
		INSERT INTO RLARP . FFSBGLWF SELECT * FROM RLARP . VW_FFWFACM ; 
  
	 ------------------------------------------------------------------------------------------------------------------------------------------------------ 
		DELETE FROM RLARP . FFSBGLWF WHERE MODULE = 'APAC' ; 
  
	 ------------------------------------------------------------------------------------------------------------------------------------------------------ 
		UPDATE RLARP . FFSBGLWF SET MODULE = 'APAC' WHERE MODULE = 'APMA' ; 
  
	 ------------------------------------------------------------------------------------------------------------------------------------------------------ 
		INSERT INTO 
			RLARP . FFSBGLR1_E 
		SELECT 
			W . MODULE , 
			W . BATCH , 
			W . PERD , 
			W . TDATE , 
			W . PDATE , 
			W . ACCT , 
			SUM ( W . AMT ) AMT , 
			W . PROJ , 
			W . USRN , 
			W . REV , 
			W . CUSMOD , 
			W . CUSKEY1 , 
			W . CUSKEY1D , 
			W . CUSKEY2 , 
			W . CUSKEY2D , 
			W . CUSKEY3 , 
			W . CUSKEY3D , 
			W . CUSKEY4 , 
			W . CUSKEY4D , 
			W . CUSVEND , 
			W . CUSCUST , 
			W . RECID 
		FROM 
			RLARP . FFSBGLWF W 
			EXCEPTION JOIN RLARP . FFSBGLR1 F ON 
				W . PERD = F . PERD AND 
				W . MODULE = F . MODULE AND 
				W . CUSMOD = F . CUSMOD AND 
				W . ACCT = F . ACCT AND 
				W . BATCH = F . BATCH AND 
				W . PDATE = F . PDATE AND 
				W . PROJ = F . PROJ AND 
				W . CUSKEY1 = F . CUSKEY1 AND 
				W . CUSKEY2 = F . CUSKEY2 AND 
				W . CUSKEY3 = F . CUSKEY3 AND 
				W . CUSKEY4 = F . CUSKEY4 AND 
				W . CUSVEND = F . CUSVEND AND 
				W . CUSCUST = F . CUSCUST AND 
				W . RECID = F . RECID 
		GROUP BY 
			W . MODULE , 
			W . BATCH , 
			W . PERD , 
			W . TDATE , 
			W . PDATE , 
			W . ACCT , 
			W . PROJ , 
			W . USRN , 
			W . REV , 
			W . CUSMOD , 
			W . CUSKEY1 , 
			W . CUSKEY1D , 
			W . CUSKEY2 , 
			W . CUSKEY2D , 
			W . CUSKEY3 , 
			W . CUSKEY3D , 
			W . CUSKEY4 , 
			W . CUSKEY4D , 
			W . CUSVEND , 
			W . CUSCUST , 
			W . RECID ; 
		 
	 ------------------------------------------------------------------------------------------------------------------------------------------------------ 
		INSERT INTO 
			RLARP . FFSBGLR1 
		SELECT 
			W . MODULE , 
			W . BATCH , 
			W . PERD , 
			W . TDATE , 
			W . PDATE , 
			W . ACCT , 
			SUM ( W . AMT ) AMT , 
			W . PROJ , 
			W . USRN , 
			W . REV , 
			W . CUSMOD , 
			W . CUSKEY1 , 
			W . CUSKEY1D , 
			W . CUSKEY2 , 
			W . CUSKEY2D , 
			W . CUSKEY3 , 
			W . CUSKEY3D , 
			W . CUSKEY4 , 
			W . CUSKEY4D , 
			W . CUSVEND , 
			W . CUSCUST , 
			W . RECID 
		FROM 
			RLARP . FFSBGLWF W 
			EXCEPTION JOIN RLARP . FFSBGLR1 F ON 
				W . PERD = F . PERD AND 
				W . MODULE = F . MODULE AND 
				W . CUSMOD = F . CUSMOD AND 
				W . ACCT = F . ACCT AND 
				W . BATCH = F . BATCH AND 
				W . PDATE = F . PDATE AND 
				W . PROJ = F . PROJ AND 
				W . CUSKEY1 = F . CUSKEY1 AND 
				W . CUSKEY2 = F . CUSKEY2 AND 
				W . CUSKEY3 = F . CUSKEY3 AND 
				W . CUSKEY4 = F . CUSKEY4 AND 
				W . CUSVEND = F . CUSVEND AND 
				W . CUSCUST = F . CUSCUST AND 
				W . RECID = F . RECID 
		GROUP BY 
			W . MODULE , 
			W . BATCH , 
			W . PERD , 
			W . TDATE , 
			W . PDATE , 
			W . ACCT , 
			W . PROJ , 
			W . USRN , 
			W . REV , 
			W . CUSMOD , 
			W . CUSKEY1 , 
			W . CUSKEY1D , 
			W . CUSKEY2 , 
			W . CUSKEY2D , 
			W . CUSKEY3 , 
			W . CUSKEY3D , 
			W . CUSKEY4 , 
			W . CUSKEY4D , 
			W . CUSVEND , 
			W . CUSCUST , 
			W . RECID ; 
			 
		OPEN C1 ;	 
		 
	END  ; 
  
GRANT ALTER , EXECUTE   
ON SPECIFIC PROCEDURE RLARP.SB_UD_R2 
TO PTROWBRIDG ; 
  
GRANT ALTER , EXECUTE   
ON SPECIFIC PROCEDURE RLARP.SB_UD_R2 
TO PUBLIC ;
