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

**event master** _equates to fc.chnl_

|`flow_name`    | `gl_pattern`  | `frequency`   |
|---------------|---------------|---------------|

**forecast**            _how are these forecasts generated?_
|`flow_name`    |`fcst_range`   |`amount`       |
|---------------|---------------|---------------|

**gl pattern**
|`gl_pattern`   | `defn`        |
|---------------|---------------|

**participation**
|`flow_name`    |`vendor`       |`split`        |
|---------------|---------------|---------------|

**implement gl**
|`vendor`       |`flow_name`    |`gl_pattern`   |`implementation`       |`schedule`     |
|---------------|---------------|---------------|-----------------------|---------------|

**schedules**
|`vendor`       |`schedule`     |
|---------------|---------------|