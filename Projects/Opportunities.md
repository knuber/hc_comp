Correct
-------------------------

1. Production Ledger            (requires corrective entries)
2. Sales Ledger                 (requires corrective entries)
3. Warehouse Transfers          (requires corrective entries)
4. Returns & Credits Behaviour  (requires corrective entries)
5. Book to perpetual            (requires corrective entries)
6. CMS Currency Type 3

Clarify
-------------------------

* centralized data store (Live)
    * CMS Tables
    * CMS transformation (FFCOSTEFFD, STKT, STKB, METHDM, METHDR, FFPDGLR1, DDQTSI, GLMT, MAST)
    * TMS
    * Williams Paid File
    * PNC Cash & parsing
    * PNC Collateral & parsing
    * PNC Loan & parsing
    * Payroll
    * Mattec
    * forecasting & budgeting
    * Quote Tool Data
    * centralized definitions of key metrics
        1. Production
            * earned hours
            * fpv
            * absorption
            * MUV
            * scrap
            * OEE
            * run time (where does it come from ultimately)
            * down time (where does it come from ultimately)
        2. Sales
            * open orders (what is an open order)
            * sales rep & director (special sauce logic for some areas)
            * standard margin (net cost/gross cost)
            * gross sales (what about corrections, manual journals, by plant)
        3. Master Data
            * standard cost categories & components
            * product first 3
            * color
            * style
            * dimensions
            * channels
            * capital projects & categories
            * unit of measure requires n interations to convert (you have to build a graph)
* Ledger Granularity Rebuild
    * Production
    * Sales
    * AR
    * AP
    * Inventory Transactions
    * Purchasing
* Variance Reporting
    * Procurement
        * Freight
        * Duty
        * PPV
        * Subcontract   
        * Transfer Cost
    * Utilization
        * MUV
        * Scrap
        * Counts
    * Conversion
        * Process Type
        * Labor
        * Overhead
    * Non-Financial
        * Run Time
        * Down Time
* Orders Matrix
    * Timing
    * Open Orders Rebuild
* Capital Tracking
* Freight & Duty Processing
* Journal Numbering
* Voucher-Time PO Receipt Adjustment

Automate
-------------------------

1. Transfer Pricing
2. Consolidating Journal Entries & Statements
3. Production Reporting
4. Balance Sheet Forecasting (including loan, cash balance, & collateral)

Invest
==========================
Better-than-market capital allocation: invest in organic execution
--------------------------
1. Production Scheduling Optimization Logic & Forecasting
2. In house route planning; on-premise geo-spatial store with KNN algorithm (POSTGis; pgRouting)
3. Polyglot persistance: implement a graph DB on top of the relational model building market intelligence