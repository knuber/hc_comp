SELECT
	d.srce,
	d.target,
	d.retval,
	jsonb_agg(d.rec_key) rec_key,
	tps.jsonb_obj_agg_ignore_null(d.value_map) value_map,
	tps.jsonb_obj_agg_ignore_null(d.direct_map) direct_map,
	tps.jsonb_obj_agg_ignore_null(d.value_map) || tps.jsonb_obj_agg_ignore_null(d.direct_map) final_value_map
FROM
	--select only distinct records so that we only see unique trans records in the rec_key column
	(
	SELECT 
		u.target,
		u.retval retval,
		u.srce,
		u.rkey rec_key,
		v.map value_map,
		m.map direct_map
	FROM 	
		--re-aggregate return values and explude any records where one or more regex failed with a null result
		(
		SELECT 
			x.srce,
			x.target,
			x.unq, 
			tps.jsonb_obj_agg_null_atomic(x.rkey) rkey,
			tps.jsonb_obj_agg_null_atomic(x.retval) AS retval
		FROM 
			--unwrap json instruction and apply regex using a count per original line fro re-aggregation
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
				jsonb_build_object(e.v->>'field',array_to_json(mt.mt)) retval
			FROM 
				tps.map_rm m
				LEFT JOIN LATERAL jsonb_array_elements(m.regex->'where') w(v) ON TRUE
				JOIN tps.trans t ON 
					t.srce = m.srce AND
					t.rec @> w.v
				LEFT JOIN LATERAL jsonb_array_elements(m.regex->'defn') WITH ORDINALITY e(v, rn) ON true
				LEFT JOIN LATERAL regexp_matches(t.rec ->> (e.v ->> 'key'::text), e.v ->> 'regex'::text) mt(mt) ON true
			ORDER BY 
				m.srce, 
				m.target, 
				t.unq, 
				e.rn
			) x
		GROUP BY 
			x.srce, 
			x.target, 
			x.unq
		HAVING
			tps.jsonb_obj_agg_null_atomic(x.retval) IS NOT NULL
			
		) u
		LEFT OUTER JOIN tps.map_rv v ON
			v.target = u.target AND
			v.srce = u.srce AND
			v.retval = u.retval
		LEFT OUTER JOIN tps.map m ON
			m.srce = u.srce AND
			m.item = u.rkey
	GROUP BY 
		u.srce, 
		u.target, 
		u.retval,
		u.rkey,
		v.map,
		m.map
	ORDER BY 
		u.srce, 
		u.target, 
		u.retval
	) d
GROUP BY
	d.srce,
	d.target, 
	d.retval;