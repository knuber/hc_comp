WITH
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
	),
	FRTC (
		vendor,
		invoice_date,
		due_date,
		vchr_date,
		check_date,
		checkn,
		amount
	)
	AS
	(
		SELECT
			rec->>'Carrier' vendor,
			(rec->>'Inv Dt')::date Invoice_date, 
			(rec->>'Pay Dt')::date due_date,
			(rec->>'Pay Dt')::date vchr_date,
			(rec->>'Pay Dt')::date check_date,
			(rec->>'Chk#')::numeric checkn,
			(rec->>'Pd Amt')::numeric amount
		FROM
			tps.trans
		WHERE
			srce = 'WMPD'
	)
SELECT
	'FREIGHT' FGRP_DESCR,
	'FREIGHT' FUNC_AREA,
	VENDOR,
	INVOICE_DATE,
	DUE_DATE,
	VCHR_DATE,
	CHECK_DATE,
	BANK.AODATE,
	frtc.checkn,
	SUM(frtc.amount) BAMOUNT,
	'OPEN FREIGHT CHECKS' SRCE
FROM
	FRTC
	LEFT JOIN BANK ON
		BANK.CHECKN = FRTC.CHECKN
WHERE
	AODATE IS NULL
GROUP BY
	VENDOR,
	INVOICE_DATE,
	DUE_DATE,
	VCHR_DATE,
	CHECK_DATE,
	BANK.AODATE,
	frtc.checkn
ORDER BY
	INVOICE_DATE DESC




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