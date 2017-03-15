\timing
--EXPLAIN (ANALYZE, BUFFERS)
SELECT  
    *
FROM
    (
        SELECT
            (rec->>'AsOfDate')::Date asofdate,
            CHK[1] checkn,
            (rec->>'Amount')::numeric amount
        FROM
            tps.trans 
            LEFT JOIN LATERAL regexp_matches(rec->>'Reference','([^''0].*)') CHK ON TRUE
        WHERE
            srce = 'PNCC' AND
            rec @> '{"Transaction":"Checks Paid","AccountName":"The HC Operating Company OPERA"}'::jsonb
    ) CL
WHERE
    LENGTH(checkn) <> 8