CREATE OR REPLACE VIEW RLARP.VW_FFOPOR ( 
	DCODAT , 
	ORD_PERD , 
	DDQDAT , 
	REQ_PERD , 
	DCMDAT , 
	PRO_PERD , 
	PROM_PERD , 
	DCPO , 
	DCPROM , 
	DDORD# , 
	DDITM# , 
	DCSTAT , 
	DDITST , 
	CALC_STATUS FOR COLUMN CALC_00001 , 
	DDQTOI , 
	DDQTSI , 
	QTY_I , 
	DCCURR , 
	DCBCUS , 
	DCSCUS , 
	PLNT , 
	DDPART , 
	DDGLC , 
	DDCRRS , 
	DCTRCD , 
	DDTOTI , 
	"VALUE" , 
	VALUE_USD , 
	COST , 
	COST_USD , 
	FESVIA , 
	ACCT , 
	FGRP , 
	GLEC , 
	GLDC , 
	MAJG , 
	MING , 
	MAJS , 
	MINS ) 
	AS 
	SELECT  
			DCODAT DCODAT,  
			SUBSTR(CHAR(DCODAT),3,2)||SUBSTR(CHAR(DCODAT),6,2) ORD_PERD,  
			DDQDAT,  
			SUBSTR(CHAR(MAX(DDQDAT,CURRENT DATE)),3,2)||SUBSTR(CHAR(MAX(DDQDAT,CURRENT DATE)),6,2) REQ_PERD,  
			DCMDAT,  
			SUBSTR(CHAR(MAX(DCMDAT,CURRENT DATE)),3,2)||SUBSTR(CHAR(MAX(DCMDAT,CURRENT DATE)),6,2) PRO_PERD,  
			SUBSTR(CHAR(DCMDAT),3,2)||SUBSTR(CHAR(DCMDAT),6,2) PROM_PERD,  
			DCPO,  
			DCPROM,  
			DDORD#,  
			DDITM#,  
			DCSTAT,  
			DDITST,  
			CASE DDITST  
				WHEN 'C' THEN  
					CASE DDQTSI  
						WHEN 0 THEN 'CANCELED'  
						ELSE 'CLOSED'  
					END  
				ELSE  
					CASE WHEN DDQTSI >0 THEN 'BACKORDER' ELSE 'OPEN' END  
			END CALC_STATUS,  
			DDQTOI,  
			DDQTSI,  
			DDQTOI - DDQTSI QTY_I,  
			DCCURR,  
			DCBCUS,  
			DCSCUS,  
			SUBSTR(DDSTKL,1,3) PLNT,  
			DDPART,  
			DDGLC,  
			DDCRRS,  
			DCTRCD,  
			DDTOTI,  
			CASE DDQTOI WHEN 0 THEN 0 ELSE DDTOTI/DDQTOI END*(DDQTOI - DDQTSI) VALUE,  
			CASE DDQTOI WHEN 0 THEN 0 ELSE DDTOTI/DDQTOI END*(DDQTOI - DDQTSI)*IX.RATE VALUE_USD,  
			STDCOST*(DDQTOI - DDQTSI) COST,  
			STDCOST*(DDQTOI - DDQTSI)*CX.RATE COST_USD,  
			DCSHVI FESVIA,  
			DIGITS(ZWSAL#) ACCT,  
			AZGROP||' - '||RTRIM(BQ1TITL) FGRP,  
			GLEC, GLDC, MAJG, MING, MAJS, MINS  
		FROM  
			LGDAT.OCRI  
			INNER JOIN LGDAT.OCRH ON  
				DCORD# = DDORD#  
			LEFT OUTER JOIN LGDAT.PLNT P ON  
				P.YAPLNT = SUBSTR(DDSTKL,1,3)  
			LEFT OUTER JOIN LGDAT.CUST ON  
				BVCUST = DCBCUS  
			LEFT OUTER JOIN LGDAT.ARMASC ON  
				ZWCOMP = BVCOMP AND  
				ZWKEY1 = BVARCD AND  
				ZWKEY2 = DDGLC AND  
				ZWPLNT = CASE SUBSTR(BVCOMP,1,1) WHEN '3' THEN '0'||BVCOMP ELSE P.YAPLNT END	  
			LEFT OUTER JOIN LGDAT.MAST ON  
				AZCOMP||DIGITS(AZGL#1)||DIGITS(AZGL#2) = DIGITS(ZWSAL#)  
			LEFT OUTER JOIN LGDAT.FGRP ON  
				BQ1GRP = AZGROP  
			LEFT OUTER JOIN RLARP.VW_FFITEMM ON  
				ITEM = DDPART  
			LEFT OUTER JOIN RLARP.VW_FFPLPR PR ON  
				PR.YAPLNT = SUBSTR(DDSTKL,1,3)  
			LEFT OUTER JOIN RLARP.FFCRET IX ON  
				IX.FCUR = DCCURR AND  
				IX.TCUR = 'US' AND  
				IX.PERD = AR AND  
				IX.RTYP = 'ME'  
			LEFT OUTER JOIN RLARP.FFCRET CX ON  
				CX.FCUR = PR.CURR AND  
				CX.TCUR = 'US' AND  
				CX.PERD = PR.AR AND  
				CX.RTYP = 'ME'  
			LEFT OUTER JOIN RLARP.VW_FFICSTX C ON  
				C.V6PART = DDPART AND  
				C.V6PLNT = SUBSTR(DDSTKL,1,3)
		WHERE  
			DDITST <> 'C' AND  
			DDQTOI - DDQTSI <> 0   ;
  
LABEL ON TABLE RLARP.VW_FFOPOR 
	IS 'Sales - Open Orders' ; 
  
LABEL ON COLUMN RLARP.VW_FFOPOR 
( DCODAT IS 'Date                Entered' , 
	DDQDAT IS 'Request             Date' , 
	DCMDAT IS 'Promise             Date' , 
	DCPO IS 'Purchase            Order' , 
	DCPROM IS 'Promotion Number' , 
	DDORD# IS 'Order               Number' , 
	DDITM# IS 'Item                Number' , 
	DCSTAT IS 'Order               Status' , 
	DDITST IS 'Item                Status' , 
	DDQTOI IS 'Quantity            Ordered IU' , 
	DDQTSI IS 'Quantity            Shipped IU' , 
	DCCURR IS 'Currency' , 
	DCBCUS IS 'Bill-to             Customer' , 
	DCSCUS IS 'Ship-to             Customer' , 
	DDPART IS 'Part                Number' , 
	DDGLC IS 'G/L                 Code' , 
	DDCRRS IS 'Credit              Reason' , 
	DCTRCD IS 'Terms               Code' , 
	DDTOTI IS 'Item                Net Total' , 
	FESVIA IS 'Ship Via' ) ; 
  
LABEL ON COLUMN RLARP.VW_FFOPOR 
( DCODAT TEXT IS 'Date Entered' , 
	DDQDAT TEXT IS 'Request Date' , 
	DCMDAT TEXT IS 'Promise Date' , 
	DCPO TEXT IS 'Purchase Order' , 
	DCPROM TEXT IS 'Promotion Number' , 
	DDORD# TEXT IS 'Order Number' , 
	DDITM# TEXT IS 'Item Number' , 
	DCSTAT TEXT IS 'Status New, A, B/o, Comp' , 
	DDITST TEXT IS 'Status Open, B/o, Compl.' , 
	DDQTOI TEXT IS 'Quantity Ordered IU' , 
	DDQTSI TEXT IS 'Quantity Shipped IU' , 
	DCCURR TEXT IS 'Currency' , 
	DCBCUS TEXT IS 'Bill-to Customer' , 
	DCSCUS TEXT IS 'Ship-to Customer' , 
	DDPART TEXT IS 'Part Number' , 
	DDGLC TEXT IS 'G/L Code' , 
	DDCRRS TEXT IS 'Credit Reason' , 
	DCTRCD TEXT IS 'Terms Code' , 
	DDTOTI TEXT IS 'Item Net Total' , 
	FESVIA TEXT IS 'Ship Via' ) ; 
  
  
GRANT SELECT   
ON RLARP.VW_FFOPOR TO PUBLIC ;
