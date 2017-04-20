product structure explosion logic
=================================

### _available switches_

* `STKA`    _single procurement type; run sizes_
* `METHDR`  _routing; potentially multiple per part;cacscading scrap factor; setup times_
* `METHDO`  _outsource; operates in sync with routing_
* `METHDM`  _bill of materials; per routing sequnce (but probably not enforced)_
* `METHOP`  _operation code; can differntiate labor rates_
* `MTHC`    _part seq unit conversion_
* `MTHL`    _tooling_
* `MTHO`    _opertion details_
* `DEPTS`   _contains outside service flag_
* `RESRE`   _burden rates_

### _CTE design_

### anchor

start with list, row_number() creates initial sort sequence on anchor

child sequence copies parent, default 1's for all quantities

row type based on V6RPLN
|            |1          |2          |3          |
|------------|-----------|-----------|-----------|
| SPLNT      |=CPLNT     |=CPLNT     |V6TPLN     |
| ROW TYPE   |R          |B          |T          |

this will require a join to `METHDR` & `METHDO`  on the anchor arm

### recursion arm

incoming parent switch (V6RPLN & ROW TYPE)
join to stka on pse.chld & pse.splnt

|PARENT ->   |1-R          |1-B          |3-T          |
|------------|-----------  |-----------  |-----------  |
|**STKA**    |             |             |             |
|1           |1-B(`METHDM)`|1-R(`METHDR`)|1-R(`METHDR`)|
|2           |-            |-            |2-X(COPY)    |
|3           |-            |3-T(`STKA`)  |3-T(`STKA`)  |

`STKA` join is implemented in the recursion arm as:

    V6PART = PSE.CHLD AND
    V6PART = PSE.SPLNT

`METHDR` join is implemented in the recursion arms as:

    AOPART = PSE.CHLD AND
    AOPLNT = PSE.SPLT AND
    PSE.PRTP IN ('B','T') AND
    V6RPLN IN (1,3)

`METHDM` join is implemented in the recursion arms as:

    AQPART = PSE.CHLD AND
    AQPLNT = PSE.SPLT AND
    PSE.PRTP = 'R' AND
    V6RPLN = 1