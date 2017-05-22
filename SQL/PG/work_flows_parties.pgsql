
WITH 
--primes in batches
PG AS (
SELECT
	BATCH,
	REC->>'CUSVEND' PARTY,
	SUBSTR(ACCT,7,4) PRIME,
	SUM(AMT) AMT,
	ROUND(SUM(AMT) FILTER (WHERE AMT > 0),2) AMTD
FROM
	r.ffsbglr1
WHERE
	PERD >= '1701' AND
	MODULE = 'APVN'
GROUP BY
	BATCH,
	REC->>'CUSVEND',
	SUBSTR(ACCT,7,4)
),
--batch primes aggregated
BP AS (
	SELECT
		BATCH,
		PARTY,
		ARRAY_AGG(PRIME ORDER BY PRIME ASC) PRIME_A,
		SUM(AMTD) AMTD
	FROM
		PG
	GROUP BY 
		BATCH,
		PARTY
),
--prime aggregate values
PA1 AS (
SELECT
	PRIME_A,
	PRIME,
	SUM(AMT),
	JSONB_BUILD_OBJECT(PRIME,to_char(ROUND(SUM(AMT),2),'999,999,999')) JD
FROM	
	BP
	INNER JOIN PG ON
		PG.BATCH = BP.BATCH AND
		PG.PARTY = BP.PARTY
GROUP BY
	PRIME_A,
	PRIME
ORDER BY PRIME_A ASC
),
--build prime aggregates into a json
PA2 AS (
SELECT
	PRIME_A,
	tps.jsonb_concat_obj(JD) JD
FROM
	PA1
GROUP BY
	PRIME_A

),
--aggregate vendor values per prime group
PAP AS (
SELECT
	bp.prime_a,
	jd,
	JSONB_BUILD_OBJECT(party,TO_CHAR(SUM(amtd),'999,999,999')) pjd
FROM 
	PA2
	INNER JOIN BP ON
		BP.PRIME_A = PA2.PRIME_A
GROUP BY
	bp.prime_a,
	jd,
	party
)
--turn vendor totals into json per the prime_a
SELECT
	prime_a,
	jsonb_pretty(jd) jd,
	jsonb_pretty(tps.jsonb_concat_obj(pjd)) pjd
FROM
	PAP
GROUP BY
	prime_a,
	jd
ORDER BY 
	prime_a ASC