
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
			SUM(amount)
		FROM
			payroll.adp_rp 
		WHERE
			gl_descr = 'NET PAY'
		GROUP BY
			adp_comp,
			employee,
			to_date(pay_date,'YYMMDD'),
			period_end,
			checkn::numeric,
			cms_acct
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
	ADPC.*,
	BANK.AODATE,
	BANK.AMOUNT BAMOUNT,
	SUM(coalesce(bank.amount,0) + coalesce(adpc.amount,0)) OVER () diff
FROM
	ADPC
	LEFT JOIN BANK ON
			BANK.CHECKN = ADPC.CHECKN AND
			BANK.AMOUNT + ADPC.AMOUNT = 0
WHERE
	BANK.AMOUNT IS NULL AND
	PAY_DATE NOT IN  ('2015-05-15','2015-05-29','2015-06-12','2015-06-26')
ORDER BY 
	PAY_DATE ASC


--SELECT * FROM tps.trans where rec->>'Reference' ~ '1008' order by unq asc
--SELECT * FROM payroll.adp_rp where checkn::numeric = 1008 order by cms_acct asc