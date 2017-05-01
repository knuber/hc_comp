SELECT 
	--rec->>'AccountName',
	rx.reg[1] checkn,
	rx.reg[2] refnum,
	(rec->>'AsOfDate')::date bank_date,
	(rec->>'Amount')::numeric amount
FROM 
	tps.trans
	JOIN LATERAL regexp_matches(trans.rec ->> 'Description'::text, '[^0-9]*([0-9]*)\s(.*)'::text) AS rx(reg) ON TRUE
WHERE 
	trans.rec @> '{"Transaction":"Checks Paid","AccountName":"The HC Operating Company OPERA"}'::jsonb AND rec->>'AsOfDate' >= '2016-01-01'