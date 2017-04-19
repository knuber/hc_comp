WITH CUR AS (
SELECT
    MAST,
    MPLT,
	SUM(
			CASE MAJG||RQBY||REPL
				WHEN '710R2' THEN 
					ERQTY + ERQTYS
				ELSE 0
			END
	) RES_REQ_QTY,
	SUM(
			CASE MAJG||RQBY||REPL
				WHEN '710B2' THEN 
					ERQTY + ERQTYS
				ELSE 0
			END
	) RES_BYP_QTY,
		SUM(
			CASE MAJG||RQBY||REPL
				WHEN '710R2' THEN 
					BASEX + BASEXS
				ELSE 0
			END
	) RES_REQ_VAL,
	SUM(
			CASE MAJG||RQBY||REPL
				WHEN '710B2' THEN 
					BASEX + BASEXS
				ELSE 0
			END
	) RES_BYP_VAL,
	SUM(
		CASE MAJG
			WHEN '910' THEN
				CASE MING
					WHEN 'D10 - CORRUGATE' THEN BASEX + BASEXS
					ELSE 0
				END
			ELSE 0
		END
	) D10_CORRUGATE,
	SUM(
		CASE MAJG
			WHEN '910' THEN
				CASE MING
					WHEN 'D11 - PALLET' THEN BASEX + BASEXS
					ELSE 0
				END
			ELSE 0
		END
	) D11_PALLET,
	SUM(
		CASE MAJG
			WHEN '910' THEN
				CASE MING
					WHEN 'D12 - LABEL' THEN BASEX + BASEXS
					ELSE 0
				END
			ELSE 0
		END
	) D12_LABEL,
	SUM(
		CASE MAJG
			WHEN '910' THEN
				CASE MING
					WHEN 'D13 - WRAP' THEN BASEX + BASEXS
					ELSE 0
				END
			ELSE 0
		END
	) D13_WRAP,
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
    QGPL.FFBSREQC
GROUP BY
    MAST,
    MPLT
),
FUT AS (
SELECT
    MAST,
    MPLT,
	SUM(
			CASE MAJG||RQBY||REPL
				WHEN '710R2' THEN 
					ERQTY + ERQTYS
				ELSE 0
			END
	) RES_REQ_QTY,
	SUM(
			CASE MAJG||RQBY||REPL
				WHEN '710B2' THEN 
					ERQTY + ERQTYS
				ELSE 0
			END
	) RES_BYP_QTY,
		SUM(
			CASE MAJG||RQBY||REPL
				WHEN '710R2' THEN 
					BASEX + BASEXS
				ELSE 0
			END
	) RES_REQ_VAL,
	SUM(
			CASE MAJG||RQBY||REPL
				WHEN '710B2' THEN 
					BASEX + BASEXS
				ELSE 0
			END
	) RES_BYP_VAL,
	SUM(
		CASE MAJG
			WHEN '910' THEN
				CASE MING
					WHEN 'D10 - CORRUGATE' THEN BASEX + BASEXS
					ELSE 0
				END
			ELSE 0
		END
	) D10_CORRUGATE,
	SUM(
		CASE MAJG
			WHEN '910' THEN
				CASE MING
					WHEN 'D11 - PALLET' THEN BASEX + BASEXS
					ELSE 0
				END
			ELSE 0
		END
	) D11_PALLET,
	SUM(
		CASE MAJG
			WHEN '910' THEN
				CASE MING
					WHEN 'D12 - LABEL' THEN BASEX + BASEXS
					ELSE 0
				END
			ELSE 0
		END
	) D12_LABEL,
	SUM(
		CASE MAJG
			WHEN '910' THEN
				CASE MING
					WHEN 'D13 - WRAP' THEN BASEX + BASEXS
					ELSE 0
				END
			ELSE 0
		END
	) D13_WRAP,
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
    QGPL.FFBSREQF
GROUP BY
    MAST,
    MPLT
), SALES AS (
SELECT
	VERSION,
	CHAN,
	GEO,
	ACCOUNT,
	GLEC,
	PLNT,
	PART,
	STATEMENT_LINE,
	R_CURRENCY,
	C_CURRENCY,
	MAJG,
	MING,
	MAJS,
	MINS,
	SUBSTR(DIGITS(YEAR(B_SHIPDATE+ I_SHIPDATE DAYS)),9)||SUBSTR(DIGITS(MONTH(B_SHIPDATE + I_SHIPDATE DAYS)),9) SHIPDATE,
	SUM(VALUE_LOCAL*CASE R_CURRENCY WHEN 'CA' THEN .75 ELSE 1 END) REVENUE_USD,
	SUM(QTY) QTY
FROM
	QGPL.FFBS0403
WHERE
	COALESCE(B_SHIPDATE,CAST('2001-01-01' AS DATE)) >= CAST('2017-03-01' AS DATE) 
GROUP BY
	VERSION,
	CHAN,
	GEO,
	ACCOUNT,
	GLEC,
	PLNT,
	PART,
	STATEMENT_LINE,
	R_CURRENCY,
	C_CURRENCY,
	MAJG,
	MING,
	MAJS,
	MINS,
	SUBSTR(DIGITS(YEAR(B_SHIPDATE+ I_SHIPDATE DAYS)),9)||SUBSTR(DIGITS(MONTH(B_SHIPDATE + I_SHIPDATE DAYS)),9)
)

