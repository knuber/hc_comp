\timing
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
--WHERE
--	AODATE IS NULL
GROUP BY
	VENDOR,
	INVOICE_DATE,
	DUE_DATE,
	VCHR_DATE,
	CHECK_DATE,
	BANK.AODATE,
	frtc.checkn
ORDER BY
	check_date DESC