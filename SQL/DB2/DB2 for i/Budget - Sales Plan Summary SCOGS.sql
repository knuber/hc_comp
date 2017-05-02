SELECT
	VERSION,
	SUBSTR(DIGITS(YEAR(B_SHIPDATE+ I_SHIPDATE DAYS)),9)||SUBSTR(DIGITS(MONTH(B_SHIPDATE + I_SHIPDATE DAYS)),9)||VERSION VERS_PERD,
	CHAN,
	GEO,
	ACCOUNT,
	GLEC,
	PLNT,
	STATEMENT_LINE,
	R_CURRENCY,
	C_CURRENCY,
	MAJG,
	MING,
	MAJS,
	MINS,
	--COALESCE(R.REPP,SPECIAL_SAUCE_REP) CUSTOM_REP,
	SUBSTR(DIGITS(YEAR(B_ORDERDATE + I_ORDERDATE DAYS)),9)||SUBSTR(DIGITS(MONTH(B_ORDERDATE + I_ORDERDATE DAYS)),9) ORDERDATE,
	SUBSTR(DIGITS(YEAR(B_REQUESTDATE + I_REQUESTDATE DAYS)),9)||SUBSTR(DIGITS(MONTH(B_REQUESTDATE + I_REQUESTDATE DAYS)),9) REQUESTDATE,
	SUBSTR(DIGITS(YEAR(B_SHIPDATE+ I_SHIPDATE DAYS)),9)||SUBSTR(DIGITS(MONTH(B_SHIPDATE + I_SHIPDATE DAYS)),9) SHIPDATE,
	FLAG,
	SUM(I_SHIPDATE) I_SHIPDATE,
	SUM(VALUE_LOCAL*CASE R_CURRENCY WHEN 'CA' THEN .75 ELSE 1 END) REVENUE_USD,
	SUM(QTY*COALESCE(CGSTCS, CHSTCS, Y0STCS, NPCOST)*CASE C_CURRENCY WHEN 'CA' THEN .75 ELSE 1 END) SCOGS_CUR_USD,
	SUM(QTY*COALESCE(CNSTCS, COSTCS, Y3STCS, NPCOST)*CASE C_CURRENCY WHEN 'CA' THEN .75 ELSE 1 END) SCOGS_FUT_USD
FROM
	QGPL.FFBS0403
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
		TABLE ( 
			VALUES
				('SIA20000E21C006LRTJU',3.676),
				('SIA12000E35C012LRTJF',0.879),
				('SIA20000E35C006LRTJR',3.676),
				('SIA12000E21C006LRTJI',0.879),
				('SIA12000A34C012LRTJH',0.879),
				('SIA12000E21C012LAH09',0.879),
				('SIA08000B91C024LRTIY',0.436),
				('SIA12000B91C012LRTJG',0.879),
				('SIA08000E21C024LRTJA',0.436),
				('SIA12000E21C012LRTJI',0.879),
				('SIA08000E35C024LRTIX',0.436),
				('SIA16000E35C012LRTJN',1.848),
				('SIA16000B91C012LRTJO',1.848),
				('SIA16000A34C012LRTJP',1.848),
				('SIA16000E35C012LAH32',1.848),
				('SIA08000A34C024LRTIZ',0.436),
				('SIA16000DC6C012LRBWI',1.848),
				('SIA20000DC6C006LRBWJ',3.676),
				('SIA20000A34C006LRTJT',3.676),
				('SIA16000A34C006LRTJP',1.848),
				('SIA16000E35C006LRTJN',1.848),
				('SIA16000E21C012LRTJQ',1.848),
				('SIA12000E35C006LJN76',0.879),
				('SIA12000BE4C006LJN75',0.879),
				('SIA20000B91C006LRTJS',3.676),
				('SIA20000E21E280',3.676),
				('SIA12000FA9C006LJN77',0.879),
				('SIA16000E22E280',1.848),
				('SIA20000E35E280',3.676),
				('SIA08000A42C024LRBXO',0.436),
				('SIA12000A42C012LRBXQ',0.879),
				('SIA16000A42C012LRBXS',1.848),
				('SIA20000A42C006LRBXT',3.676),
				('SIA16000E21E280',1.848),
				('SIA20000E22C006',3.676),
				('SIA08000DC6C006LJN85',0.436),
				('SIA12000E21E432',0.879),
				('SIA12000DC6C012LRBWG',0.879),
				('SIA12000E35C012LAH10',0.879),
				('SIA12000A42C012LAH46',0.879),
				('SIA16000A42C012LAH45',1.848),
				('SIA08000DC6C024LRBWE',0.436),
				('SIA20000E35C006',3.676),
				('SIA16000E24E280',1.848)
		) NP(NPPART, NPCOST) ON
			NPPART = PART

