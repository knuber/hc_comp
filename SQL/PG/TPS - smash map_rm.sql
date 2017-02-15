SELECT 
	srce, 
	target,
	w.*,
	s.*
FROM 
	TPS.MAP_RM
	JOIN LATERAL jsonb_to_record(regex) as x(defn jsonb, type text, "where" jsonb) ON TRUE
	JOIN LATERAL jsonb_to_recordset(x.where) as w("Transaction" text) ON TRUE
	JOIN LATERAL jsonb_to_recordset(x.defn) as s(key text, field text, regex text) ON TRUE