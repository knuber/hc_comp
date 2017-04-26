forecasting cash flows, balance sheet, collateral, and loan balances
====================================================================

bucket all activity according to unique ledger patterns. label the pattern.

each economic event will then need to implement the forecasted ledger behavior
* which accounts to use

* timing between events 

        handling in bleed-off schedule?
        forecast each expense account or high-level forecast?

* attachment to drivers

        can setup fixed schedules where drivers don't make sense?

    forecasted drivers
    * fpv
    * eh
    * total spend
    * absorption
    * prior period/year?
    * historic holding period
    * historic schedule

* incur frequency

        generate_series will spool out an incursion basis but the connection to 
        the forecast basis (daily incursion versus a single monthly forecast) is not clear. 
        need to have a ratio of frequency to forecast basis 
        to pro-rata allocate

        logic needs to be in place such that if there is an open ap balance for somethingn that
        only incurs once per month, don't forecast anymore for that month.
                -> is it already incured in the target range?

* forecast time period basis

explore
---
* interval -> use to drive series generation
* range type -> use to define forecast and incursion ranges

        range type may incur some performance issues, convert to a text label for a range if necessary

building out a table with tsrange and 1M rows takes 8 sec
indexing a tsrange column of 1M rows takes 33 sec


**forecast**
`fc.fcst`

| driver        | fcst range    | amount        |version        |
|---------------|---------------|---------------|---------------|
|fpv            |[1/1-2/1)      |10,000,000     |               |
|fpv            |[2/1-3/1)      |10,000,000     |               |
|emh            |[1/1-2/1)      |500,000        |               |
|emh            |[2/1-3/1)      |475,000        |               |

        a manual load

**event master**
`fc.evnt`

| flow name     |  gl pattern   |  frequency    |forecast       |relation       |version        |
|---------------|---------------|---------------|---------------|---------------|---------------|
|raw mat        |incur-pay-clear|-              | fpv           |.5             |               |
|fg prepay      |incur pay clear relcass|-      | fpv           |.1             |               |

        lose the gl pattern column and rely on specific implementation below?

**participation**
`fc.party`

| flow name     | vendor        | split         | range                 | frequency  |
|---------------|---------------|---------------|-----------------------|------------|
|rawmat         |i. stern       |.50            |[1/1/01, 12/31/20]     | 1 days     |
|rawmat         |trademark      |.50            |[1/1/01, 12/31/20]     | 3 days     |

        add a column for range? yes. default to wide, but will be available if needs split
        this will MANDATE consideration in the join logic

**vendor schedule** 
`fc.schd`

| flow name     | party         | gl action     | sequence      | interval      |
|---------------|---------------|---------------|---------------|---------------|
|rawmat         |i. stern       |recpt          |1              | 0 days        |
|rawmat         |i. stern       |voucher        |2              | 5 days        |
|rawmat         |i. stern       |pay            |3              | 45 days       |
|rawmat         |i. stern       |clear          |4              | 7 days        |
|rawmat         |i. stern       |borrow         |5              | 0 days        |

        **the interval shoudl be total not incremental**

        do we really need the flow name column? wouldn't this be strictly vendor behaviour?
        need to be able to snap the pay date to a schedule of check run dates that includes holding AP
        
        what to do about amortization schedules?

**valuation**
`fc.dble`

| flow name     | party         | gl action     | flag          | account       | sign  | % total       |
|---------------|---------------|---------------|---------------|---------------|-------|---------------|
|rawmat         |i. stern       |recpt          |debit          | 1200-00       |1      |.95            |
|rawmat         |i. stern       |recpt          |debit          | 6502-00       |1      |.05            |
|rawmat         |i. stern       |recpt          |credit         | 2004-00       |-1     |1              |       
|rawmat         |i. stern       |voucher        |debit          | 2004-00       |-1     |1              |
|rawmat         |i. stern       |voucher        |credit         | 2000-00       |-1     |1              |
|rawmat         |i. stern       |pay            |debit          | 2000-21       |1      |1              |
|rawmat         |i. stern       |pay            |credit         | 2000-99       |-1     |1              |
|rawmat         |i. stern       |clear          |debit          | 2000-21       |1      |1              |
|rawmat         |i. stern       |clear          |credit         | 1010-01       |-1     |1              |
|rawmat         |i. stern       |revolver       |debit          | 1010-01       |1      |1              |
|rawmat         |i. stern       |revolver       |credit         | 3000-01       |-1     |1              |


        do we need a column for `gl_pattern` if a vendor has mutliple patterns involved?

        there are 2k flow/vendor combinations and that doesn't include any customer info

        this table could be built and static or the logic coudl be live but that requires more tables import cms tables?
                a static table build out would facilitate using logic eventually wihtout needing it right now

### will need to look at adding a location/entity identifier (**done**)

the party table shoudl convert from account to party.that evnt table should convert from whatever the forecast spend level is to the account level. 

This could be different for different areas. (plant spend versus general twinsburg spend number)

Populate Data Tasks
* frequency of incur by party
    1. copy vchr to postgres
    2. cust aggregate to get average between dates, or get sample range and count of vouchers in that range
    3. if re-cur on regular basis, need to determine maybe week of month and exclude forecasting if this has occured
* timing receipt to voucher
* time to pay, or hold time (voucher to check)
   1. select vouchers where last date has a balance of 0
* check oustanding time
* need to understand how many flows per vendor

