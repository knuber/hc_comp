functional balance sheet forecasting...
========================================

...mandates a complete double entry build-out

* that integrates with
    1. unvcouhered receipts (`PORCAP`)
    2. open ap (`OPEN`)
    3. open ap checks (`UCHQ`)
    4. open freight checks (not in CMS, but still represents a real draw on loan)
    5. open payroll (not in CMS, but still represents a real draw on loan)
    6. incurred items not yet booked (not in CMS, but still represents a real draw on loan)
* includes all work flows (capital, payroll, prepaid amortization, prepaid inventory, etc.)
* is quickly updated with some top level changes
* is directly comparable to history
* translates monthly forecasts to a daily schedule

Basic Premise
---------------
    Everything recorded on the ledger is part of a work flow
    Each flow has a timing to it depending on the parties involved
    Forecast the work flows and the parties involved and you can forecast the gl activity & timeframe
    The existing P&L forecast represents some part of some of the flows and serves as a starting point

Complications needing worked through
-------------------------------------

* creating a more granular forecast than supplied by the plants is presumptious by person/logic doing the break-out; collaboration needed
* each plant has different practices & account usage which necessitate different flows for the same basic thing
* merging known/firm AP & AR on top of forecasted AP & AR
* all ledger activity has to be claimed by a modeled flow, but not over-allocated, and actual activity must be similarly aligned for comparability
* how do you handle the frequency of which items occur and make sure not to over-forecast infrequent expenditures (especially if part of known AP/AR)
* modeling disbursements & borrowing to land on weekly check run schedule
* attributing cost of sales to specific locations while holding the receivable in a central location
* holding AP at certain times
* modeling collateral 
* accrual situations
* change in FX & consolidations
* Canada's balance sheet
* transfer pricing
* intercomp settlement
* open/incurred freight & payroll needs to be derived from bank activity (to ensure not double forecasted)
* open incurred manually booked items needs to be derived from bank activity (to ensure not double forecasted)
* above requirements give rise to on-demand bank data with mappings (which is mostly resolved in `tps.trans`)

Platform
---------

* PostgreSQL ([text link](https://www.bigsql.org/))
    * regular expressions & json data for bank loading & parsing
    * ranges, intervals, series for spooling out forecasts
    * can replicate
* SQL Server
    * replciated core data store
* DB2 for i
    * core data store