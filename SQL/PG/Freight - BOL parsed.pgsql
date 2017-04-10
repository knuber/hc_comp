
SELECT 
    rs.*,
    r.x, 
    r.rn
FROM
    tps.trans 
    JOIN LATERAL JSONB_POPULATE_RECORD(null::tps.tms,rec) rs ON TRUE
    JOIN LATERAL REGEXP_MATCHES(rec->>'Order Number(s)',$$[0-9]{5,}$$,'g') WITH ORDINALITY r(x, rn) ON TRUE
WHERE   
    srce = 'TMS'
LIMIT 1

--SELECT jr.* FROM tps.trans left join lateral jsonb_populate_record(null::tps.tms,rec) jr ON TRUE LIMIT 10