Should there be a separate event for receipt versus voucher? yes

                Sometimes a new account is involved at voucher time like inbound freight.
                Modeling this kind of spend and matching forecasted P&L totals is going to be difficule
                could simply ignore this and treat it as a separate invoice with it's own pay schedule
                this could be done for PPV but only if the timing is identical to the offset entry

                could join the dble table to the allocated forecast. would need to ensure that all GL have a match in the dble
                aligning split to account must be managed such that all split out accounts have a match in each vendor's schedule
                maybe setup the vendor schedules first and then split to those accounts

How to setup initial dble?
should only be activity that ends with cash?

intial incur from hist? look at APVN accounts and just substitute for 2004 if necessary
payroll entry
withholding relief


forecast level -> 2 digit department 4 digits P&L

new idea
------------

1. use flows to first split forecast drivers to vendor
2. then use GL patterns to implement whatever forecast accounts they have to work with
    * I guess this assumes that the forecast element is an account lol
        * if not the flow must exclusively flow the driver 100% with no overlap with other flows
        * flows are in a tree or graph?
        * assign forecasted items to a flow-tree entry point and the allocation is a the leaf nodes?
        
another new idea
==========
1. a flow has claims on forecasted elements so as to ensure complete allocation
2. the flow then has participants with their own timing characteristics
3. the flow also exposes several possible gl patterns that the particpants can singularly use
    * examples
        * 3-way voucher, 2-way voucher, voucher
        * check, ach, wire
        * prepaid, manual journal, etc.
    * the available forecast elements and flows must fully reconcile to the forecasted P&L
        * the graph could be implemented here to more narrow channels, but this requires more work building splits & baselines?
            * splits really could be very generic, say 6 months
            * baselines woudl be more difficult because it requires
            * the problem with a graph is that it is 100% variable, need to implement some fixed components
        * another approach is to split tasks and have a seperate logic that produces a granular forecast
            * they just need to run in sync

**forecast**
`fc.fcst`

| driver        | fcst range    | amount        |version        |loc    |
|---------------|---------------|---------------|---------------|-------|
|fpv            |[1/1-2/1)      |10,000,000     |               |       |
|fpv            |[2/1-3/1)      |10,000,000     |               |       |
|emh            |[1/1-2/1)      |500,000        |               |       |
|emh            |[2/1-3/1)      |475,000        |               |       |

        a manual load

**event master**
`fc.claim`

| flow          |  element      |  claim        |location       |verions        |
|---------------|---------------|---------------|---------------|---------------|
|rawmat         |RMACT          |1              | SPARKS        |2018B          |
|rawmat         |RMSTD          |1              | SPARKS        |2018B          |
|rawmat         |PPV            |1              | SPARKS        |2018B          |



**participation**
`fc.party`

| flow          | party         | split         | range                 | schedule      |frequency | location   | version       |
|---------------|---------------|---------------|-----------------------|---------------|----------|------------|---------------|
|rawmat         |i. stern       |.50            |[1/1/01, 12/31/20]     | MATCH-CHECK   | 1 days   |            |               |
|rawmat         |trademark      |.50            |[1/1/01, 12/31/20]     | NOPO-ACH      | 3 days   |            |               |

        does this range need to be narrower than the forecast period?

**vendor schedule** 
`fc.schd`

| party         | sched         | gl action     | sequence      | interval      | range                 | location      | versions      |
|---------------|---------------|---------------|---------------|---------------|-----------------------|---------------|---------------|
|i. stern       | MATCH-CHECK   |recpt          |1              | 0 days        |[1/1/01, 12/31/20]     |               |               |
|i. stern       | MATCH-CHECK   |voucher        |2              | 5 days        |[1/1/01, 12/31/20]     |               |               |
|i. stern       | MATCH-CHECK   |pay            |3              | 45 days       |[1/1/01, 12/31/20]     |               |               |
|i. stern       | MATCH-CHECK   |clear          |4              | 7 days        |[1/1/01, 12/31/20]     |               |               |
|i. stern       | MATCH-CHECK   |borrow         |5              | 0 days        |[1/1/01, 12/31/20]     |               |               |

        - the interval is going to have to be cumulative
        - each party will have to implement it's pattern
        - each amortization schedule will have to have it's own pattern
        - should there be a schedule master or does it really matter? 

**gl patern**
`fc.patt`

| flow name     | sched         |gl action     | flag          | account       | sign  | factor        | element       | 
|---------------|---------------|---------------|---------------|---------------|-------|---------------|---------------|
|rawmat         | MATCH-CHECK   |recpt          |debit          | 1200-00       |1      |1              |RMSTD          |
|rawmat         | MATCH-CHECK   |recpt          |debit          | 6502-00       |1      |1              |PPV            |
|rawmat         | MATCH-CHECK   |recpt          |credit         | 2004-00       |-1     |1              |RMACT          |
|rawmat         | MATCH-CHECK   |voucher        |debit          | 2004-00       |1      |1              |RMACT          |
|rawmat         | MATCH-CHECK   |voucher        |credit         | 2000-00       |-1     |1              |RMACT          |
|rawmat         | MATCH-CHECK   |pay            |debit          | 2000-21       |1      |1              |RMACT          |
|rawmat         | MATCH-CHECK   |pay            |credit         | 2000-99       |-1     |1              |RMACT          |
|rawmat         | MATCH-CHECK   |clear          |debit          | 2000-21       |1      |1              |RMACT          |
|rawmat         | MATCH-CHECK   |clear          |credit         | 1010-01       |-1     |1              |RMACT          |
|rawmat         | MATCH-CHECK   |revolver       |debit          | 1010-01       |1      |1              |RMACT          |
|rawmat         | MATCH-CHECK   |revolver       |credit         | 3000-01       |-1     |1              |RMACT          |