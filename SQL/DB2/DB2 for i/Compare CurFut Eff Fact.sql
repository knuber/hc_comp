SELECT 
	F.AODEPT,
	F.AORESC,
	F.AOEFF, 
	C.AOEFF,
	COUNT(*)
FROM 
	LGDAT.FUTHDR F
	INNER JOIN LGDAT.STKA ON
		V6PART = F.AOPART AND
		V6PLNT = F.AOPLNT
	LEFT OUTER JOIN LGDAT.METHDR C ON
		C.AOPART = F.AOPART AND
		C.AOPLNT = F.AOPLNT AND
		C.AOSEQ# = F.AOSEQ#
WHERE
	V6STAT = 'A'
GROUP BY
	F.AOEFF, 
	F.AODEPT,
	F.AORESC,
	C.AOEFF
ORDER BY 
	AODEPT ASC