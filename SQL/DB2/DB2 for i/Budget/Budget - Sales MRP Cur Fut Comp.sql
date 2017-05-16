WITH CUR AS (
SELECT
    MAST,
    MPLT,
    SUM(COALESCE(BASEX,0)) BASE,
    SUM(COALESCE(FRTX,0)) FREIGHT,
    SUM(COALESCE(DUTYX,0)) DUTY,
    SUM(COALESCE(MULT1X,0)) MULT1,
    SUM(COALESCE(MULT2X,0)) MULT2,
    SUM(COALESCE(SHIPHX,0)) SHIPH,
    SUM(COALESCE(OSFTX,0)) SUBFRTOUT,
    SUM(COALESCE(OSFFX,0)) SUBFRTIN,
    SUM(COALESCE(CURRX,0)) CURRENCY,
    SUM(COALESCE(SUBCX,0)) SUBCONTR,
    SUM(LABRX) LABRUN,
    SUM(VARRX) VARRUN,
    SUM(FIXRX) FIXRUN,
    SUM(LABSX) LABSET,
    SUM(VARSX) VARSET,
    SUM(FIXSX) FIXSET,
    SUM(
        COALESCE(BASEXS,0) +
        COALESCE(FRTXS,0) +
        COALESCE(DUTYXS,0) +
        COALESCE(MULT1XS,0) +
        COALESCE(MULT2XS,0) +
        COALESCE(SHIPHXS,0) +
        COALESCE(OSFTXS,0) +
        COALESCE(OSFFXS,0) +
        COALESCE(CURRXS,0) +
        COALESCE(SUBCXS,0) +
        COALESCE(LABRXS,0)+
        COALESCE(VARRXS,0)+
        COALESCE(FIXRXS,0)+
        COALESCE(LABSXS,0)+
        COALESCE(VARSXS,0)+
        COALESCE(FIXSXS,0)
    ) SCRAP,
    ROUND(
        SUM(
                ---good----
                COALESCE(BASEX,0) +
                COALESCE(FRTX,0) +
                COALESCE(DUTYX,0) +
                COALESCE(MULT1X,0) +
                COALESCE(MULT2X,0) +
                COALESCE(SHIPHX,0) +
                COALESCE(OSFTX,0) +
                COALESCE(OSFFX,0) +
                COALESCE(CURRX,0) +
                COALESCE(SUBCX,0) +
                COALESCE(LABRX,0)+
                COALESCE(VARRX,0)+
                COALESCE(FIXRX,0)+
                COALESCE(LABSX,0)+
                COALESCE(VARSX,0)+
                COALESCE(FIXSX,0)+
                ---scrap----
                COALESCE(BASEXS,0) +
                COALESCE(FRTXS,0) +
                COALESCE(DUTYXS,0) +
                COALESCE(MULT1XS,0) +
                COALESCE(MULT2XS,0) +
                COALESCE(SHIPHXS,0) +
                COALESCE(OSFTXS,0) +
                COALESCE(OSFFXS,0) +
                COALESCE(CURRXS,0) +
                COALESCE(SUBCXS,0) +
                COALESCE(LABRXS,0)+
                COALESCE(VARRXS,0)+
                COALESCE(FIXRXS,0)+
                COALESCE(LABSXS,0)+
                COALESCE(VARSXS,0)+
                COALESCE(FIXSXS,0)
        )
    ,5) TOTAL_CALC
FROM
    QGPL.FFBSMRPC
GROUP BY
    MAST,
    MPLT
),
FUT AS (
SELECT
    MAST,
    MPLT,
    SUM(COALESCE(BASEX,0)) BASE,
    SUM(COALESCE(FRTX,0)) FREIGHT,
    SUM(COALESCE(DUTYX,0)) DUTY,
    SUM(COALESCE(MULT1X,0)) MULT1,
    SUM(COALESCE(MULT2X,0)) MULT2,
    SUM(COALESCE(SHIPHX,0)) SHIPH,
    SUM(COALESCE(OSFTX,0)) SUBFRTOUT,
    SUM(COALESCE(OSFFX,0)) SUBFRTIN,
    SUM(COALESCE(CURRX,0)) CURRENCY,
    SUM(COALESCE(SUBCX,0)) SUBCONTR,
    SUM(LABRX) LABRUN,
    SUM(VARRX) VARRUN,
    SUM(FIXRX) FIXRUN,
    SUM(LABSX) LABSET,
    SUM(VARSX) VARSET,
    SUM(FIXSX) FIXSET,
    SUM(
        COALESCE(BASEXS,0) +
        COALESCE(FRTXS,0) +
        COALESCE(DUTYXS,0) +
        COALESCE(MULT1XS,0) +
        COALESCE(MULT2XS,0) +
        COALESCE(SHIPHXS,0) +
        COALESCE(OSFTXS,0) +
        COALESCE(OSFFXS,0) +
        COALESCE(CURRXS,0) +
        COALESCE(SUBCXS,0) +
        COALESCE(LABRXS,0)+
        COALESCE(VARRXS,0)+
        COALESCE(FIXRXS,0)+
        COALESCE(LABSXS,0)+
        COALESCE(VARSXS,0)+
        COALESCE(FIXSXS,0)
    ) SCRAP,
    ROUND(
        SUM(
                ---good----
                COALESCE(BASEX,0) +
                COALESCE(FRTX,0) +
                COALESCE(DUTYX,0) +
                COALESCE(MULT1X,0) +
                COALESCE(MULT2X,0) +
                COALESCE(SHIPHX,0) +
                COALESCE(OSFTX,0) +
                COALESCE(OSFFX,0) +
                COALESCE(CURRX,0) +
                COALESCE(SUBCX,0) +
                COALESCE(LABRX,0)+
                COALESCE(VARRX,0)+
                COALESCE(FIXRX,0)+
                COALESCE(LABSX,0)+
                COALESCE(VARSX,0)+
                COALESCE(FIXSX,0)+
                ---scrap----
                COALESCE(BASEXS,0) +
                COALESCE(FRTXS,0) +
                COALESCE(DUTYXS,0) +
                COALESCE(MULT1XS,0) +
                COALESCE(MULT2XS,0) +
                COALESCE(SHIPHXS,0) +
                COALESCE(OSFTXS,0) +
                COALESCE(OSFFXS,0) +
                COALESCE(CURRXS,0) +
                COALESCE(SUBCXS,0) +
                COALESCE(LABRXS,0)+
                COALESCE(VARRXS,0)+
                COALESCE(FIXRXS,0)+
                COALESCE(LABSXS,0)+
                COALESCE(VARSXS,0)+
                COALESCE(FIXSXS,0)
        )
    ,5) TOTAL_CALC
FROM
    QGPL.FFBSMRPF
GROUP BY
    MAST,
    MPLT   
)
SELECT
    U.*, CUR.TOTAL_CALC, CUR.SCRAP, FUT.TOTAL_CALC, FUT.SCRAP
FROM
    QGPL.FFBSUPP U
    LEFT OUTER JOIN CUR ON
        CUR.MAST = U.PART AND
        CUR.MPLT = U.PLNT
    LEFT OUTER JOIN FUT ON
        FUT.MAST = U.PART AND
        FUT.MPLT = U.PLNT