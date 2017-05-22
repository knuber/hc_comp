
WITH 
--primes in batches
PG AS (
SELECT
	SUBSTRING(ACCT,1,2) COMP,
	BATCH,
	(REC->>'CUSVEND')||' - '||btname PARTY,
	AZGROP||' - '||bq1titl PRIME,
	SUM(AMT) AMT,
	ROUND(SUM(AMT) FILTER (WHERE AMT > 0),2) AMTD
FROM
	r.ffsbglr1
	LEFT OUTER JOIN lgdat.mast ON
		azcomp||azcode = acct
	LEFT OUTER JOIN lgdat.fgrp ON
		bq1grp = azgrop
	LEFT OUTER JOIN lgdat.vend ON
		btvend = REC->>'CUSVEND'
WHERE
	PERD >= '1701' AND
	MODULE = 'APVN'
GROUP BY
	SUBSTRING(ACCT,1,2),
	BATCH,
	(REC->>'CUSVEND')||' - '||btname,
	AZGROP||' - '||bq1titl
),
--batch primes aggregated
BP AS (
	SELECT
		COMP,
		BATCH,
		PARTY,
		JSONB_AGG(PRIME ORDER BY PRIME ASC) PRIME_A,
		SUM(AMTD) AMTD
	FROM
		PG
	GROUP BY 
		COMP,
		BATCH,
		PARTY
),
--prime aggregate values
PA1 AS (
SELECT
	BP.COMP,
	PRIME_A,
	PRIME,
	SUM(AMT) AMT,
	SUM(AMTD) AMTD,
	JSONB_BUILD_OBJECT(PRIME,to_char(ROUND(SUM(AMT),2),'999,999,999')) JD
FROM	
	BP
	INNER JOIN PG ON
		PG.BATCH = BP.BATCH AND
		PG.PARTY = BP.PARTY
GROUP BY
	BP.COMP,
	PRIME_A,
	PRIME
ORDER BY PRIME_A ASC
),
--build prime aggregates into a json
PA2 AS (
SELECT
	COMP,
	PRIME_A,
	tps.jsonb_concat_obj(JD) JD
FROM
	PA1
GROUP BY
	COMP,
	PRIME_A

),
--aggregate vendor values per prime group
PAP AS (
SELECT
	BP.COMP,
	bp.prime_a,
	jd,
	JSONB_BUILD_OBJECT(party,TO_CHAR(SUM(amtd),'999,999,999')) pjd,
	SUM(AMTD) AMTD
FROM 
	PA2
	INNER JOIN BP ON
		BP.PRIME_A = PA2.PRIME_A AND
		BP.COMP = PA2.COMP
GROUP BY
	BP.COMP,
	bp.prime_a,
	jd,
	party
)
--turn vendor totals into json per the prime_a
SELECT
	COMP,
	jsonb_pretty(prime_a) prime_a,
	jsonb_pretty(jd) jd,
	jsonb_pretty(tps.jsonb_concat_obj(pjd)) pjd,
	SUM(AMTD) AMTD
FROM
	PAP
GROUP BY	
	COMP,
	prime_a,
	jd
ORDER BY 
	prime_a ASC