SELECT
	S.VERSION,
	S.CHAN,
	S.GEO,
	S.ACCOUNT,
	S.GLEC,
	S.PLNT,
	S.PART,
	S.STATEMENT_LINE,
	S.R_CURRENCY,
	S.C_CURRENCY,
	S.MAJG,
	S.MING,
	S.MAJS,
	S.MINS,
	S.SHIPDATE,
	S.REVENUE_USD,
	S.QTY,
	C.RES_REQ_QTY * S.QTY CRES_REQ_QTY,
	C.RES_BYP_QTY * S.QTY CRES_BYP_QTY,
	C.RES_REQ_VAL * S.QTY CRES_REQ_VAL,
	C.RES_BYP_VAL * S.QTY CRES_BYP_VAL,
	C.D10_CORRUGATE * S.QTY CD10_CORRUGATE,
	C.D11_PALLET * S.QTY CD11_PALLET,
	C.D12_LABEL * S.QTY CD12_LABEL,
	C.D13_WRAP * S.QTY CD13_WRAP,
	C.BASE * S.QTY CBASE,
	C.FREIGHT * S.QTY CFREIGHT,
	C.DUTY * S.QTY CDUTY,
	C.MULT1 * S.QTY CMULT1,
	C.MULT2 * S.QTY CMULT2,
	C.SHIPH * S.QTY CSHIPH,
	C.SUBFRTOUT * S.QTY CSUBFRTOUT,
	C.SUBFRTIN * S.QTY CSUBFRTIN,
	C.CURRENCY * S.QTY CCURRENCY,
	C.SUBCONTR * S.QTY CSUBCONTR,
	C.LABRUN * S.QTY CLABRUN,
	C.VARRUN * S.QTY CVARRUN,
	C.FIXRUN * S.QTY CFIXRUN,
	C.LABSET * S.QTY CLABSET,
	C.VARSET * S.QTY CVARSET,
	C.FIXSET * S.QTY CFIXSET,
	C.SCRAP * S.QTY CSCRAP,
	F.RES_REQ_QTY * S.QTY FRES_REQ_QTY,
	F.RES_BYP_QTY * S.QTY FRES_BYP_QTY,
	F.RES_REQ_VAL * S.QTY FRES_REQ_VAL,
	F.RES_BYP_VAL * S.QTY FRES_BYP_VAL,
	F.D10_CORRUGATE * S.QTY FD10_CORRUGATE,
	F.D11_PALLET * S.QTY FD11_PALLET,
	F.D12_LABEL * S.QTY FD12_LABEL,
	F.D13_WRAP * S.QTY FD13_WRAP,
	F.BASE * S.QTY FBASE,
	F.FREIGHT * S.QTY FFREIGHT,
	F.DUTY * S.QTY FDUTY,
	F.MULT1 * S.QTY FMULT1,
	F.MULT2 * S.QTY FMULT2,
	F.SHIPH * S.QTY FSHIPH,
	F.SUBFRTOUT * S.QTY FSUBFRTOUT,
	F.SUBFRTIN * S.QTY FSUBFRTIN,
	F.CURRENCY * S.QTY FCURRENCY,
	F.SUBCONTR * S.QTY FSUBCONTR,
	F.LABRUN * S.QTY FLABRUN,
	F.VARRUN * S.QTY FVARRUN,
	F.FIXRUN * S.QTY FFIXRUN,
	F.LABSET * S.QTY FLABSET,
	F.VARSET * S.QTY FVARSET,
	F.FIXSET * S.QTY FFIXSET,
	F.SCRAP * S.QTY FSCRAP
FROM
	SALES S
	LEFT OUTER JOIN CUR C ON
		C.MAST = S.PART AND
		C.MPLT = S.PLNT
	LEFT OUTER JOIN FUT F ON
		F.MAST = S.PART AND
		F.MPLT = S.PLNT
FETCH FIRST 100 ROWS ONLY