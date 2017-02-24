
SELECT TOP 100
	dcbcus,
	dcscus, 
	ddpart, 
	dcodat, 
	ddqdat, 
	dhsdat,
	azgrop,
	DDGLC,
	SUM(item_quantity) qty, 
	SUM(item_value) amt, 
	SUM(item_cost) cost
FROM 
	R.OM_STAT 
WHERE 
	DCBCUS IS NOT NULL AND azgrop = '41010' AND
	os_year = 16 AND
	status <> 'CANCELED' AND
	item_value <> 0 AND
	DDQTOI <> 0 AND
	DDTOTI <> 0 AND
	DCBCUS <> 'MISC0001' AND
	DCSCUS <> 'MISC0001' AND
	DCSCUS <> 'MISC0003' AND
	DDPART <> ''
GROUP BY 
	dcbcus,
	dcscus, 
	ddpart, 
	dcodat, 
	ddqdat, 
	dhsdat,
	azgrop,
	ddglc
ORDER BY 


	dcbcus,
	dcscus, 
	ddpart, 
	dcodat, 
	ddqdat, 
	dhsdat
OPTION (MAXDOP 8, RECOMPILE)
