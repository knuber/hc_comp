
WITH 
	----------------ADP Checks-------------
	ADPC (
		adp_comp, 
		employee, 
		pay_date, 
		perdion_end, 
		checkn, 
		cms_acct, 
		amount
	) AS
	(
		SELECT
			adp_comp,
			employee,
			to_date(pay_date,'YYMMDD') pay_date, 
			period_end,
			checkn::numeric,
			cms_acct,
			amount
		FROM
			payroll.adp_rp 
		WHERE
			gl_descr = 'NET PAY'
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
			rec @> '{"Transaction":"Checks Paid","AccountName":"The HC Operating Company PAYR"}'::jsonb
		ORDER BY
			CHK[1]::numeric asc
	)
--------merge and get difference-------------
SELECT
	ADP_COMP,
	PAY_DATE,
	SUM(ADP+BANK) OVER (ORDER BY ADP_COMP, PAY_DATE),
	SUM(BANK) OVER (ORDER BY ADP_COMP, PAY_DATE)
FROM
	(
		SELECT
			ADP_COMP, 
			PAY_DATE, 
			SUM(AMOUNT) ADP,
			SUM(BAMOUNT) BANK
		FROM
			(
				SELECT
					ADPC.*,
					BANK.AODATE,
					BANK.AMOUNT BAMOUNT
				FROM
					ADPC
					LEFT JOIN BANK ON
							BANK.CHECKN = ADPC.CHECKN AND
							BANK.AMOUNT + ADPC.AMOUNT = 0
			) X
		GROUP BY	
			ADP_COMP,
			PAY_DATE
		ORDER BY
			ADP_COMP,
			PAY_DATE
	) S