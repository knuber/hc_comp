
postgres & mssql

1. greater ability to internalize business logic
2. greater ability to accomodate diverse data sources
2. greater analytic capability
3. total cost of ownership 


* data minupulation
    * **regular expressions**
    * **order by clauses**
        - mssql functions not permitted
        - mssql views not permitted
        - mssql stored procs permitted but not callable as a table
    * **temp tables**
        - mssql use prohibited in anything other than stored proc which cannot be called as table
    * **left joins**
        - mssql not permited in recursive CTE
        - mssql not permited in indexed view
    * **mssql cannot specify option on stored proc call which is necessary if maxrecursion > 100**
    * **types (char, nchar, varchar, nvarchar, & text versus text)**
    * **user defined aggregate (mssql requires clr integration)**
    * function overloading (ergonomics)
    * order by clause inside of aggregate SUM(column ORDER BY othercol)
    * filter on aggregates SUM(column WHERE thing = true) (ergonomics)
    * **WITH ORINALITY for set-returning functions joins**
    * **standard function library (least/greatest, pad, stringagg) (ergonomics)**
    * dollar quoting (ergonomics)
    * **generate_series**
    * write-able CTE (ergonomics)
    * languages 
        * python
        * java
        * R
        * tcl
        * perl

* persisting data

    * namespace/schema division
    * **descriptions**
    * **arrays**
    * **range types**
    * **interval type**
    * **json**
    * geospatial
    * inheritance
    * **simple text & date types (fully indexable and ready for full text search, utf-8)**
    * partitioning
    * replication

* peripherals

    * gui (pg is not great)
    * mssql reporting & analysis services (enterprise license, pg = no offering)
    * agent (pg version is just ok)
    * command line (pg is better)
    * tuning
    * geospatial