
------------Weathered Wood---------------
DELETE FROM QGPL.FFBS0516 WHERE VERSION = 'X1000 Weathered Wood';
INSERT INTO 
	QGPL.FFBS0516
SELECT 
    PLNT,
    ORDER,
    ORDERITEM,
    BOL,
    BOLITEM,
    INVOICE,
    INVOICEITEM,
    PROMO,
    RETURNREAS,
    TERMS,
    CUSTPO,
    ORDERDATE,
    REQUESTDATE,
    PROMISEDATE,
    SHIPDATE,
    SALESMONTH,
    BILLREMITO,
    BILLCUSTCLASS,
    BILLCUST,
    BILLREP,
    BILLDSM,
    BILLDIRECTOR,
    SHIPCUSTCLASS,
    SHIPCUST,
    SHIPDSM,
    SHIPDIRECTOR,
    SPECIAL_SAUCE_REP,
    ACCOUNT,
    GEO,
    CHAN,
    ORIG_CTRY,
    ORIG_PROV,
    ORIG_LANE,
    ORIG_POST,
    DEST_CTRY,
    DEST_PROV,
    DEST_LANE,
    DEST_POST,
    PART,
    GL_CODE,
    MAJG,
    MING,
    MAJS,
    MINS,
    GLDC,
    GLEC,
    HARM,
    CLSS,
    BRAND,
    ASSC,
    STATEMENT_LINE,
    R_CURRENCY,
    R_RATE,
    C_CURRENCY,
    C_RATE,
    QTY*4.58517-QTY,
    VALUE_LOCAL*4.58517-VALUE_LOCAL VALUE_LOCAL,
    PRICE,
    STATUS,
    FLAG,
    B_ORDERDATE,
    B_REQUESTDATE,
    B_SHIPDATE,
    I_ORDERDATE,
    I_REQUESTDATE,
    I_SHIPDATE,
    'X1000 Weathered Wood'
FROM 
	QGPL.FFBS0516 
    INNER JOIN QGPL.FFVERS ON
        VERS = VERSION
WHERE 
    SEQ <= 3 AND
    PART LIKE 'PBH1200%' AND
    GLEC = '1GR - GREENHOUSE PRODUCT' AND
	B_SHIPDATE + I_SHIPDATE DAYS >= '2017-06-01' AND
    B_SHIPDATE + I_SHIPDATE DAYS < '2018-06-01' AND
    B_ORDERDATE + I_ORDERDATE DAYS >= '2017-06-01';

------------6 ct Tray---------------
DELETE FROM QGPL.FFBS0516 WHERE VERSION = '6 ct Tray';
INSERT INTO 
	QGPL.FFBS0516
SELECT 
    PLNT,
    ORDER,
    ORDERITEM,
    BOL,
    BOLITEM,
    INVOICE,
    INVOICEITEM,
    PROMO,
    RETURNREAS,
    TERMS,
    CUSTPO,
    ORDERDATE,
    REQUESTDATE,
    PROMISEDATE,
    SHIPDATE,
    SALESMONTH,
    BILLREMITO,
    BILLCUSTCLASS,
    BILLCUST,
    BILLREP,
    BILLDSM,
    BILLDIRECTOR,
    SHIPCUSTCLASS,
    SHIPCUST,
    SHIPDSM,
    SHIPDIRECTOR,
    SPECIAL_SAUCE_REP,
    ACCOUNT,
    GEO,
    CHAN,
    ORIG_CTRY,
    ORIG_PROV,
    ORIG_LANE,
    ORIG_POST,
    DEST_CTRY,
    DEST_PROV,
    DEST_LANE,
    DEST_POST,
    PART,
    GL_CODE,
    MAJG,
    MING,
    MAJS,
    MINS,
    GLDC,
    GLEC,
    HARM,
    CLSS,
    BRAND,
    ASSC,
    STATEMENT_LINE,
    R_CURRENCY,
    R_RATE,
    C_CURRENCY,
    C_RATE,
    QTY*6.532696-QTY,
    VALUE_LOCAL*6.532696-VALUE_LOCAL VALUE_LOCAL,
    PRICE,
    STATUS,
    FLAG,
    B_ORDERDATE,
    B_REQUESTDATE,
    B_SHIPDATE,
    I_ORDERDATE,
    I_REQUESTDATE,
    I_SHIPDATE,
    '6 ct Tray'
FROM 
	QGPL.FFBS0516 
    INNER JOIN QGPL.FFVERS ON
        VERS = VERSION
WHERE 
    SEQ <= 3 AND
    PART LIKE 'TIS6665%' AND
    GLEC = '1GR - GREENHOUSE PRODUCT' AND
	B_SHIPDATE + I_SHIPDATE DAYS >= '2017-06-01' AND
    B_SHIPDATE + I_SHIPDATE DAYS < '2018-06-01' AND
    B_ORDERDATE + I_ORDERDATE DAYS >= '2017-06-01';

------------Retail Distribution Adjustments---------------
DELETE FROM QGPL.FFBS0516 WHERE VERSION = 'Distribution Adjustments - Vol';
INSERT INTO 
	QGPL.FFBS0516
SELECT 
    PLNT,
    ORDER,
    ORDERITEM,
    BOL,
    BOLITEM,
    INVOICE,
    INVOICEITEM,
    PROMO,
    RETURNREAS,
    TERMS,
    CUSTPO,
    ORDERDATE,
    REQUESTDATE,
    PROMISEDATE,
    SHIPDATE,
    SALESMONTH,
    BILLREMITO,
    BILLCUSTCLASS,
    BILLCUST,
    BILLREP,
    BILLDSM,
    BILLDIRECTOR,
    SHIPCUSTCLASS,
    SHIPCUST,
    SHIPDSM,
    SHIPDIRECTOR,
    SPECIAL_SAUCE_REP,
    ACCOUNT,
    GEO,
    CHAN,
    ORIG_CTRY,
    ORIG_PROV,
    ORIG_LANE,
    ORIG_POST,
    DEST_CTRY,
    DEST_PROV,
    DEST_LANE,
    DEST_POST,
    PART,
    GL_CODE,
    MAJG,
    MING,
    MAJS,
    MINS,
    GLDC,
    GLEC,
    HARM,
    CLSS,
    BRAND,
    ASSC,
    STATEMENT_LINE,
    R_CURRENCY,
    R_RATE,
    C_CURRENCY,
    C_RATE,
    QTY*.07 QTY,
    VALUE_LOCAL*.07 VALUE_LOCAL,
    0 PRICE,
    STATUS,
    FLAG,
    B_ORDERDATE,
    B_REQUESTDATE,
    B_SHIPDATE,
    I_ORDERDATE,
    I_REQUESTDATE,
    I_SHIPDATE,
    'Distribution Adjustments - Vol'
FROM 
	QGPL.FFBS0516 
    INNER JOIN QGPL.FFVERS ON
        VERS = VERSION
WHERE 
    SEQ <= 3 AND
    BILLCUSTCLASS IN ('GDIS','RDIS') AND
    GLEC = '1RE - RETAIL PRODUCT' AND
    B_ORDERDATE + I_ORDERDATE DAYS >= '2017-06-01';

