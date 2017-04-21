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
| driver        | fcst range    | amount        |
|---------------|---------------|---------------|
|fpv            |[1/1-2/1)      |10,000,000     |
|fpv            |[2/1-3/1)      |10,000,000     |
|emh            |[1/1-2/1)      |500,000        |
|emh            |[2/1-3/1)      |475,000        |

        a manual load

**event master**

| flow name     |  gl pattern   |  frequency    |forecast       |relation       |
|---------------|---------------|---------------|---------------|---------------|
|raw mat        |incur-pay-clear|-              | fpv           |.5             |
|fg prepay      |incur pay clear relcass|-      | fpv           |.1             |

        lose the gl pattern column and rely on specific implementation below?

**participation**
| flow name     | vendor        | split         |
|---------------|---------------|---------------|
|raw_mat        |i. stern       |.50            |
|raw_mat        |trademark      |.50            |

        is this singular or defined per period?

**vendor schedule** 
| flow name     | party         | gl action     | sequence      | interval      |
|---------------|---------------|---------------|---------------|---------------|
|raw_mat        |i. stern       |incur          |1              | 0 days        |
|raw_mat        |i. stern       |pay            |2              | 60 days       |
|raw_mat        |i. stern       |clear          |3              | 20 days       |
|raw_mat        |i. stern       |borrow         |4              | 0 days        |

        do we really need the flow name column? wouldn't this be strictly vendor behaviour?
        need to be able to snap the pay date to a schedule of check run dates that includes holding AP


**valuation**
| flow name     | party         | gl action     | flag          | account       | sign  |
|---------------|---------------|---------------|---------------|---------------|-------|
|raw_mat        |i. stern       |incur          |debit          | 7000-00       |1      |
|raw_mat        |i. stern       |incur          |credit         | 2000-21       |-1     |
|raw_mat        |i. stern       |pay            |debit          | 2000-21       |1      |
|raw_mat        |i. stern       |pay            |credit         | 2000-99       |-1     |
|raw_mat        |i. stern       |clear          |debit          | 2000-21       |1      |
|raw_mat        |i. stern       |clear          |credit         | 1010-01       |-1     |
|raw_mat        |i. stern       |revolver       |debit          | 1010-01       |1      |
|raw_mat        |i. stern       |revolver       |credit         | 3000-01       |-1     |


        do we need a column for `gl_pattern` if a vendor has mutliple patterns involved?

        there are 2k flow/vendor combinations and that doesn't include any customer info

        this table could be built and static or the logic coudl be live but that requires more tables import cms tables?
                a static table build out would facilitate using logic eventually wihtout needing it right now

        
