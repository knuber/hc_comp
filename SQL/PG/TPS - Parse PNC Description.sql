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
	custid[1],
	adp_comp[1],
	sec[1],
	descr[1],
	discr[1],
	dat[1],
	tim[1],
	chk[1],
	adde[1],
	curr[1] cd1,
	curr[3] cd2,
	curr[2] cr1,
	curr[4] cr2,
	acct.rv[1] ac1,
	acct.rv[2] ac2
	
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
	LEFT JOIN LATERAL regexp_matches(rec->>'Description','Cust ID:(.+?)(?=$|\w+?:)') custid ON TRUE
	LEFT JOIN LATERAL regexp_matches(rec->>'Description','Cust ID:.*?(B3X|UDV|U7E|U7C|U7H|U7J).*?(?=$|\w+?:)') adp_comp ON TRUE
	LEFT JOIN LATERAL regexp_matches(rec->>'Description','SEC:(.+?) Cust') sec ON TRUE
	LEFT JOIN LATERAL regexp_matches(rec->>'Description','Desc:(.+?) Comp') descr ON TRUE
	LEFT JOIN LATERAL regexp_matches(rec->>'Description','Discr:(.+?)(?=$| SEC:|\w+?:)') discr ON TRUE
	LEFT JOIN LATERAL regexp_matches(rec->>'Description','([\w].*?)(?=$| -|\s[0-9].*?|\s[\w/]+?:)') ini ON TRUE
	LEFT JOIN LATERAL regexp_matches(rec->>'Reference','([^''0].*)','g') CHK ON TRUE
	LEFT JOIN LATERAL regexp_matches(rec->>'Description','Addenda:(.+?)(?=$|\w+?:)') adde ON TRUE
	LEFT JOIN LATERAL regexp_matches(rec->>'Description','.*(DEBIT|CREDIT).*(USD|CAD).*(DEBIT|CREDIT).*(USD|CAD).*') curr ON TRUE
	LEFT JOIN LATERAL regexp_matches(rec->>'Description','AC/(\w* ).*AC/(\w* )') acct(rv) ON TRUE
WHERE
	srce = 'PNCC'
order by ini[1] asc
LIMIT 1000
