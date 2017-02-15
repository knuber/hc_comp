
SELECT 
	u.srce,
	u.unq,
	tps.jsonb_concat_obj(u.retval||coalesce(v.map,'{}'::jsonb)) comb
FROM 	
	--re-aggregate return values and explude any records where one or more regex failed with a null result
	(
	SELECT 
		x.srce,
		x.target,
		x.unq, 
		tps.jsonb_concat_obj(x.rkey) rkey,
		tps.jsonb_concat_obj(x.retval) AS retval,
		x.seq
	FROM 
		--unwrap json instruction and apply regex using a count per original line for re-aggregation
		( 
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
		ORDER BY 
			m.srce, 
			m.seq,
			m.target, 
			t.unq, 
			e.rn
		) x
	GROUP BY 
		x.srce, 
		x.target, 
		x.unq,
		x.seq
		
	) u
	LEFT OUTER JOIN tps.map_rv v ON
		v.target = u.target AND
		v.srce = u.srce AND
		v.retval <@ u.retval
GROUP BY
	u.srce,
	u.unq
