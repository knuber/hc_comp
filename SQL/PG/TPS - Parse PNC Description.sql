select 
	unq,
	REC->>'Description' descr,
	rec->>'AccountName' acct,
	rec->>'Transaction' trans,
	ini[1],
	--bb.*,
	rfb[1],
	obi[1],
	ori[1],
	bene[1],
	compn[1],
	custn[1],
	sec[1],
	descr[1],
	discr[1],
	dat[1],
	tim[1]
from 
	tps.trans 
	--LEFT JOIN LATERAL regexp_matches(rec->>'Description','([\w/]+?):(.+?) [\w/]+?:','g') bb ON TRUE
	LEFT JOIN LATERAL regexp_matches(rec->>'Description','RFB:(.+?)(?=$|[\w/]+?:)') rfb ON TRUE
	LEFT JOIN LATERAL regexp_matches(rec->>'Description','OBI:(.+?) [A-Z]+?:') obi ON TRUE
	LEFT JOIN LATERAL regexp_matches(rec->>'Description','ORIGINATOR:(.+?) AC/') ori ON TRUE
	LEFT JOIN LATERAL regexp_matches(rec->>'Description','DATE:(\d+)') dat ON TRUE
	LEFT JOIN LATERAL regexp_matches(rec->>'Description','TIME:(\d+)') tim ON TRUE
	LEFT JOIN LATERAL regexp_matches(rec->>'Description','BENEFICIARY:(.+?) AC/\d*(.*?)\s[\w/]+?:') bene ON TRUE
	LEFT JOIN LATERAL regexp_matches(rec->>'Description','Comp Name:(.+?)(?=$| Comp|\w+?:)') compn ON TRUE
	LEFT JOIN LATERAL regexp_matches(rec->>'Description','Cust Name:(.+?)(?=$|\w+?:)') custn ON TRUE
	LEFT JOIN LATERAL regexp_matches(rec->>'Description','SEC:(.+?) Cust') sec ON TRUE
	LEFT JOIN LATERAL regexp_matches(rec->>'Description','Desc:(.+?) Comp') descr ON TRUE
	LEFT JOIN LATERAL regexp_matches(rec->>'Description','Discr:(.+?)(?=$| SEC:|\w+?:)') discr ON TRUE
	LEFT JOIN LATERAL regexp_matches(rec->>'Description','([\w].*?)(?=$| -|\s[0-9].*?|\s[\w/]+?:)') ini ON TRUE
WHERE
	srce = 'PNCC' AND
	rec->>'AsOfDate' >= '2016-10-01'
order by ini[1] asc
