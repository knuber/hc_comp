SELECT  
    c.reason,
    c.party,
    gs.idat,
    to_char(gs.idat,c.fcst_basis) fst_basis
FROM    
    fc.chan c
    LEFT JOIN LATERAL generate_series(current_date,current_date + INTERVAL '15 months', c.frequency) gs(idat) ON TRUE
LIMIT 10;