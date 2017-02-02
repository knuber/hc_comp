
SELECT
	X.COMP, X.VCHR, X.PPVACCT, X.PPV, X.CNT, X.TOT, LBRKEY, LBPT#, LBEXT, LBCOM#||Y1PRVR PPVACCT, LBPPV, 
	CASE X.PPV 
		WHEN 0 THEN 
			CASE X.TOT
				WHEN 0 THEN FLOAT(1)/FLOAT(X.CNT)
				ELSE LBEXT/X.TOT 
			END
		ELSE LBPPV/X.PPV
	END PPV_DET
FROM	
	LGDAT.POMVAR
	LEFT OUTER JOIN LGDAT.STKMM ON
		AVPART = LBPT#
	LEFT OUTER JOIN LGDAT.STKMP ON
		AWPART = LBPT#
	LEFT OUTER JOIN LGDAT.GLIE ON
		Y1PLNT = LBPLNT AND
		Y1GLEC = COALESCE(AVGLED, AWGLED)
	LEFT OUTER JOIN
	(
		SELECT
			LBCOM# COMP, LBVCH# VCHR, LBCOM#||Y1PRVR PPVACCT, SUM(LBPPV) PPV, COUNT(LBRKEY) CNT, SUM(LBEXT) TOT
		FROM	
			LGDAT.POMVAR
			LEFT OUTER JOIN LGDAT.STKMM ON
				AVPART = LBPT#
			LEFT OUTER JOIN LGDAT.STKMP ON
				AWPART = LBPT#
			LEFT OUTER JOIN LGDAT.GLIE ON
				Y1PLNT = LBPLNT AND
				Y1GLEC = COALESCE(AVGLED, AWGLED)
		WHERE
			LBFSYY = 16 AND
			LBFSPP = 4 AND
			LBPT# <> '' AND
			LBSCST <> .00001
		GROUP BY
			LBCOM#, LBVCH#, LBCOM#||Y1PRVR
	) X ON
		X.COMP = LBCOM# AND	
		X.VCHR = LBVCH# AND
		X.PPVACCT = LBCOM#||Y1PRVR
WHERE
	LBFSYY = 16 AND
	LBFSPP = 4 AND
	LBPT# <> '' AND
	LBSCST <> .00001
FETCH FIRST 200 ROWS ONLY