SELECT 
	PAY_DATE,
	PMNT,
	CASE X.JRNLT WHEN 'PRIMAR' THEN CODE ELSE 'TOTALS' END CODE,
	SUBSTR(CASE x.jrnlt WHEN 'PRIMAR' THEN r.cms_acct ELSE COALESCE(r.cms_tb, '00') || '0000101002' END, 7, 6) acct,
	SUM(r.amount * CASE x.jrnlt WHEN 'PRIMAR'::text THEN '-1'::integer ELSE 1 END::numeric) FILTER (WHERE ADP_COMP = 'B3X') B3X,
	SUM(r.amount * CASE x.jrnlt WHEN 'PRIMAR'::text THEN '-1'::integer ELSE 1 END::numeric) FILTER (WHERE ADP_COMP = 'UDV') UDV,
	SUM(r.amount * CASE x.jrnlt WHEN 'PRIMAR'::text THEN '-1'::integer ELSE 1 END::numeric) FILTER (WHERE ADP_COMP = 'U7H') U7H,
	SUM(r.amount * CASE x.jrnlt WHEN 'PRIMAR'::text THEN '-1'::integer ELSE 1 END::numeric) FILTER (WHERE ADP_COMP = 'U7J') U7J,
	SUM(r.amount * CASE x.jrnlt WHEN 'PRIMAR'::text THEN '-1'::integer ELSE 1 END::numeric) FILTER (WHERE ADP_COMP = 'U7C') U7C,
	SUM(r.amount * CASE x.jrnlt WHEN 'PRIMAR'::text THEN '-1'::integer ELSE 1 END::numeric) FILTER (WHERE ADP_COMP = 'U7E') U7E
FROM 
	payroll.adp_rp r
	INNER JOIN payroll.adp_code c on
		r.gl_descr::text = c.code::text AND 
		r.prim_offset::text = c.po::text
	CROSS JOIN (VALUES('PRIMAR'::text, 'OFFSET'::text)) x(jrnlt)
	
WHERE 
	r.gl_descr::text = c.code::text AND 
	r.prim_offset::text = c.po::text AND 
	r.pay_date >= '170301' and
	r.pay_date <= '170331' and
	(c.pmnt::text = ANY (ARRAY['ADP_TAX'::character varying::text, 'PRINCIPAL_401K'::character varying::text, 'ADP_GARNISHMENTS'::character varying::text]))
GROUP BY 
	PAY_DATE,
	PMNT,
	CASE X.JRNLT WHEN 'PRIMAR' THEN CODE ELSE 'TOTALS' END,
	SUBSTR(CASE x.jrnlt WHEN 'PRIMAR' THEN r.cms_acct ELSE COALESCE(r.cms_tb, '00') || '0000101002' END, 7, 6)
ORDER BY
	PAY_DATE ASC,
	PMNT ASC;
