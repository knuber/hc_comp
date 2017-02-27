WITH
	oms (bcus, scus, part, plnt, dcodat, ddqdat, dhsdat, azgrop, dhincr, glc, dccurr, trcd, os_yp, is_yp, qty, amt, cost)
	AS
	(
	SELECT
		coalesce(dhbcs#, dcbcus) bcus,
		coalesce(dhscs#,dcscus) scus, 
		coalesce(dipart, ddpart) part, 
		coalesce(dhplnt, ddstkl) plnt,
		dcodat, 
		ddqdat, 
		dhsdat,
		azgrop,
		dhincr,
		COALESCE(DIGLCD, ddglc) glc,
		dccurr,
		coalesce(dhtrcd, dctrcd) trcd,
		os_year +os_perd os_yp,  
		coalesce(is_year + is_perd,'O'+dbo.GREATEST_CHAR(SUBSTRING(ssyr,3,2)+sspr,'1709'))   is_yp,
		SUM(item_quantity) qty, 
		SUM(item_value*r_rate) amt, 
		SUM(item_cost*c_rate) cost
	FROM 
		R.OM_STAT 
		LEFT OUTER JOIN R.GLDATREF ON
			N1COMP = 93 AND
			N1SD01 <= ddqdat AND
			N1ED01 >= ddqdat
	WHERE 
		azgrop IN ('41010','41020') AND
		(os_year >= 16 OR is_year >= 16) AND
		COALESCE(DIGLCD, ddglc) <> 'FRT' AND
		status <> 'CANCELLED'
	GROUP BY 
		coalesce(dhbcs#, dcbcus),
		coalesce(dhscs#,dcscus), 
		coalesce(dipart, ddpart) , 
		coalesce(dhplnt, ddstkl) ,
		dcodat, 
		ddqdat, 
		dhsdat,
		azgrop,
		dhincr, 
		COALESCE(DIGLCD, ddglc),
		dccurr,
		coalesce(dhtrcd, dctrcd),
		os_year +os_perd,  
		coalesce(is_year + is_perd,'O'+dbo.GREATEST_CHAR(SUBSTRING(ssyr,3,2)+sspr,'1709'))
	) 
	--lk (dcbcus, dcscus, ddpart, ddstkl, dcodat, ddqdat, dhsdat,azgrop, ddglc, dccurr, trcd, qty, amt, cost, chan, geo, gled)
	SELECT
		bcus, 
		bc.bvclas bclass, 
		scus, sc.bvclas sclass, 
		part, 
		plnt, 
		dcodat, 
		ddqdat, 
		CASE dhsdat WHEN '0001-01-01' THEN NULL ELSE dhsdat END dhsdat,
		azgrop, 
		dhincr, 
		glc, 
		dccurr, 
		trcd, 
		os_yp,
		is_yp,
		qty, 
		amt, 
		cost, 
		chan, 
		COALESCE(avgled, awgled) gled
	FROM
		oms
		LEFT OUTER JOIN LGDAT.CUST BC ON
			BC.bvcust = bcus
		LEFT OUTER JOIN LGDAT.CUST SC ON
			SC.bvcust = scus
		LEFT OUTER JOIN R.FFCHNL ON
			bill = bc.bvclas AND
			ship = COALESCE(sc.bvclas,'')
		LEFT OUTER JOIN LGDAT.STKMM ON
			avpart = part
		LEFT OUTER JOIN LGDAT.STKMP ON
			awpart = part
	WHERE
		bc.bvclas <> 'SALE'
OPTION (MAXDOP 8)