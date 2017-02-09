WITH
	FRTC
	(
		checkn,
		carrier,
		pdate,
		amount
	) AS
	(
		SELECT 
			checkn,
			carrier,
			pdate, 
			sum(amount) amount
		FROM 
			freight.wm_paid
		GROUP BY
			checkn,
			carrier,
			pdate
		ORDER BY 
			checkn asc
	),
	--------------Bank Checks-----------------
	BANK (
		aodate,
		trans,
		acctn,
		refr,
		checkn,
		amount
	) AS
	(
		SELECT
			(rec->>'AsOfDate')::Date,
			rec->>'Transaction',
			rec->>'AccountName',
			rec->>'Reference',
			CHK[1]::numeric,
			(rec->>'Amount')::numeric
		FROM
			tps.trans 
			LEFT JOIN LATERAL regexp_matches(rec->>'Reference','([^''0].*)','g') CHK ON TRUE
		WHERE
			srce = 'PNCC' AND
			rec @> '{"Transaction":"Checks Paid","AccountName":"The HC Operating Company FREIG"}'::jsonb
		ORDER BY
			CHK[1]::numeric asc
	)
SELECT
	FRTC.*,
	BANK.AODATE,
	BANK.AMOUNT BAMOUNT
FROM
	FRTC
	LEFT JOIN BANK ON
			BANK.CHECKN = FRTC.CHECKN
ORDER BY
	PDATE DESC




/*
--------merge and get difference-------------
SELECT
	CARRIER,
	PDATE,
	SUM(FRT) OVER (ORDER BY CARRIER, PDATE) FRT,
	SUM(BANK) OVER (ORDER BY CARRIER, PDATE) BANK,
	SUM(FRT-BANK) OVER (ORDER BY CARRIER, PDATE)
	
FROM
	(
		SELECT
			CARRIER, 
			PDATE, 
			SUM(AMOUNT) FRT,
			SUM(BAMOUNT) BANK
		FROM
			(
				SELECT
					FRTC.*,
					BANK.AODATE,
					BANK.AMOUNT BAMOUNT
				FROM
					FRTC
					LEFT JOIN BANK ON
							BANK.CHECKN = FRTC.CHECKN
			) X
		GROUP BY	
			CARRIER,
			PDATE
		ORDER BY
			CARRIER,
			PDATE
	) S
ORDER BY PDATE DESC
*/

--select rec->>'AsOfDate', count(*) from tps.trans where srce = 'PNCC' group by rec->>'AsOfDate' order by  rec->>'AsOfDate' desc