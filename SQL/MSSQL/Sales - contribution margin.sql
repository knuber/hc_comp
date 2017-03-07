WITH
	s1 (is_year, fsline, bcus, scus, prep, part, plnt,  amount, matcost, qty) AS (
	SELECT
		is_year,
		AZGROP + ' - ' + BQ1TITL fsline, 
		coalesce(dhbcs#, dcbcus) bcus,
		coalesce(dhscs#, dcscus) scus,
		COALESCE(dcppcl,diprep) prep,
		coalesce(dipart, ddpart) part,
		COALESCE(dhplnt, SUBSTRING(ddstkl,1,3)) plnt,
		SUM(ITEM_VALUE*R_RATE) amount,
		SUM(ITEM_matcost*C_RATE) matcost,
		SUM(item_quantity) qty
	FROM
		R.OM_STAT
	WHERE
		IS_YEAR = 16 OR (IS_YEAR = 17 AND IS_PERD <= 8)
	GROUP BY
		is_year,
		AZGROP + ' - ' + BQ1TITL, 
		coalesce(dhbcs#, dcbcus),
		coalesce(dhscs#, dcscus),
		COALESCE(dcppcl,diprep),
		coalesce(dipart, ddpart),
		COALESCE(dhplnt, SUBSTRING(ddstkl,1,3))
	)
SELECT
	is_year,
	fsline,
	COALESCE(chan,'UNDEFINED') chan,
	COALESCE(geo,'UNDEFINED') geo,
	coalesce(avgled, awgled,'UNDEFINED') gled,
	COALESCE(cgrp, bc.bvname) account,
	coalesce(avmajg, awmajg,'UNDEFINED') + ' - ' + MAJG.BQDES majg,
	coalesce(avming, awming,'UNDEFINED') + ' - ' + MMGP.BRDES ming,
	coalesce(avmajs, awmajs,'UNDEFINED') + ' - ' + MAS.BSDES1 majs,
	coalesce(avmins, awmins,'UNDEFINED') + ' - ' + MIS.BSDES1 mins,
	CASE COALESCE(AVMING,AWMING)
				WHEN 'B10' THEN 'LABELED'
				WHEN 'B11' THEN 'PRINTED'
				WHEN 'B52' THEN 'LABELED'
				ELSE 'UNBRANDED'
			END branding,
	CAT.DESCR category,
	COL.DESCR color,
	SUBSTRING(part,1,8) mold,
	SUBSTRING(part,1,3)+' - '+COALESCE(CAT.DESCR,'') family,
	plnt,
	prep,
	sum(amount) amount,
	COALESCE(sum(matcost),0) matcost,
	SUM(
		COALESCE(
			(
				COALESCE(FREIGHTCOST,COALESCE(PQF.RoadMiles,FD.MILES)*COALESCE(PQF.Rate,FL.RATE, FS.RATE))/24
			)
			*CASE 
				WHEN COALESCE(V6MPCK,0) <= 0 THEN 0 
				ELSE qty/V6MPCK 
			END
			*CASE prep 
				WHEN 'P' THEN 1
				WHEN 'C' THEN 0
				WHEN 'I' THEN 0
				WHEN '' THEN 1
			END
			--coalesce against -0- in case of null
			,0
		)
	) FREIGHT_PQ,
	--pt credits
	SUM(
		ROUND(
			COALESCE(CRED,0)*
			amount
		,2)
	) CRED_EXT_USD,
		--pt rebates
	SUM(
		ROUND(
			COALESCE(REBT,0)*
			amount
		,2)
	) REBT_EXT_USD
FROM
	s1
	LEFT OUTER JOIN LGDAT.CUST BC ON
		bc.bvcust = bcus
	LEFT OUTER JOIN LGDAT.CUST SC ON
		sc.bvcust = scus
	LEFT OUTER JOIN R.FFCHNL CH ON
		ch.bill = bc.bvclas AND
		ch.ship = sc.bvclas
	LEFT OUTER JOIN LGDAT.STKMM ON
		avpart = part
	LEFT OUTER JOIN LGDAT.STKMP ON
		awpart = part
	LEFT OUTER JOIN R.FFTERR T ON
		PROV = SC.BVPRCD AND
		CTRY = SC.BVCTRY AND
		T.VERS = 'INI'
	LEFT OUTER JOIN LGDAT.STKA ON
		V6PART = part AND
		V6PLNT = plnt
	LEFT OUTER JOIN PRICEQUOTE.DBO.FREIGHT PQF ON
		CUSTOMERNUMBER = scus AND
		MANUFACTURESOURCE = plnt
	LEFT OUTER JOIN LGDAT.PLNT P ON
		P.YAPLNT = plnt
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
	LEFT OUTER JOIN R.FFCUST CG ON		
		CG.CUSTN = bcus
	LEFT OUTER JOIN R.FFCRED CR ON
		CR.CUSTG = COALESCE(CG.CGRP,BC.BVCUST+' - '+RTRIM(BC.BVNAME)) AND
		CR.VERS = '1516'
	LEFT OUTER JOIN R.NMC_CAT CAT ON
			CAT.F3 = SUBSTRING(part,1,3)
	LEFT OUTER JOIN R.NMC_COL COL ON
		COL.CODE = SUBSTRING(part,9,3)
	LEFT OUTER JOIN LGDAT.MAJG MAJG ON
		MAJG.BQGRP = COALESCE(avmajg, awmajg)
	LEFT OUTER JOIN LGDAT.MMGP MMGP ON
		MMGP.BRGRP = COALESCE(avmajg, awmajg) AND
		MMGP.BRMGRP = COALESCE(avming, awming)
	LEFT OUTER JOIN LGDAT.MMSL MAS ON
		MAS.BSMJCD = COALESCE(avmajs, awmajs) AND
		MAS.BSMNCD = ''
	LEFT OUTER JOIN LGDAT.MMSL MIS ON
		MIS.BSMJCD = COALESCE(avmajs, awmajs) AND
		MIS.BSMNCD = COALESCE(avmins, awmins)
GROUP BY
	is_year,
	fsline,
	COALESCE(chan,'UNDEFINED'),
	COALESCE(geo,'UNDEFINED'),
	coalesce(avgled, awgled,'UNDEFINED'),
	COALESCE(cgrp, bc.bvname),
	coalesce(avmajg, awmajg,'UNDEFINED') + ' - ' + MAJG.BQDES,
	coalesce(avming, awming,'UNDEFINED') + ' - ' + MMGP.BRDES,
	coalesce(avmajs, awmajs,'UNDEFINED') + ' - ' + MAS.BSDES1,
	coalesce(avmins, awmins,'UNDEFINED') + ' - ' + MIS.BSDES1,
	CASE COALESCE(AVMING,AWMING)
				WHEN 'B10' THEN 'LABELED'
				WHEN 'B11' THEN 'PRINTED'
				WHEN 'B52' THEN 'LABELED'
				ELSE 'UNBRANDED'
			END,
	CAT.DESCR,
	COL.DESCR,
	SUBSTRING(part,1,8),
	SUBSTRING(part,1,3)+' - '+COALESCE(CAT.DESCR,''),
	plnt,
	prep
ORDER BY
	fsline,
	COALESCE(chan,'UNDEFINED'),
	COALESCE(geo,'UNDEFINED')
OPTION (MAXDOP 8, RECOMPILE)