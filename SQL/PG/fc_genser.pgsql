\timing
SET WORK_MEM = 250000;
--EXPLAIN (ANALYZE, BUFFERS)
WITH
    chgs(reason, party, idat, fbasis) AS (
        SELECT  
            c.reason,
            c.party,
            gs.idat,
            to_char(gs.idat,c.fcst_basis) fbasis
        FROM    
            fc.chan c
            LEFT JOIN LATERAL generate_series(current_date,current_date + INTERVAL '15 months', c.frequency) gs(idat) ON TRUE
    )
SELECT * FROM chgs LIMIT 1000;