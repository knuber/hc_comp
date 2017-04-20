\timing
SET MAX_PARALLEL_WORKERS_PER_GATHER = 8;
SET WORK_MEM = 250000;
EXPLAIN (ANALYZE, BUFFERS, VERBOSE)

------build temo table & populate--------------------
CREATE TEMP TABLE _t AS
SELECT  
    c.reason,
    c.party,
    gs.idat,
    ('['||gs.idat::text||','||(gs.idat + c.frequency)::text||')')::tsrange dayrange,
    c.frequency
    --to_char(gs.idat,c.fcst_basis) fbasis
FROM    
    fc.chan c
    LEFT JOIN LATERAL generate_series(date_trunc('month',CURRENT_TIMESTAMP),CURRENT_DATE + INTERVAL '15 months', c.frequency) gs(idat) ON TRUE;

-------build index-----------------------------
CREATE INDEX x ON _t USING GIST (dayrange);

-------final select----------------------------
SELECT 
	reason,
    x.t,
    x.p,
    
    round(SUM(
		ROUND(((extract(days from upper(_t.dayrange) - lower(_t.dayrange)) / extract(days from upper(x.t) - lower(x.t))) * x.p)::numeric,10)
	),5) allocated
FROM 
	_t 
    INNER JOIN (
        	VALUES
        		('[2017-06-01, 2017-06-30)'::tsrange, 1300),
        		('[2017-07-01, 2017-07-31)'::tsrange, 1250),
        		('[2017-08-01, 2017-08-31)'::tsrange, 1700),
        		('[2017-09-01, 2017-09-30)'::tsrange, 1650),
        		('[2017-10-01, 2017-10-31)'::tsrange, 900)
   	) x(t, p) ON
    	x.t @> _t.dayrange
GROUP BY
	reason,
    x.t,
    x.p;

--DROP TEMP TABLE _t;