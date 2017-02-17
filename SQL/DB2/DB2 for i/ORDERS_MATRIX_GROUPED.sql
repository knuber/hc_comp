INSERT INTO RLARP.FFORDH
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
	------------------------periods------------------------------------------------------------------------
	SUBSTR(CHAR(DCODAT),3,2)||SUBSTR(CHAR(DCODAT),6,2) CAPR_ORD,
	GF.FSPR FSPR_ORD,
	SUBSTR(CHAR(DDQDAT),3,2)||SUBSTR(CHAR(DDQDAT),6,2) CAPR_REQ,
	DIGITS(DHARYR)||DIGITS(DHARPR) FSPR_INV,
	------------------------attributes---------------------------------------------------------------------
	COALESCE(DHPLNT,FGPLNT,SUBSTR(DDSTKL,1,3)) PLNT,
	YACOMP COMP,
	DDPART PART,
	COALESCE(DCBCUS,DHBCS#) CUST_BILL,
	COALESCE(DCSCUS,DHSCS#) CUST_SHIP,
	COALESCE(DIGLCD, DDGLC) GL_CODE, 
	RTRIM(DCPROM) PROMO,
	SUM(
	CASE F.FLAG
		WHEN 'REMAINDER' THEN 
			DDQTOI-DDQTSI
		WHEN 'SHIPMENT' THEN
			FGQSHP*CASE FESIND WHEN 'Y' THEN 1 ELSE 0 END
	END)  FB_QTY,
	COALESCE(DHCURR,DCCURR) CURRENCY,
	SUM(CAST(
	CASE F.FLAG
		WHEN 'REMAINDER' THEN 
			--------remaining qty*calculated price per---------
			CASE COALESCE(DDQTOI,0) 
				WHEN 0 THEN 0 
				ELSE DDTOTI/DDQTOI 
			END*(DDQTOI - DDQTSI)
		WHEN 'SHIPMENT' THEN
			---------BOL quantity * calculated price per-------
			CASE COALESCE(DDQTOI,0)
				WHEN 0 THEN 0 
				ELSE DDTOTI/DDQTOI 
			END*COALESCE(FGQSHP*CASE FESIND WHEN 'Y' THEN 1 ELSE 0 END,DDQTSI)
	END AS DEC(18,2))) FB_VAL_LOC
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
	LEFT OUTER JOIN LGDAT.PLNT ON
		YAPLNT = COALESCE(DHPLNT,FGPLNT,SUBSTR(DDSTKL,1,3))
	LEFT OUTER JOIN RLARP.VW_FFGLPD GF ON
		GF.COMP = YACOMP AND
		GF.SDAT <= DCODAT AND
		GF.EDAT >= DCODAT
	CROSS JOIN TABLE( VALUES
		('REMAINDER'),
		('SHIPMENT')
	) AS F(FLAG)
WHERE
	DCODAT >= '2014-01-01' AND
	DCODAT <= '2014-12-31' AND
	(
		(F.FLAG = 'REMAINDER' AND DDQTOI-DDQTSI <> 0) OR 
		(F.FLAG = 'SHIPMENT' AND FGQSHP*CASE FESIND WHEN 'Y' THEN 1 ELSE 0 END<>0)
	) 
GROUP BY
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
	END, 
	------------------------periods------------------------------------------------------------------------
	SUBSTR(CHAR(DCODAT),3,2)||SUBSTR(CHAR(DCODAT),6,2),
	GF.FSPR,
	SUBSTR(CHAR(DDQDAT),3,2)||SUBSTR(CHAR(DDQDAT),6,2),
	DIGITS(DHARYR)||DIGITS(DHARPR),
	------------------------attributes---------------------------------------------------------------------
	COALESCE(DHPLNT,FGPLNT,SUBSTR(DDSTKL,1,3)),
	YACOMP,
	DDPART,
	COALESCE(DCBCUS,DHBCS#),
	COALESCE(DCSCUS,DHSCS#),
	COALESCE(DIGLCD, DDGLC), 
	RTRIM(DCPROM),
	COALESCE(DHCURR,DCCURR)