SELECT
	rec->>'AsOfDate',
	rec->>'Transaction',
	rec->>'AccountName',
	rec->>'Reference',
	CHK[1],
	(rec->>'Amount')::numeric
FROM
	tps.trans 
	LEFT JOIN LATERAL regexp_matches(rec->>'Reference',$$([^'0].*)$$,'g') CHK ON TRUE
WHERE
	srce = 'PNCC' AND
	rec @> $${"Transaction":"Checks Paid","AccountName":"The HC Operating Company PAYR"}$$
ORDER BY
	CHK[1]::numeric asc