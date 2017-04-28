\timing
explain (analyze,  buffers)
SELECT
        cms_tb,
        gl_dep,
        SUBSTRING(cms_acct,7,4) prime,
        sum(amount)
FROM
        PAYROLL.ADP_RP
WHERE
        pay_date >= '160401'
GROUP BY
        cms_tb,
        gl_dep,
        SUBSTRING(cms_acct,7,4)
ORDER BY
        cms_tb,
        gl_dep,
        SUBSTRING(cms_acct,7,4);