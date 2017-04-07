SELECT
	trantype,
	ini,
	ledger,
	party, 
	reason,
	r."AsOfDate" asofdate,
	to_char(r."AsOfDate",'YYMM') perd,
	SUM(r."Amount" * m.sign) amount,
	jsonb_pretty(tps.jsonb_concat_arr(rec)) rec
FROM
	tps.trans
	LEFT JOIN LATERAL jsonb_populate_record(null::tps.trans_rec_tp, rec) r ON TRUE
	LEFT JOIN LATERAL jsonb_populate_record(null::tps.pncc_map, map) m ON TRUE
WHERE
	srce = 'PNCC'
GROUP BY
	trantype,
	ini,
	ledger,
	party, 
	reason,
	r."AsOfDate"
ORDER BY
	trantype,
	ini,
	r."AsOfDate"