WHERE
	--SUBSTR(GLEC,1,1) IN ('1','2') AND
	COALESCE(B_SHIPDATE,CAST('2001-01-01' AS DATE)) >= CAST('2017-03-01' AS DATE)
	--NOT (STATUS = 'CLOSED' AND	INVOICE IS NULL)
GROUP BY
	VERSION,
	SUBSTR(DIGITS(YEAR(B_SHIPDATE+ I_SHIPDATE DAYS)),9)||SUBSTR(DIGITS(MONTH(B_SHIPDATE + I_SHIPDATE DAYS)),9)||VERSION,
	CHAN,
	GEO,
	ACCOUNT,
	GLEC,
	PLNT,
	STATEMENT_LINE,
	R_CURRENCY,
	C_CURRENCY,
	MAJG,
	MING,
	MAJS,
	MINS,
	SUBSTR(DIGITS(YEAR(B_ORDERDATE + I_ORDERDATE DAYS)),9)||SUBSTR(DIGITS(MONTH(B_ORDERDATE + I_ORDERDATE DAYS)),9) ,
	SUBSTR(DIGITS(YEAR(B_REQUESTDATE + I_REQUESTDATE DAYS)),9)||SUBSTR(DIGITS(MONTH(B_REQUESTDATE + I_REQUESTDATE DAYS)),9) ,
	SUBSTR(DIGITS(YEAR(B_SHIPDATE+ I_SHIPDATE DAYS)),9)||SUBSTR(DIGITS(MONTH(B_SHIPDATE + I_SHIPDATE DAYS)),9),
	FLAG

UNION ALL

SELECT
	VERSION,
	SALESMONTH||VERSION VERS_PERD,
	CHAN,
	GEO,
	ACCOUNT,
	GLEC,
	PLNT,
	STATEMENT_LINE,
	R_CURRENCY,
	C_CURRENCY,
	MAJG,
	MING,
	MAJS,
	MINS,
	--COALESCE(R.REPP,SPECIAL_SAUCE_REP) CUSTOM_REP,
	SUBSTR(DIGITS(YEAR(B_ORDERDATE + I_ORDERDATE DAYS)),9)||SUBSTR(DIGITS(MONTH(B_ORDERDATE + I_ORDERDATE DAYS)),9) ORDERDATE,
	SUBSTR(DIGITS(YEAR(B_REQUESTDATE + I_REQUESTDATE DAYS)),9)||SUBSTR(DIGITS(MONTH(B_REQUESTDATE + I_REQUESTDATE DAYS)),9) REQUESTDATE,
	SALESMONTH SHIPDATE,
	FLAG,
	SUM(I_SHIPDATE) I_SHIPDATE,
	SUM(VALUE_LOCAL*XR.RATE) REVENUE_USD,
	SUM(QTY*COALESCE(CGSTCS, CHSTCS, Y0STCS)*XC.RATE) SCOGS_CUR_USD,
	SUM(QTY*COALESCE(CNSTCS, COSTCS, Y3STCS)*XC.RATE) SCOGS_FUT_USD
FROM
	QGPL.FFBSHIST
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
	LEFT OUTER JOIN RLARP.FFCRET XC ON
		XC.PERD = SALESMONTH AND
		XC.RTYP = 'MA' AND
		XC.FCUR = C_CURRENCY AND
		XC.TCUR = 'US'
	LEFT OUTER JOIN RLARP.FFCRET XR ON
		XR.PERD = SALESMONTH AND
		XR.RTYP = 'MA' AND
		XR.FCUR = R_CURRENCY AND
		XR.TCUR = 'US'
WHERE
	SUBSTR(GLEC,1,1) IN ('1','2') --AND
	--COALESCE(B_SHIPDATE,CAST('2001-01-01' AS DATE)) >= CAST('2017-03-01' AS DATE)
	--NOT (STATUS = 'CLOSED' AND	INVOICE IS NULL)
GROUP BY
	VERSION,
	SALESMONTH||VERSION,
	CHAN,
	GEO,
	ACCOUNT,
	GLEC,
	PLNT,
	STATEMENT_LINE,
	R_CURRENCY,
	C_CURRENCY,
	MAJG,
	MING,
	MAJS,
	MINS,
	SUBSTR(DIGITS(YEAR(B_ORDERDATE + I_ORDERDATE DAYS)),9)||SUBSTR(DIGITS(MONTH(B_ORDERDATE + I_ORDERDATE DAYS)),9),
	SUBSTR(DIGITS(YEAR(B_REQUESTDATE + I_REQUESTDATE DAYS)),9)||SUBSTR(DIGITS(MONTH(B_REQUESTDATE + I_REQUESTDATE DAYS)),9),
	SALESMONTH,
	FLAG