SELECT
        adp_dep_worked,
        SUBSTRING(cms_acct,7,4) prime,
        sum(amount)
FROM
        PAYROLL.ADP_RP
WHERE
        pay_date >= '160401'
GROUP BY
        adp_dep_worked,
        SUBSTRING(cms_acct,7,4)
ORDER BY
        adp_dep_worked,
        SUBSTRING(cms_acct,7,4);