SELECT 
	m.srce,
	m.target,
	t.unq,
	jsonb_build_object(
		e.v ->> 'key'::text,
		(t.rec -> (e.v ->> 'key'::text))
	) AS rkey,
	--array_to_json(mt.mt)::jsonb AS retval,
	jsonb_build_object(e.v->>'field',CASE WHEN array_upper(mt.mt,1)=1 THEN to_json(mt.mt[1]) ELSE array_to_json(mt.mt) END) retval,
	m.seq
FROM 
	tps.map_rm m
	LEFT JOIN LATERAL jsonb_array_elements(m.regex->'where') w(v) ON TRUE
	JOIN tps.trans t ON 
		t.srce = m.srce AND
		t.rec @> w.v
	LEFT JOIN LATERAL jsonb_array_elements(m.regex->'defn') WITH ORDINALITY e(v, rn) ON true
	LEFT JOIN LATERAL regexp_matches(t.rec ->> (e.v ->> 'key'::text), e.v ->> 'regex'::text) WITH ORDINALITY mt(mt, rn) ON true
WHERE
	t.map is null
ORDER BY 
	m.srce, 
	m.seq,
	m.target, 
	t.unq, 
	e.rn