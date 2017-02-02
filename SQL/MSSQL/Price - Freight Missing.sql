SELECT

		QZCRYC ORIG_CTRY,
		QZPROV ORIG_PROV,
		SUBSTRING(QZPOST,1,3) ORIG_LANE,
		CASE QZCTRY 
			WHEN 'CAN' THEN SUBSTRING(REPLACE(REPLACE(QZPOST,'-',''),' ',''),1,3)  + ' ' + SUBSTRING(REPLACE(REPLACE(QZPOST,'-',''),' ',''),4,3)
			WHEN 'USA' THEN SUBSTRING(QZPOST,1,5)
			ELSE REPLACE(QZPOST,'-',' ')
		END ORIG_POST,
		SC.BVCTRY DEST_CTRY,
		SC.BVPRCD DEST_PROV,
		SUBSTRING(SC.BVPOST,1,3) DEST_LANE,
		CASE SC.BVCTRY
			WHEN 'CAN' THEN SUBSTRING(REPLACE(REPLACE(SC.BVPOST,'-',''),' ',''),1,3) + ' ' + SUBSTRING(REPLACE(REPLACE(SC.BVPOST,'-',''),' ',''),4,3)
			WHEN 'USA' THEN SUBSTRING(REPLACE(SC.BVPOST,'-',' '),1,5)
			ELSE REPLACE(SC.BVPOST,'-',' ')
		END DEST_POST,
		SC.BVCUST + ' - ' + SC.BVNAME SHIP_CUST,
		RTRIM(SC.BVADR1)+' '+RTRIM(SC.BVADR2)+' '+ RTRIM(SC.BVADR3)+' '+RTRIM(SC.BVADR4) ADRS,
		SUBSTRING(DDSTKL, 1, 3) PLNT,
		FD.MILES,
		FL.RATE LANE_RATE,
		FS.RATE STATE_RATE,
		AVG(PQ.RoadMiles) MilesActual,
		PQ.Rate,
		COALESCE(CASE PQ.RoadMiles WHEN 0 THEN FD.MILES ELSE PQ.RoadMiles END, FD.MILES) C_MILES,
		COALESCE(PQ.RATE, FL.RATE, FS.RATE) C_RATE,
		SUM(DDTOTI) DDTOTI

FROM

	---------------Order Data---------------

	LGDAT.OCRI
	INNER JOIN LGDAT.OCRH ON
		DCORD# = DDORD#
	LEFT OUTER JOIN LGDAT.CUST BC ON
		DCBCUS = BC.BVCUST
	LEFT OUTER JOIN LGDAT.CUST SC ON
		DCSCUS = SC.BVCUST
	LEFT OUTER JOIN LGDAT.PLNT P ON
		P.YAPLNT = SUBSTRING(DDSTKL,1,3)

	LEFT OUTER JOIN LGDAT.ADRS ON
		QZADR = YAADR#
	LEFT OUTER JOIN R.FRDIST FD ON
		--FD.SRCE = 'TMS' AND
		FD.LEVL = 'POSTAL' AND
		FD.ORIG =	CASE QZCTRY 
						WHEN 'CAN' THEN SUBSTRING(REPLACE(REPLACE(QZPOST,'-',''),' ',''),1,3)  + ' ' +  SUBSTRING(REPLACE(REPLACE(QZPOST,'-',''),' ',''),4,3)
						WHEN 'USA' THEN SUBSTRING(QZPOST,1,5)
						ELSE REPLACE(QZPOST,'-',' ')
					END AND
		FD.DEST =	CASE SC.BVCTRY
						WHEN 'CAN' THEN SUBSTRING(REPLACE(REPLACE(SC.BVPOST,'-',''),' ',''),1,3)  + ' ' +  SUBSTRING(REPLACE(REPLACE(SC.BVPOST,'-',''),' ',''),4,3)
						WHEN 'USA' THEN SUBSTRING(REPLACE(SC.BVPOST,'-',' '),1,5)
						ELSE REPLACE(SC.BVPOST,'-',' ')
					END
	LEFT OUTER JOIN R.FRRATE FL ON
		FL.LEVL = 'LANE' AND
		FL.ORIG = SUBSTRING(QZPOST,1,3) AND
		FL.DEST = SUBSTRING(SC.BVPOST,1,3)
	LEFT OUTER JOIN R.FRRATE FS ON
		FS.LEVL = 'STATE' AND
		FS.ORIG = RTRIM(QZPROV) AND
		FS.DEST = RTRIM(SC.BVPRCD)
	LEFT OUTER JOIN PriceQuote.dbo.Freight PQ ON
		CustomerNumber = SC.BVCUST AND
		ManufactureSource = SUBSTRING(DDSTKL, 1, 3)

WHERE
	DCODAT >= '2015-06-01' AND
	BC.BVCLAS NOT IN ('SALE','INTC','INTR') AND
	DDQTOI <> 0 AND
	DDTOTI <> 0 AND
	DCBCUS <> 'MISC0001' AND
	DCSCUS <> 'MISC0001' AND
	DCSCUS <> 'MISC0003' AND
	SC.BVCTRY IN ('CAN','USA') AND
	DDPART <> '' AND
	CASE DDITST WHEN 'C' THEN 
		CASE DDQTSI WHEN 0 THEN 'CANCELED' ELSE 'CLOSED' END 
		ELSE CASE WHEN DDQTSI >0 THEN 'BACKORDER' ELSE 'OPEN' END 
	END <> 'CANCELED'

GROUP BY
	QZCRYC,
	QZPROV,
	SUBSTRING(QZPOST,1,3),
	CASE QZCTRY 
		WHEN 'CAN' THEN SUBSTRING(REPLACE(REPLACE(QZPOST,'-',''),' ',''),1,3)  + ' ' +  SUBSTRING(REPLACE(REPLACE(QZPOST,'-',''),' ',''),4,3)
		WHEN 'USA' THEN SUBSTRING(QZPOST,1,5)
		ELSE REPLACE(QZPOST,'-',' ')
	END ,
	SC.BVCTRY ,
	SC.BVPRCD ,
	SUBSTRING(SC.BVPOST,1,3),
	CASE SC.BVCTRY
		WHEN 'CAN' THEN SUBSTRING(REPLACE(REPLACE(SC.BVPOST,'-',''),' ',''),1,3)  + ' ' +  SUBSTRING(REPLACE(REPLACE(SC.BVPOST,'-',''),' ',''),4,3)
		WHEN 'USA' THEN SUBSTRING(REPLACE(SC.BVPOST,'-',' '),1,5)
		ELSE REPLACE(SC.BVPOST,'-',' ')
	END,
	SC.BVCUST + ' - ' + SC.BVNAME,
	RTRIM(SC.BVADR1)+' '+RTRIM(SC.BVADR2)+' '+ RTRIM(SC.BVADR3)+' '+RTRIM(SC.BVADR4),
	SUBSTRING(DDSTKL, 1, 3),
	FD.MILES,
	FL.RATE,
	FS.RATE,
	PQ.Rate,
	COALESCE(CASE PQ.RoadMiles WHEN 0 THEN FD.MILES ELSE PQ.RoadMiles END, FD.MILES),
	COALESCE(FL.RATE, PQ.RATE, FS.RATE)

OPTION (MAXDOP 8)