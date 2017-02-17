
--EXPLAIN ANALYZE
SELECT
	x.flag,
	"dcord#",
	"dditm#",
	"febol#",
	"fgent#",
	"dilin#",
	"diinv#",
	"dhinv#",
	dditst,
	CASE ocri.dditst
            WHEN 'C'::text THEN
		    CASE ocri.ddqtsi
			WHEN 0 THEN 'CANCELED'::text
			ELSE 'CLOSED'::text
		    END
            ELSE
		    CASE
			WHEN ocri.ddqtsi > 0::numeric THEN 'BACKORDER'::text
			ELSE 'OPEN'::text
		    END
        END AS calc_status,
	ddqtoi, 
	fgqshp,
	diqtsh,
        CASE x.flag
		WHEN 'REMAINDER' THEN 
			DDQTOI-DDQTSI
		WHEN 'SHIPMENT' THEN
			FGQSHP*CASE FESIND WHEN 'Y' THEN 1 ELSE 0 END
	END  fb_qty,
	(
		(x.flag = 'REMAINDER' AND DDQTOI-DDQTSI <> 0) OR 
		(x.flag = 'SHIPMENT' AND FGQSHP*CASE FESIND WHEN 'Y' THEN 1 ELSE 0 END<>0)
	)::tEXT include
FROM
	lgdat.ocrh
	INNER JOIN lgdat.ocri ON
		"ddord#" = "dcord#"
	LEFT OUTER JOIN lgdat.bold ON
		"fgord#" = "ddord#" AND
		fgitem = "dditm#"
	LEFT OUTER JOIN lgdat.bolh ON
		"febol#" = "fgbol#"
	LEFT OUTER JOIN lgdat.oid ON
		"diord#" = "ddord#" AND
		"diitm#" = "dditm#"
	LEFT OUTER JOIN lgdat.oih ON
		"dhinv#" = "diinv#" AND
		"dhboln" = "febol#"
	CROSS JOIN unnest(ARRAY['SHIPMENT','REMAINDER']) x(flag)
WHERE 
	--"dcord#" = 701000
	DCODAT >= '2016-09-01'
	/*(
		(x.flag = 'REMAINDER' AND DDQTOI-DDQTSI <> 0) OR 
		(x.flag = 'SHIPMENT' AND FGQSHP*CASE FESIND WHEN 'Y' THEN 1 ELSE 0 END<>0)
	) 
	*/
ORDER BY
	"dcord#",
	"dditm#",
	"febol#",
	"fgent#",
	"dhinv#",
	"dilin#"
LIMIT 200


--set max_parallel_workers_per_gather = 8
