SELECT
	VERSION,
	CHAN,
	GEO,
	ACCOUNT,
	GLEC,
	COALESCE(R.REPP,SPECIAL_SAUCE_REP) CUSTOM_REP,
	SUBSTR(DIGITS(YEAR(B_ORDERDATE)),9)||SUBSTR(DIGITS(MONTH(B_ORDERDATE)),9) ORDERDATE,
	SUBSTR(DIGITS(YEAR(B_REQUESTDATE)),9)||SUBSTR(DIGITS(MONTH(B_REQUESTDATE)),9) REQUESTDATE,
	SUBSTR(DIGITS(YEAR(B_SHIPDATE)),9)||SUBSTR(DIGITS(MONTH(B_SHIPDATE)),9) SHIPDATE,
	SUM(VALUE_LOCAL*CASE R_CURRENCY WHEN 'CA' THEN .75 ELSE 1 END) REVENUE_USD,
	SUM(QTY*COALESCE(CGSTCS, CHSTCS, Y0STCS)*CASE C_CURRENCY WHEN 'CA' THEN .75 ELSE 1 END) SCOGS_CUR_USD,
	SUM(QTY*COALESCE(CNSTCS, COSTCS, Y3STCS)*CASE C_CURRENCY WHEN 'CA' THEN .75 ELSE 1 END) SCOGS_FUT_USD
FROM
	QGPL.FFOTEST
	LEFT OUTER JOIN LGDAT.ICSTP ON
		CHPART = PART AND
		CHPLNT = PLNT
	LEFT OUTER JOIN LGDAT.ICSTM ON
		CGPART = PART AND
		CGPLNT = PLNT
	LEFT OUTER JOIN LGDAT.ICSTR ON
		Y0PART = PART AND
		Y0PLNT = PLNT
	LEFT OUTER JOIN LGDAT.FTCSTP ON
		COPART = PART AND
		COPLNT = PLNT
	LEFT OUTER JOIN LGDAT.FTCSTM ON
		CNPART = PART AND
		CNPLNT = PLNT
	LEFT OUTER JOIN LGDAT.FTCSTR ON
		Y3PART = PART AND
		Y3PLNT = PLNT
	LEFT OUTER JOIN 
	(
		SELECT
			MN.GRP ||' - ' ||DESCR DIRECTOR,
			LTRIM(RTRIM(A9)) RCODE,
			LTRIM(RTRIM(A9)) ||' - ' ||A30 REPP
		FROM
			LGDAT.CODE
			INNER JOIN 
			(
				SELECT
					MI.GRP, 
					MI.CODE,
					A30 DESCR
				FROM
					(
						SELECT 
							SUBSTR(LTRIM(RTRIM(A9)),1,3) GRP,
							MIN(A9) CODE
						FROM
							LGDAT.CODE
						WHERE
							A2 = 'MM'
						GROUP BY
							SUBSTR(LTRIM(RTRIM(A9)),1,3)
					)MI
					INNER JOIN LGDAT.CODE ON
						A2 = 'MM' AND
						A9 = CODE
			) MN ON
				GRP = SUBSTR(LTRIM(RTRIM(A9)),1,3)
		WHERE
			A2 = 'MM'
	) R ON
		R.RCODE = SPECIAL_SAUCE_REP
WHERE
	SUBSTR(GLEC,1,1) IN ('1','2') AND
	COALESCE(B_SHIPDATE,CAST('2001-01-01' AS DATE)) >= CAST('2017-03-01' AS DATE)
	--NOT (STATUS = 'CLOSED' AND	INVOICE IS NULL)
GROUP BY
	VERSION,
	CHAN,
	GEO,
	ACCOUNT,
	GLEC,
	SUBSTR(DIGITS(YEAR(B_ORDERDATE)),9)||SUBSTR(DIGITS(MONTH(B_ORDERDATE)),9),
	SUBSTR(DIGITS(YEAR(B_REQUESTDATE)),9)||SUBSTR(DIGITS(MONTH(B_REQUESTDATE)),9),
	SUBSTR(DIGITS(YEAR(B_SHIPDATE)),9)||SUBSTR(DIGITS(MONTH(B_SHIPDATE)),9)
ORDER BY
	VERSION,
	CHAN,
	GEO,
	ACCOUNT,
	GLEC,
	SUBSTR(DIGITS(YEAR(B_ORDERDATE)),9)||SUBSTR(DIGITS(MONTH(B_ORDERDATE)),9),
	SUBSTR(DIGITS(YEAR(B_REQUESTDATE)),9)||SUBSTR(DIGITS(MONTH(B_REQUESTDATE)),9),
	SUBSTR(DIGITS(YEAR(B_SHIPDATE)),9)||SUBSTR(DIGITS(MONTH(B_SHIPDATE)),9)