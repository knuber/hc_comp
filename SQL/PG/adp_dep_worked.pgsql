\timing
--explain (analyze,  buffers)
SELECT
        cms_tb,
        elmt,
        cms_acct,
        substring(pay_date,1,4) payperd,
        sum(amount)
FROM
        PAYROLL.ADP_RP
        LEFT OUTER JOIN ( 
            VALUES 
                ('019300','Manufacturing spend - Labor'),
                ('019305','Manufacturing spend - Labor'),
                ('019307','Manufacturing spend - Labor'),
                ('019313','Manufacturing spend - Labor'),
                ('019325','Manufacturing spend - Labor'),
                ('029311','Manufacturing spend - Labor'),
                ('039306','Manufacturing spend - Labor'),
                ('079310','Manufacturing spend - Labor'),
                ('088004','Manufacturing spend - Labor'),
                ('088010','Manufacturing spend - Labor'),
                ('088014','Manufacturing spend - Labor'),
                ('089327','Manufacturing spend - Labor'),
                ('595920','Manufacturing spend - Labor'),
                ('088005','Manufacturing spend - OH'),
                ('088011','Manufacturing spend - OH'),
                ('088020','Manufacturing spend - OH'),
                ('088026','Manufacturing spend - OH'),
                ('019330','Manufacturing spend - OH'),
                ('019331','Manufacturing spend - OH'),
                ('019333','Manufacturing spend - OH'),
                ('019335','Manufacturing spend - OH'),
                ('019343','Manufacturing spend - OH'),
                ('019345','Manufacturing spend - OH'),
                ('019356','Selling - Distribution Expense'),
                ('019357','Selling - Distribution Expense'),
                ('019380','Manufacturing spend - OH'),
                ('019382','Manufacturing spend - OH'),
                ('019383','Manufacturing spend - OH'),
                ('029331','Manufacturing spend - OH'),
                ('039336','Manufacturing spend - OH'),
                ('056459','Selling - Distribution Expense'),
                ('066570','G&A Expenses'),
                ('066571','G&A Expenses'),
                ('066574','G&A Expenses'),
                ('069363','Selling - Distribution Expense'),
                ('079340','Manufacturing spend - OH'),
                ('088032','Manufacturing spend - OH'),
                ('088043','Manufacturing spend - OH'),
                ('088050','Selling - Distribution Expense'),
                ('088051','Selling - Distribution Expense'),
                ('088082','Manufacturing spend - OH'),
                ('088084','Manufacturing spend - OH'),
                ('088094','Manufacturing spend - OH'),
                ('089337','Manufacturing spend - OH'),
                ('096570','G&A Expenses'),
                ('099370','G&A Expenses'),
                ('099371','G&A Expenses'),
                ('099374','G&A Expenses'),
                ('099391','G&A Expenses'),
                ('099392','G&A Expenses'),
                ('099393','G&A Expenses'),
                ('099394','G&A Expenses'),
                ('099398','G&A Expenses'),
                ('595943','Manufacturing spend - OH'),
                ('595956','Selling - Distribution Expense'),
                ('595980','Manufacturing spend - OH'),
                ('931032','Manufacturing spend - OH')
        ) dep(adpd,elmt) ON
                adpd = adp_dep_worked
WHERE
        pay_date >= '160401'
GROUP BY
        cms_tb,
        elmt,
        cms_acct,
        substring(pay_date,1,4)
