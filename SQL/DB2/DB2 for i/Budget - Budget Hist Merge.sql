DELETE FROM QGPL.FFBSHIST WHERE VERSION = 'ACTUAL';
SELECT
	--order data
	PLNT,
	DDORD#,
	DDITM#,
	FGBOL#,
	FGENT#,
	DIINV#,
	DILIN#,
	PROMO,
	RETURN_REAS,
	TERMS,
	DCPO CUSTPO,
	--dates-------------------------------
	DCODAT,
	DDQDAT,
	DCMDAT,
	DHIDAT,
	FSPR_INV,
	--customer data----------------------
	BC.BVCOMP,
	BC.BVCLAS,
	BC.BVCUST||' - '||RTRIM(BC.BVNAME) , 
	BC.BVSALM,
	BR.REPP,
	BR.DIRECTOR,
	SC.BVCLAS , 
	SC.BVCUST||' - '||RTRIM(SC.BVNAME),
	SR.REPP,
	SR.DIRECTOR,
	----special sauce rep...very VERY special sauce-----
	RTRIM( 
		--main contorl flow is glec
		CASE WHEN COALESCE(AVGLED,AWGLED) IN ('1RE','1CU')
			THEN
				CASE RTRIM(BC.BVTERR)
					WHEN '51' THEN 'DONNA'
					WHEN '52' THEN 'DORAN'
					WHEN '53' THEN 'RACHE'
					WHEN '54' THEN 'KEN S'
					WHEN '57' THEN 'KEN S'
					WHEN '58' THEN 'JON H'
					ELSE 
						--use retail rep by defualt, if null use bill-to salesman and run through switch
						CASE CASE COALESCE(CURREP,'') WHEN '' THEN SUBSTR(BC.BVSALM,1,3) ELSE SUBSTR(CURREP,1,3) END
							WHEN '501' THEN 'DORAN'
							WHEN '502' THEN 'DORAN'
							WHEN '503' THEN 'RACHE'
							WHEN '506' THEN 'JON H'
							WHEN '508' THEN 'JON H'
							--use salesman
							ELSE CASE COALESCE(CURREP,'') WHEN '' THEN SUBSTR(BC.BVSALM,1,3) ELSE SUBSTR(CURREP,1,3) END
						END
				END
			ELSE
				CASE WHEN COALESCE(AVGLED,AWGLED)  = '1NU'
					THEN
						CASE WHEN COALESCE(CUNREP,'') = ''
							--basis saleman code
							THEN
								CASE WHEN SUBSTR(BC.BVSALM,1,3) IN ('400','130')
									THEN BC.BVSALM
									ELSE SC.BVSALM
								END
							ELSE CUNREP
						END
					--basis 1GR/2WI & everything ELSE
					ELSE
						CASE WHEN SUBSTR(BC.BVSALM,1,3) IN ('400','130')
							-- 400/130 = bill to salesman code
							THEN BC.BVSALM
							-- <> 400/130
							ELSE
								CASE WHEN COALESCE(CUGREP,'') = ''
									THEN SC.BVSALM
									ELSE CUGREP
								END
						END
				END
		END
	),
	--scenario (offline data)------------
	COALESCE(CG.CGRP,BC.BVNAME) ACCOUNT,
	COALESCE(T.GEO,'UNDEFINED') GEO, 
	COALESCE(C.CHAN,'UNDEFINED') CHAN,
	--location
	QZCRYC ORIG_CTRY,
	QZPROV ORIG_PROV,
	SUBSTR(QZPOST,1,3) ORIG_LANE,
	QZPOST ORIG_POST,
	SC.BVCTRY DEST_CTRY,
	SC.BVPRCD DEST_PROV,
	SUBSTR(SC.BVPOST,1,3) DEST_LANE,
	SC.BVPOST DEST_POST,
	--item data-------------------------
	PART,
	GL_CODE,
	COALESCE(AVMAJG,AWMAJG)||' - '||RTRIM(BQDES) MAJG,  
	COALESCE(AVMING,AWMING)||' - '||RTRIM(BRDES) MING,  
	COALESCE(AVMAJS,AWMAJS)||' - '||RTRIM(MS.BSDES1) MAJS,  
	COALESCE(AVMINS,AWMINS)||' - '||RTRIM(NS.BSDES1) MINS,  
	COALESCE(AVGLCD,AWGLDC)||' - '||RTRIM(GD.A30) GLDC,  
	COALESCE(AVGLED,AWGLED)||' - '||RTRIM(GE.A30) GLEC, 
	COALESCE(AVHARM, AWHARM) HARM,  
	COALESCE(AVCLSS,AWCLSS) CLSS,  
	SUBSTR(AVCPT#,1,1) BRAND, 
	COALESCE(AVASSC,AWASSC) ASSC,
	--values-----------------------------
	AZGROP||' - '||RTRIM(BQ1TITL),
	CURRENCY,
	XR.RATE,
	SUBSTR(A249,242,2),
	XC.RATE,
	FB_QTY,
	FB_VAL_LOC,
	CASE WHEN FB_QTY = 0 THEN 0 ELSE FB_VAL_LOC/FB_QTY END,
	CALC_STATUS,
	FLAG,
	--------Version control-------------------
	DCODAT ORDERDATE,
	DDQDAT REQUESTDATE,
	DHIDAT SHIPDATE,
	0,
	0,
	0,
	'ACTUAL' VERSION					
FROM
	(

		SELECT
			------------------------status-------------------------------------------------------------------------
			F.FLAG, 
			CASE DDITST 
				WHEN 'C' THEN 
					CASE DDQTSI 
						WHEN 0 THEN 'CANCELED' 
						ELSE 'CLOSED' 
					END 
				ELSE 
					CASE F.FLAG
						WHEN 'SHIPMENT' THEN 'CLOSED' 
						ELSE CASE WHEN DDQTSI >0 THEN 'BACKORDER' ELSE 'OPEN' END 
					END 
			END CALC_STATUS, 
			-----------------------id's and flags------------------------------------------------------------------
			DDORD#, 
			DDITM#, 
			FGBOL#, 
			FGENT#, 
			DIINV#, 
			DILIN#, 
			DCODAT, 
			DDQDAT,
			DCMDAT,
			FESDAT, 
			FESIND, 
			DHIDAT, 
			DHPOST, 
			------------------------periods------------------------------------------------------------------------
			DIGITS(DHARYR)||DIGITS(DHARPR) FSPR_INV,
			------------------------attributes---------------------------------------------------------------------
			COALESCE(DHPLNT,FGPLNT,SUBSTR(DDSTKL,1,3)) PLNT,
			COALESCE(DCBCUS,DHBCS#) CUST_BILL,
			COALESCE(DCSCUS,DHSCS#) CUST_SHIP,
			COALESCE(DIGLCD, DDGLC) GL_CODE, 
			COALESCE(DIPART,DDPART) PART,
			RTRIM(DCPROM) PROMO,
			DCPO,
			DDCRRS RETURN_REAS,
			COALESCE(DHTRCD,DCTRCD) TERMS,
			CASE F.FLAG
				WHEN 'REMAINDER' THEN 
					DDQTOI-DDQTSI
				WHEN 'SHIPMENT' THEN
					FGQSHP*CASE FESIND WHEN 'Y' THEN 1 ELSE 0 END
			END FB_QTY,
			COALESCE(DHCURR,DCCURR) CURRENCY,
			CASE F.FLAG
				WHEN 'REMAINDER' THEN 
					--------remaining qty*calculated price per---------
					CASE DDQTOI 
						WHEN 0 THEN 0 
						ELSE DDTOTI/DDQTOI 
					END*(DDQTOI - DDQTSI)
				WHEN 'SHIPMENT' THEN
					---------BOL quantity * calculated price per-------
					CASE DDQTOI 
						WHEN 0 THEN 0 
						ELSE DDTOTI/DDQTOI 
					END*COALESCE(FGQSHP*CASE FESIND WHEN 'Y' THEN 1 ELSE 0 END,DDQTSI)
			END FB_VAL_LOC
		FROM
			----------------------Order Data-----------------------------
			LGDAT.OCRI 
			INNER JOIN LGDAT.OCRH ON 
				DCORD# = DDORD# 
			-----------------------BOL-----------------------------------
			LEFT OUTER JOIN LGDAT.BOLD ON 
				FGORD# = DDORD# AND 
				FGITEM = DDITM# 
			LEFT OUTER JOIN LGDAT.BOLH ON 
				FEBOL# = FGBOL#
			----------------------Invoicing------------------------------
			LEFT OUTER JOIN LGDAT.OID ON 
				DIINV# = FGINV# AND 
				DILIN# = FGLIN# 
			LEFT OUTER JOIN LGDAT.OIH ON 
				DHINV# = DIINV# 
			CROSS JOIN TABLE( VALUES
				('REMAINDER'),
				('SHIPMENT')
			) AS F(FLAG)
		WHERE
			(
				DIGITS(DHARYR)||DIGITS(DHARPR) >= '1506' AND
                DIGITS(DHARYR)||DIGITS(DHARPR) <= '1703'
			) AND
			--DAYS(DDQDAT) - DAYS(DCODAT) < 450 AND
			(	
				(F.FLAG = 'REMAINDER' AND DDQTOI-DDQTSI <> 0) OR 
				(F.FLAG = 'SHIPMENT' AND FGQSHP*CASE FESIND WHEN 'Y' THEN 1 ELSE 0 END<>0)
			)
	) O
	LEFT OUTER JOIN LGDAT.STKMM ON
		AVPART = PART
	LEFT OUTER JOIN LGDAT.STKMP ON
		AWPART = PART
	LEFT OUTER JOIN LGDAT.MAJG ON  
		BQGRP = AVMAJG  
	LEFT OUTER JOIN LGDAT.MMSL MS ON  
		MS.BSMJCD = COALESCE(AVMAJS, AWMAJS) AND  
		MS.BSMNCD = ''  
	LEFT OUTER JOIN LGDAT.MMSL NS ON  
		NS.BSMJCD = COALESCE(AVMAJS, AWMAJS) AND  
		NS.BSMNCD = COALESCE(AVMINS, AWMINS)
	LEFT OUTER JOIN LGDAT.MMGP ON  
		BRGRP = COALESCE(AVMAJG, AWMAJG) AND  
		BRMGRP = COALESCE(AVMING, AWMING)
	LEFT OUTER JOIN LGDAT.CODE GE ON  
		RTRIM(LTRIM(GE.A9)) =COALESCE(AVGLED, AWGLED) AND  
		GE.A2 = 'GE'  
	LEFT OUTER JOIN LGDAT.CODE GD ON  
		RTRIM(LTRIM(GD.A9)) = COALESCE(AVGLCD, AWGLDC) AND  
		GD.A2 = 'EE'  
	LEFT OUTER JOIN LGDAT.PLNT ON	
		YAPLNT = PLNT
	LEFT OUTER JOIN LGDAT.ADRS ON
		QZADR = YAADR#
	LEFT OUTER JOIN LGDAT.NAME N ON
		N.A7 = 'C0000'||YACOMP
	LEFT OUTER JOIN 
		(
			SELECT 
				N1COMP COMP, N1CCYY FSYR, KPMAXP PERDS, DIGITS(N1FSPP) PERD, 
				DIGITS(N1FSYP) FSPR,  
				N1SD01 SDAT, N1ED01 EDAT, 
				SUBSTR(CHAR(N1ED01),3,2)||SUBSTR(CHAR(N1ED01),6,2) CAPR,  
				N1ED01 - N1SD01 +1 NDAYS 
			  
			FROM 
				LGDAT.GLDATREF 
				INNER JOIN LGDAT.GLDATE ON 
					KPCOMP = N1COMP AND 
					KPCCYY = N1CCYY
		) GP ON
		GP.COMP = YACOMP AND
		GP.FSPR = FSPR_INV
	LEFT OUTER JOIN 
		(
			SELECT 
				N1COMP COMP, N1CCYY FSYR, KPMAXP PERDS, DIGITS(N1FSPP) PERD, 
				DIGITS(N1FSYP) FSPR,  
				N1SD01 SDAT, N1ED01 EDAT, 
				SUBSTR(CHAR(N1ED01),3,2)||SUBSTR(CHAR(N1ED01),6,2) CAPR,  
				N1ED01 - N1SD01 +1 NDAYS 
			  
			FROM 
				LGDAT.GLDATREF 
				INNER JOIN LGDAT.GLDATE ON 
					KPCOMP = N1COMP AND 
					KPCCYY = N1CCYY
		) GF ON
		GF.COMP = YACOMP AND
		GF.SDAT <= DCODAT AND
		GF.EDAT >= DCODAT
	LEFT OUTER JOIN RLARP.FFCRET XR ON
		XR.PERD = COALESCE(FSPR_INV, GF.FSPR) AND
		XR.FCUR = CURRENCY AND	
		XR.TCUR = 'US' AND
		XR.RTYP = 'MA'
	LEFT OUTER JOIN RLARP.FFCRET XC ON
		XC.PERD = COALESCE(FSPR_INV, GF.FSPR) AND
		XC.FCUR = SUBSTR(N.A249,242,2) AND
		XC.TCUR = 'US' AND
		XC.RTYP = 'MA'
	LEFT OUTER JOIN LGDAT.CUST BC ON
		BC.BVCUST = CUST_BILL
	LEFT OUTER JOIN LGDAT.CUST SC ON
		SC.BVCUST = CUST_SHIP
	LEFT OUTER JOIN 
		(
			SELECT
				MN.GRP ||' - ' ||DESCR DIRECTOR,
				LTRIM(RTRIM(A9)) RCODE,
				LTRIM(RTRIM(A9)) ||' - ' ||A30 REPP
			FROM
				LGDAT.CODE
				INNER JOIN 
				(
					SELECT
						MI.GRP, 
						MI.CODE,
						A30 DESCR
					FROM
						(
							SELECT 
								SUBSTR(LTRIM(RTRIM(A9)),1,3) GRP,
								MIN(A9) CODE
							FROM
								LGDAT.CODE
							WHERE
								A2 = 'MM'
							GROUP BY
								SUBSTR(LTRIM(RTRIM(A9)),1,3)
						)MI
						INNER JOIN LGDAT.CODE ON
							A2 = 'MM' AND
							A9 = CODE
				) MN ON
					GRP = SUBSTR(LTRIM(RTRIM(A9)),1,3)
			WHERE
				A2 = 'MM'
		) SR ON
		SR.RCODE = SC.BVSALM
	LEFT OUTER JOIN 
		(
			SELECT
				MN.GRP ||' - ' ||DESCR DIRECTOR,
				LTRIM(RTRIM(A9)) RCODE,
				LTRIM(RTRIM(A9)) ||' - ' ||A30 REPP
			FROM
				LGDAT.CODE
				INNER JOIN 
				(
					SELECT
						MI.GRP, 
						MI.CODE,
						A30 DESCR
					FROM
						(
							SELECT 
								SUBSTR(LTRIM(RTRIM(A9)),1,3) GRP,
								MIN(A9) CODE
							FROM
								LGDAT.CODE
							WHERE
								A2 = 'MM'
							GROUP BY
								SUBSTR(LTRIM(RTRIM(A9)),1,3)
						)MI
						INNER JOIN LGDAT.CODE ON
							A2 = 'MM' AND
							A9 = CODE
				) MN ON
					GRP = SUBSTR(LTRIM(RTRIM(A9)),1,3)
			WHERE
				A2 = 'MM'
		) BR ON
		BR.RCODE = BC.BVSALM
	LEFT OUTER JOIN RLARP.FFCHNL C ON
		BILL = BC.BVCLAS AND
		SHIP = SC.BVCLAS
	LEFT OUTER JOIN RLARP.FFTERR T ON
		PROV = SC.BVPRCD AND
		CTRY = SC.BVCTRY
	LEFT OUTER JOIN RLARP.FFCUST CG ON
		CUSTN = BC.BVCUST
	LEFT OUTER JOIN LGDAT.ARMASC ON
		ZWCOMP = YACOMP AND
		ZWKEY1 = BC.BVARCD AND
		ZWKEY2 = COALESCE(AVGLCD,AWGLDC) AND
		ZWPLNT = PLNT
	LEFT OUTER JOIN LGDAT.MAST ON
		AZCOMP||DIGITS(AZGL#1)||DIGITS(AZGL#2) = ZWSAL#
	LEFT OUTER JOIN LGDAT.FGRP ON
		BQ1GRP = AZGROP
	LEFT OUTER JOIN LGPGM.USRCUST ON
		CUCUST = BC.BVCUST
WHERE	
	CALC_STATUS <> 'CANCELED' AND
	FLAG <> 'REMAINDER';
	--(CALC_STATUS = 'CLOSED' AND FLAG = 'REMAINDER') = FALSE;