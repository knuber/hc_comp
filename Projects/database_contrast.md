
postgres & mssql

1. greater ability to internalize business logic
2. greater ability to accomodate diverse data sources
2. greater analytic capability
3. total cost of ownership 


* data minupulation
    * regular expressions
    * order by clauses
        - functions not permitted
        - views not permitted
        - stored procs permitted but callable as a table
    * temp tables
        - use prohibited in anything other than stored proc which cannot be called as table
    * left joins
        - not permited in recursive CTE
        - not permited in indexed view
    * cannot specify option on stored proc call which is necessary if maxrecursion > 100
    * type casting
    * user defined aggregate require clr integration
    * standard function library (no least/greates)
    * text type & indexes
    * filter on aggregates (example pivoting)
    * dollar quoting
    * languages 
        * python
        * java
        * R
        * tcl
        * perl

* persisting data

    * namespace/schema division
    * descriptions
    * arrays
    * ranges
    * interval
    * json
    * geospatial
    * inheritance

* peripherals

    * ssms gui is better
    * reporting & analysis services (enterprise license)
    * sql agent is better


