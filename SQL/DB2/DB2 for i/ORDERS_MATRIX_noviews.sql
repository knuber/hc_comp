SELECT
	O.*, 
	O.FB_VAL_LOC*RATE FB_VAL_USD,
	COALESCE(AVMAJG,AWMAJG)||' - '||RTRIM(BQDES) MAJG,  
	COALESCE(AVMING,AWMING)||' - '||RTRIM(BRDES) MING,  
	COALESCE(AVMAJS,AWMAJS)||' - '||RTRIM(MS.BSDES1) MAJS,  
	COALESCE(AVMINS,AWMINS)||' - '||RTRIM(NS.BSDES1) MINS,  
	COALESCE(AVGLCD,AWGLCD)||' - '||RTRIM(GD.A30) GLDC,  
	COALESCE(AVGLED,AWGLED)||' - '||RTRIM(GE.A30) GLEC, 
	COALESCE(AVHARM, AWHARM) HARM,  
	COALESCE(AVCLSS,AWCLSS) CLSS,  
	SUBSTR(COALESCE(AVCPT#,AWCPT#),1,1) BRAND, 
	COALESCE(AVASSC,AWASSC) ASSC,
	BC.BVCLAS BILL_CUST_CLASS, 
	BC.BVCUST||' - '||RTRIM(BC.BVNAME) BILL_CUST,
	SC.BVCLAS SHIP_CUST_CLASS, 
	SC.BVCUST||' - '||RTRIM(SC.BVNAME) SHIP_CUST
FROM
	(
		SELECT
			------------------------status-------------------------------------------------------------------------
			F.FLAG, 
			CASE DDITST 
				WHEN 'C' THEN 
					CASE DDQTSI 
						WHEN 0 THEN 'CANCELED' 
						ELSE 'CLOSED' 
					END 
				ELSE 
					CASE F.FLAG
						WHEN 'SHIPMENT' THEN 'CLOSED' 
						ELSE CASE WHEN DDQTSI >0 THEN 'BACKORDER' ELSE 'OPEN' END 
					END 
			END CALC_STATUS, 
			-----------------------id's and flags------------------------------------------------------------------
			DDORD#, 
			DDITM#, 
			FGBOL#, 
			FGENT#, 
			DIINV#, 
			DILIN#, 
			DDGLC, 
			DDODAT, 
			FESDAT, 
			FESIND, 
			DHIDAT, 
DHPOST, 
			------------------------periods------------------------------------------------------------------------
			SUBSTR(CHAR(DCODAT),3,2)||SUBSTR(CHAR(DCODAT),6,2) CAPR_ORD,
			SUBSTR(CHAR(DDQDAT),3,2)||SUBSTR(CHAR(DDQDAT),6,2) CAPR_REQ,
			DIGITS(DHARYR)||DIGITS(DHARPR) FSPR_INV,
			------------------------attributes---------------------------------------------------------------------
			COALESCE(DHPLNT,FGPLNT,SUBSTR(DDSTKL,1,3)) PLNT,
			COALESCE(DCBCUS,DHBCS#) CUST_BILL,
			COALESCE(DCSCUS,DHSCS#) CUST_SHIP,
			COALESCE(DIGLCD, DDGLC) GL_CODE, 
			COALESCE(DIPART,DDPART) PART,
			RTRIM(DCPROM) PROMO,
			DDCRRS RETURN_REAS,
			COALESCE(DHTRCD,DCTRCD) TERMS,
			CASE F.FLAG
				WHEN 'REMAINDER' THEN 
					DDQTOI-DDQTSI
				WHEN 'SHIPMENT' THEN
					FGQSHP*CASE FESIND WHEN 'Y' THEN 1 ELSE 0 END
			END FB_QTY,
			COALESCE(DHCURR,DCCURR) CURRENCY,
			CASE F.FLAG
				WHEN 'REMAINDER' THEN 
					--------remaining qty*calculated price per---------
					CASE DDQTOI 
						WHEN 0 THEN 0 
						ELSE DDTOTI/DDQTOI 
					END*(DDQTOI - DDQTSI)
				WHEN 'SHIPMENT' THEN
					---------BOL quantity * calculated price per-------
					CASE DDQTOI 
						WHEN 0 THEN 0 
						ELSE DDTOTI/DDQTOI 
					END*COALESCE(FGQSHP*CASE FESIND WHEN 'Y' THEN 1 ELSE 0 END,DDQTSI)
			END FB_VAL_LOC
		FROM
			----------------------Order Data-----------------------------
			LGDAT.OCRI 
			INNER JOIN LGDAT.OCRH ON 
				DCORD# = DDORD# 
			-----------------------BOL-----------------------------------
			LEFT OUTER JOIN LGDAT.BOLD ON 
				FGORD# = DDORD# AND 
				FGITEM = DDITM# 
			LEFT OUTER JOIN LGDAT.BOLH ON 
				FEBOL# = FGBOL#
			----------------------Invoicing------------------------------
			LEFT OUTER JOIN LGDAT.OID ON 
				DIINV# = FGINV# AND 
				DILIN# = FGLIN# 
			LEFT OUTER JOIN LGDAT.OIH ON 
				DHINV# = DIINV# 
			CROSS JOIN TABLE( VALUES
				('REMAINDER'),
				('SHIPMENT')
			) AS F(FLAG)
		WHERE
			DCODAT >= '2016-06-01' AND
			(	
				(F.FLAG = 'REMAINDER' AND DDQTOI-DDQTSI <> 0) OR 
				(F.FLAG = 'SHIPMENT' AND FGQSHP*CASE FESIND WHEN 'Y' THEN 1 ELSE 0 END<>0)
			)
	) O
	LEFT OUTER JOIN LGDAT.STKA ON
		V6PART = PART
	LEFT OUTER JOIN LGDAT.STKMM ON
		AVPART = PART
	LEFT OUTER JOIN LGDAT.STKMP ON
		AWPART = PART
	LEFT OUTER JOIN LGDAT.MAJG ON  
		BQGRP = AVMAJG  
	LEFT OUTER JOIN LGDAT.MMSL MS ON  
		MS.BSMJCD = COALESCE(AVMAJS, AWMAJS) AND  
		MS.BSMNCD = ''  
	LEFT OUTER JOIN LGDAT.MMSL NS ON  
		NS.BSMJCD = COALESCE(AVMAJS, AWMAJS) AND  
		NS.BSMNCD = COALESCE(AVMINS, AWMINS)
	LEFT OUTER JOIN LGDAT.MMGP ON  
		BRGRP = COALESCE(AVMAJG, AWMAJG) AND  
		BRMGRP = COALESCE(AVMING, AWMING)
	LEFT OUTER JOIN LGDAT.CODE GE ON  
		RTRIM(LTRIM(GE.A9)) =COALESCE(AVGLED, AWGLED) AND  
		GE.A2 = 'GE'  
	LEFT OUTER JOIN LGDAT.CODE GD ON  
		RTRIM(LTRIM(GD.A9)) = COALESCE(AVGLCD, AWGLCD) AND  
		GD.A2 = 'EE'  
	LEFT OUTER JOIN LGDAT.PLNT ON	
		YAPLNT = PLNT
	LEFT OUTER JOIN RLARP.VW_FFGLPD GP ON
		GP.COMP = YACOMP AND
		GP.FSPR = FSPR_INV
	LEFT OUTER JOIN RLARP.VW_FFGLPD GF ON
		GF.COMP = YACOMP AND
		GF.SDAT <= DDODAT AND
		GF.EDAT >= DDODAT
	LEFT OUTER JOIN RLARP.FFCRET X ON
		X.PERD = COALESCE(FSPR_INV, GF.FSPR) AND
		X.FCUR = CURRENCY AND	
		X.TCUR = 'US' AND
		X.RTYP = 'MA'
	LEFT OUTER JOIN LGDAT.CUST BC ON
		BC.BVCUST = CUST_BILL
	LEFT OUTER JOIN LGDAT.CUST SC ON
		SC.BVCUST = CUST_SHIP
