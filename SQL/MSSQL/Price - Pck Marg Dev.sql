SELECT
	ORDER_NUMBER,
	ORDER_LINE,
	ORDER_DATE,
	SEASON_YEAR,
	SEASON_PERIOD,
	DCPO,
	PROMO_CODE,
	PREPAID_COLLECT,
	STAT,
	BILL_REMIT_TO,
	BILL_CUST_CLASS,
	BILL_CUST,
	SHIP_CUST_CLASS,
	SHIP_CUST,
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
	DEST_ADRS,
	PART,
	MOLD,
	QTY,
	UOM,
	CURRENCY,
	PLNT,
	GL_CODE,
	MAJG,
	MING,
	GLED,
	BRANDING,
	ORD_AMT_LOCAL,
	ORD_AMT_USD,
	ORD_COST_LOCAL,
	ORD_COST_USD,
	ORD_TERMS,
	PAYDATE,
	PAYDAYS,
	DISCP,
	DISCDAYS,
	TERMS_RATE,
	TERMS_EXT_USD,
	PCS_PLT,
	PALLETS,
	MILES,
	CPM_L,
	CPM_P,
	FREIGHT_PT,
	ROADMILES,
	RATE,
	MINIMUMCHARGE,
	FREIGHT_PQ,
	PTCRED_RATE,
	CRED_EXT_USD,
	PTREBT_RATE,
	REBT_EXT_USD,
	MCREDIT_RATE,
	MCREDIT_EXT_USD,
	MREBATE_RATE,
	MREBATE_EXT_USD,
	TARGET_GROSS_MARGIN,
	MATCH_FLAG,
	TARGET_REVENUE,
	SEG_AMT,
	SEG_QTY,
	SEG_CST,
	SEG_FRT,
	SEG_CRD,
	SEG_RBT,
	SEG_TRM,
	SEG_SHIPTO_AMT,
	SEG_SHIPTO_QTY,
	SEG_SHIPTO_CST,
	SEG_SHIPTO_FRT,
	SEG_SHIPTO_CRD,
	SEG_SHIPTO_RBT,
	SEG_SHIPTO_TRM,
	MAX(SEG_SHIPTO_QTY) OVER (PARTITION BY SUBSTRING(PART,1,11), BRANDING, GEO ,CHAN, SEASON_YEAR) MAX_SEG_SHIPTO_QTY
FROM
	(
	SELECT
		ORDER_NUMBER,
		ORDER_LINE,
		ORDER_DATE,
		SEASON_YEAR,
		SEASON_PERIOD,
		DCPO,
		PROMO_CODE,
		PREPAID_COLLECT,
		STAT,
		BILL_REMIT_TO,
		BILL_CUST_CLASS,
		BILL_CUST,
		SHIP_CUST_CLASS,
		SHIP_CUST,
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
		DEST_ADRS,
		PART,
		MOLD,
		QTY,
		UOM,
		CURRENCY,
		PLNT,
		GL_CODE,
		MAJG,
		MING,
		GLED,
		BRANDING,
		ORD_AMT_LOCAL,
		ORD_AMT_USD,
		ORD_COST_LOCAL,
		ORD_COST_USD,
		ORD_TERMS,
		PAYDATE,
		PAYDAYS,
		DISCP,
		DISCDAYS,
		TERMS_RATE,
		TERMS_EXT_USD,
		PCS_PLT,
		PALLETS,
		MILES,
		CPM_L,
		CPM_P,
		FREIGHT_PT,
		ROADMILES,
		RATE,
		MINIMUMCHARGE,
		FREIGHT_PQ,
		PTCRED_RATE,
		CRED_EXT_USD,
		PTREBT_RATE,
		REBT_EXT_USD,
		MCREDIT_RATE,
		MCREDIT_EXT_USD,
		MREBATE_RATE,
		MREBATE_EXT_USD,
		TARGET_GROSS_MARGIN,
		MATCH_FLAG,
		TARGET_REVENUE,
		SUM(ORD_AMT_USD) OVER 		(PARTITION BY SUBSTRING(PART,1,11), BRANDING, GEO ,CHAN, SEASON_YEAR) SEG_AMT,
		SUM(QTY) OVER 			(PARTITION BY SUBSTRING(PART,1,11), BRANDING, GEO ,CHAN, SEASON_YEAR) SEG_QTY,
		SUM(ORD_COST_USD) OVER 		(PARTITION BY SUBSTRING(PART,1,11), BRANDING, GEO ,CHAN, SEASON_YEAR) SEG_CST,
		SUM(FREIGHT_PQ) OVER 		(PARTITION BY SUBSTRING(PART,1,11), BRANDING, GEO ,CHAN, SEASON_YEAR) SEG_FRT,
		SUM(CRED_EXT_USD) OVER 		(PARTITION BY SUBSTRING(PART,1,11), BRANDING, GEO ,CHAN, SEASON_YEAR) SEG_CRD,
		SUM(MREBATE_EXT_USD) OVER 	(PARTITION BY SUBSTRING(PART,1,11), BRANDING, GEO ,CHAN, SEASON_YEAR) SEG_RBT,
		SUM(TERMS_EXT_USD) OVER 	(PARTITION BY SUBSTRING(PART,1,11), BRANDING, GEO ,CHAN, SEASON_YEAR) SEG_TRM,
		SUM(ORD_AMT_USD) OVER 		(PARTITION BY SUBSTRING(PART,1,11), BRANDING, GEO ,CHAN, SEASON_YEAR, SHIP_CUST) SEG_SHIPTO_AMT,
		SUM(QTY) OVER 			(PARTITION BY SUBSTRING(PART,1,11), BRANDING, GEO ,CHAN, SEASON_YEAR, SHIP_CUST) SEG_SHIPTO_QTY,
		SUM(ORD_COST_USD) OVER 		(PARTITION BY SUBSTRING(PART,1,11), BRANDING, GEO ,CHAN, SEASON_YEAR, SHIP_CUST) SEG_SHIPTO_CST,
		SUM(FREIGHT_PQ) OVER 		(PARTITION BY SUBSTRING(PART,1,11), BRANDING, GEO ,CHAN, SEASON_YEAR, SHIP_CUST) SEG_SHIPTO_FRT,
		SUM(CRED_EXT_USD) OVER 		(PARTITION BY SUBSTRING(PART,1,11), BRANDING, GEO ,CHAN, SEASON_YEAR, SHIP_CUST) SEG_SHIPTO_CRD,
		SUM(MREBATE_EXT_USD) OVER 	(PARTITION BY SUBSTRING(PART,1,11), BRANDING, GEO ,CHAN, SEASON_YEAR, SHIP_CUST) SEG_SHIPTO_RBT,
		SUM(TERMS_EXT_USD) OVER 	(PARTITION BY SUBSTRING(PART,1,11), BRANDING, GEO ,CHAN, SEASON_YEAR, SHIP_CUST) SEG_SHIPTO_TRM
	FROM 
		(
				SELECT
				-------------------Order Data------------------------------------------

					DDORD# ORDER_NUMBER,
					DDITM# ORDER_LINE,
					DCODAT ORDER_DATE,
					SSYR SEASON_YEAR, 
					SSPR SEASON_PERIOD, 
					DCPO, 
					DCPROM PROMO_CODE,
					DCPPCL PREPAID_COLLECT,
					--line item status. if ddqtsi = 'C' then it's either closed or canceled. 
					--if the ship quantity is -0- then it's canceled, otherwise closed and the ship quantity should be used as the final qty
					CASE DDITST
						WHEN 'C' THEN 
							CASE DDQTSI 
								WHEN 0 THEN 'CANCELED' 
								ELSE 'CLOSED' 
							END 
						ELSE 
							CASE 
								WHEN DDQTSI >0 THEN 'BACKORDER' 
								ELSE 'OPEN' 
							END 
					END STAT,

				-----------------Customer & Shipment Data--------------------------------
					--bill-to
					BC.BVCOMP BILL_REMIT_TO,
 					BC.BVCLAS BILL_CUST_CLASS, 
 					BC.BVCUST+' - '+RTRIM(BC.BVNAME) BILL_CUST, 

					--ship-to
 					SC.BVCLAS SHIP_CUST_CLASS, 
 					SC.BVCUST+' - '+RTRIM(SC.BVNAME) SHIP_CUST,

					--scenario
					COALESCE(CG.CGRP,BC.BVNAME) ACCOUNT,
					COALESCE(T.GEO,'UNDEFINED') GEO, 
					COALESCE(C.CHAN,'UNDEFINED') CHAN,

					--location
					QZCRYC ORIG_CTRY,
					QZPROV ORIG_PROV,
					SUBSTRING(QZPOST,1,3) ORIG_LANE,
					QZPOST ORIG_POST,
					SC.BVCTRY DEST_CTRY,
					SC.BVPRCD DEST_PROV,
					SUBSTRING(SC.BVPOST,1,3) DEST_LANE,
					SC.BVPOST DEST_POST,
					RTRIM(SC.BVADR1) +' '+ RTRIM(SC.BVADR2) + ' '+ RTRIM(SC.BVADR3) + ' '+ RTRIM(SC.BVADR4) DEST_ADRS,

				-------------------------------------Item Data----------------------------------------------

					DDPART PART,
					SUBSTRING(DDPART,1,8) MOLD,
					CASE DDITST 
						WHEN 'C' THEN 
							CASE DDQTSI 
								WHEN 0 THEN DDQTOI 
								ELSE DDQTSI 
							END 
						ELSE DDQTOI 
					END QTY,
					V6UNTI UOM,
					DCCURR CURRENCY,
					SUBSTRING(DDSTKL, 1, 3) PLNT,
					DDGLC GL_CODE,
					COALESCE(AVMAJG,AWMAJG) MAJG,
					COALESCE(AVMING,AWMING) MING,
					COALESCE(AVGLED,AWGLED) GLED,
					CASE COALESCE(AVMING,AWMING)
						WHEN 'B10' THEN 'BRANDED'
						WHEN 'B11' THEN 'BRANDED'
						WHEN 'B52' THEN 'BRANDED'
						ELSE 'UNBRANDED'
					END BRANDING,


				-----------------------------------------Order Value------------------------------------------------
		
					--order amount. if quantity ordered is -0- then set order value to -0- as well
					ROUND(
						CASE DDQTOI 
							WHEN 0 THEN 0 
							ELSE 
								CASE DDITST 
									WHEN 'C' THEN 
										CASE DDQTSI 
											WHEN 0 THEN DDTOTI
											ELSE (DDQTSI/DDQTOI)*DDTOTI
										END 
									ELSE DDTOTI
								END 
						END
					,2) ORD_AMT_LOCAL, 

					--ORDER VALUE IN USD
					ROUND(
						CASE DDQTOI 
							WHEN 0 THEN 0 
							ELSE 
								CASE DDITST 
									WHEN 'C' THEN 
										CASE DDQTSI 
											WHEN 0 THEN DDTOTI
											ELSE (DDQTSI/DDQTOI)*DDTOTI
										END 
									ELSE DDTOTI
								END 
						END
						*XO.RATE
					,2) ORD_AMT_USD, 

				-----------------------------------------Standard Costs------------------------------------------------

					--standard material & labor costs
					ROUND(
						--if status is closed then used ship qty else use order qty
						CASE DDITST 
							WHEN 'C' THEN 
								CASE DDQTSI 
									WHEN 0 THEN DDQTOI 
									ELSE DDQTSI 
								END 
							ELSE DDQTOI 
						END*
						--material & labor std cost @ current definition
						(
							COALESCE(CGMATS,CHSUC,Y0SMAT)
							--+COALESCE(CGLABS,Y0SLAB,0)
						)
					,2) ORD_COST_LOCAL,
				ROUND(
					CASE DDITST 
						WHEN 'C' THEN 
							CASE DDQTSI 
								WHEN 0 THEN DDQTOI 
								ELSE DDQTSI 
							END 
						ELSE DDQTOI 
					END*
					(
						COALESCE(CGMATS,CHSUC,Y0SMAT)
						--+COALESCE(CGLABS,Y0SLAB,0)
					)*XC.RATE
				,2) ORD_COST_USD,

				-----------------------------------------Terms------------------------------------------------

					DCTRCD+' - '+RTRIM(TC.DESCR) ORD_TERMS, 
 					PAYDATE, 
 					PAYDAYS, 
 					DISCP, 
 					DISCDAYS,
					--choose the most beneficial terms offered if discount period available
					-dbo.LEAST(
							(
								(
									--deviation from 30 days is the basis for benefit extended
									30.0-
									--the difference between the paydate and the promise date (as a proxy for invoice date) is terms offered
									CASE PAYDATE 
										WHEN '' THEN PAYDAYS 
										ELSE DATEDIFF(D,PAYDATE,DCMDAT) 
									END
								)/30.0
							)*.01,
							(30.0 - DISCDAYS)/30.0*.01
							-COALESCE(DISCP,0.0)
					) TERMS_RATE,
					ROUND(
						-dbo.LEAST(
							(
								(
									30.0-
									CASE PAYDATE 
										WHEN '' THEN PAYDAYS 
										ELSE DATEDIFF(D,PAYDATE,DCMDAT) 
									END
								)/30.0
							)*.01,
							(30.0 - DISCDAYS)/30.0*.01
							-COALESCE(DISCP,0.0)
						)*
						CASE DDQTOI 
							WHEN 0 THEN 0 
							ELSE 
								CASE DDITST 
									WHEN 'C' THEN 
										CASE DDQTSI 
											WHEN 0 THEN DDTOTI
											ELSE (DDQTSI/DDQTOI)*DDTOTI
										END 
									ELSE DDTOTI
								END 
						END
						*XO.RATE
					,2) TERMS_EXT_USD,

				----------------------------Freight (PT calculation)--------------------------------------------------

					V6MPCK PCS_PLT,
					CASE 
						WHEN COALESCE(V6MPCK,0) <= 0 THEN 0 
						ELSE 
							CASE DDITST 
								WHEN 'C' THEN 
									CASE DDQTSI 
										WHEN 0 THEN DDQTOI 
										ELSE DDQTSI 
									END 
								ELSE DDQTOI 
							END
							/V6MPCK 
					END PALLETS,
					FD.MILES,
					FL.RATE CPM_L,
					FS.RATE CPM_P,
					COALESCE(
						ROUND(
							-------freight cost per pallet-----
							(
								COALESCE(FD.MILES,PQF.RoadMiles)*
								COALESCE(FL.RATE,FS.RATE,PQF.Rate)
								--pallets per truck assumed at 24
								/24
							)*
							------number of pallets----------
							(
								CASE 
									WHEN COALESCE(V6MPCK,0) <= 0 THEN 0 
									ELSE 
										CASE DDITST 
											WHEN 'C' THEN 
												CASE DDQTSI 
													WHEN 0 THEN DDQTOI 
													ELSE DDQTSI 
												END 
											ELSE DDQTOI 
										END
										/V6MPCK 
								END
							)
						,2)* 
						-----if the order is not prepaid then freight should be -0-
						CASE 
							WHEN DCPPCL = 'P' THEN 1 
							ELSE 0 
						END
						--in case of null coalesce against -0-
						,0
					) FREIGHT_PT,

				-------------------------Quote Tool Freight-------------------------------------
					ROADMILES,
					PQF.RATE,
					MINIMUMCHARGE,
					COALESCE(
						(
							COALESCE(FREIGHTCOST,COALESCE(PQF.RoadMiles,FD.MILES)*COALESCE(PQF.Rate,FL.RATE, FS.RATE))/24
						)
						*CASE 
							WHEN COALESCE(V6MPCK,0) <= 0 THEN 0 
							ELSE 
								CASE DDITST 
									WHEN 'C' THEN 
										CASE DDQTSI 
											WHEN 0 THEN DDQTOI 
											ELSE DDQTSI 
										END
									ELSE DDQTOI 
								END
								/V6MPCK 
						END
						*CASE 
							WHEN DCPPCL = 'P' THEN 1 
							ELSE 0 
						END
						--coalesce against -0- in case of null
						,0
					) FREIGHT_PQ,

				------------------------Credits & Rebates-------------------------------------------------

					--pt credits
					COALESCE(CRED,0) PTCRED_RATE,
					ROUND(
						COALESCE(CRED,0)*
						CASE DDQTOI 
							WHEN 0 THEN 0 
							ELSE 
								CASE DDITST 
									WHEN 'C' THEN 
										CASE DDQTSI 
											WHEN 0 THEN DDTOTI
											ELSE (DDQTSI/DDQTOI)*DDTOTI
										END 
									ELSE DDTOTI
								END 
						END
						*XO.RATE
					,2) CRED_EXT_USD,
					--pt rebates
					COALESCE(REBT,0) PTREBT_RATE,
					ROUND(
						COALESCE(REBT,0)*
						CASE DDQTOI 
							WHEN 0 THEN 0 
							ELSE 
								CASE DDITST 
									WHEN 'C' THEN 
										CASE DDQTSI 
											WHEN 0 THEN DDTOTI
											ELSE (DDQTSI/DDQTOI)*DDTOTI
										END 
									ELSE DDTOTI
								END 
						END
						*XO.RATE
					,2) REBT_EXT_USD,
					--pricequote tool credits
					COALESCE(MCREDIT,0) MCREDIT_RATE,
					ROUND(
						CASE DDQTOI 
							WHEN 0 THEN 0 
							ELSE 
								CASE DDITST 
									WHEN 'C' THEN 
										CASE DDQTSI 
											WHEN 0 THEN DDTOTI
											ELSE (DDQTSI/DDQTOI)*DDTOTI
										END 
									ELSE DDTOTI
								END 
						END
						*XO.RATE
					,2)
					*COALESCE(MCREDIT,0) MCREDIT_EXT_USD,
					--pricequote tool rebates
					COALESCE(MREBATE,0) MREBATE_RATE,
					ROUND(
						CASE DDQTOI 
							WHEN 0 THEN 0 
							ELSE 
								CASE DDITST 
									WHEN 'C' THEN 
										CASE DDQTSI 
											WHEN 0 THEN DDTOTI
											ELSE (DDQTSI/DDQTOI)*DDTOTI
										END 
									ELSE DDTOTI
								END 
						END
						*XO.RATE
					,2)
					*COALESCE(MREBATE,0) MREBATE_EXT_USD,
					--target margin
					COALESCE(TMH.TM, TMC.TM) TARGET_GROSS_MARGIN,

				----------------------------Issues Call-Out-----------------------------------------
	
				--Freight
					CASE COALESCE(COALESCE(FREIGHTCOST,COALESCE(PQF.RoadMiles,FD.MILES)*COALESCE(PQF.Rate,FL.RATE, FS.RATE)),0)
						WHEN 0 THEN 'NO FREIGHT' 
						ELSE '' 
					END+
				--Target out of range
					CASE 
						WHEN COALESCE(TMH.TM, TMC.TM) < .01 THEN 'BAD TARGET' 
						WHEN COALESCE(TMH.TM, TMC.TM) > .95 THEN 'BAD TARGET' 
						ELSE '' 
					END+
				--No Target
					CASE ISNULL(COALESCE(TMH.TM, TMC.TM),0) 
						WHEN 0 THEN 'NO TARGET' 
						ELSE '' 
					END MATCH_FLAG,
				--------------------------------TARGET PRICE----------------------------------------
				(
					--Target Gross Margin
					(	
						--Std Mat & Labor Cost
						(
							CASE DDITST 
								WHEN 'C' THEN 
									CASE DDQTSI 
										WHEN 0 THEN DDQTOI 
										ELSE DDQTSI 
									END 
								ELSE DDQTOI 
							END*
							(
								COALESCE(CGMATS,CHSUC,Y0SMAT)+
								COALESCE(CGLABS,Y0SLAB,0)
							)
						)/
						--Target Margin
						(
							-COALESCE(TMH.TM, TMC.TM)+1
						)
					)+
					--Add Freight Cost
					(
						(
							COALESCE(FREIGHTCOST,0)/24
						)*
						CASE 
							WHEN COALESCE(V6MPCK,0) <= 0 THEN 0 
							ELSE 
								CASE DDITST 
									WHEN 'C' THEN 
										CASE DDQTSI 
											WHEN 0 THEN DDQTOI 
											ELSE DDQTSI 
										END 
									ELSE DDQTOI 
								END/
								V6MPCK 
						END* 
						CASE WHEN DCPPCL = 'P' THEN 1 ELSE 0 END
					)
				)/
				--Factor up gross margin + freight by terms, credits, & discounts rates
				(
					1-
					COALESCE(MCREDIT,0)-   --(%)
					COALESCE(MREBATE,0)-   --(%)
					---Terms value added  (%)
					dbo.LEAST(
						--Straight Pay Days Benefit > 30 days
						(
							(
								30.0-
								CASE PAYDATE 
									WHEN '' THEN PAYDAYS 
									ELSE DATEDIFF(D,PAYDATE,DCMDAT) 
								END
							)
							/30.0
						)*.01,
						--Discount Benefit
						(30.0 - DISCDAYS)/
						30.0*.01-
						COALESCE(DISCP,0.0)
					)
				) TARGET_REVENUE
	
			FROM

				---------------Order Data---------------

				LGDAT.OCRI
				INNER JOIN LGDAT.OCRH ON
					DCORD# = DDORD#

				---------------Item Master Data---------

				LEFT OUTER JOIN LGDAT.STKA ON
					V6PART = DDPART AND
					V6PLNT = SUBSTRING(DDSTKL, 1, 3)

				LEFT OUTER JOIN LGDAT.STKMM ON
					AVPART = DDPART

				LEFT OUTER JOIN LGDAT.STKMP ON
					AWPART = DDPART

				LEFT OUTER JOIN LGDAT.ICSTM ON
					CGPART = DDPART AND
					CGPLNT = SUBSTRING(DDSTKL,1,3)

				LEFT OUTER JOIN LGDAT.ICSTP ON
					CHPART = DDPART AND
					CHPLNT = SUBSTRING(DDSTKL,1,3)

				LEFT OUTER JOIN LGDAT.ICSTR ON
					Y0PART = DDPART AND
					Y0PLNT = SUBSTRING(DDSTKL,1,3)

				---------------Customer Data-------------

				LEFT OUTER JOIN CMSINTERFACEIN.LGDAT.CUST BC ON
					DCBCUS = BC.BVCUST

				LEFT OUTER JOIN CMSINTERFACEIN.LGDAT.CUST SC ON
					DCSCUS = SC.BVCUST

				LEFT OUTER JOIN R.FFTERR T ON
					PROV = SC.BVPRCD AND
					CTRY = SC.BVCTRY AND
					T.VERS = 'INI'

				LEFT OUTER JOIN R.FFCHNL C ON
					BILL = BC.BVCLAS AND
					SHIP = SC.BVCLAS AND
					C.VERS = 'INI'

				LEFT OUTER JOIN R.FFCUST CG ON		
					CG.CUSTN = DCBCUS

				LEFT OUTER JOIN R.FFCRED CR ON
					CR.CUSTG = COALESCE(CG.CGRP,BC.BVCUST+' - '+RTRIM(BC.BVNAME)) AND
					CR.VERS = '1516'

				--------------Plant Data------------------

				LEFT OUTER JOIN LGDAT.PLNT P ON
					P.YAPLNT = SUBSTRING(DDSTKL,1,3)

				LEFT OUTER JOIN LGDAT.ADRS ON
					QZADR = YAADR#

				LEFT OUTER JOIN R.FRDIST FD ON
					--FD.SRCE = 'TMS' AND
					FD.LEVL = 'POSTAL' AND
					FD.ORIG =	CASE QZCTRY 
									WHEN 'CAN' THEN SUBSTRING(REPLACE(REPLACE(QZPOST,'-',''),' ',''),1,3)  + ' ' +  SUBSTRING(REPLACE(REPLACE(QZPOST,'-',''),' ',''),4,3)
									WHEN 'USA' THEN SUBSTRING(QZPOST,1,5)
									ELSE REPLACE(QZPOST,'-',' ')
								END AND
					FD.DEST =	CASE SC.BVCTRY
									WHEN 'CAN' THEN SUBSTRING(REPLACE(REPLACE(SC.BVPOST,'-',''),' ',''),1,3)  + ' ' +  SUBSTRING(REPLACE(REPLACE(SC.BVPOST,'-',''),' ',''),4,3)
									WHEN 'USA' THEN SUBSTRING(REPLACE(SC.BVPOST,'-',' '),1,5)
									ELSE REPLACE(SC.BVPOST,'-',' ')
								END
				LEFT OUTER JOIN R.FRRATE FL ON
					FL.LEVL = 'LANE' AND
					FL.ORIG = SUBSTRING(QZPOST,1,3) AND
					FL.DEST = SUBSTRING(SC.BVPOST,1,3)
				LEFT OUTER JOIN R.FRRATE FS ON
					FS.LEVL = 'STATE' AND
					FS.ORIG = RTRIM(QZPROV) AND
					FS.DEST = RTRIM(SC.BVPRCD)

				-----------------------Company Periods-----------------------------------------

				LEFT OUTER JOIN R.PLPR PL ON
					PL.YAPLNT = SUBSTRING(DDSTKL,1,3)

				LEFT OUTER JOIN R.GLDATREF PD ON
					YACOMP = PD.N1COMP AND
					PD.N1SD01 <= DCODAT AND
					PD.N1ED01 >= DCODAT

				-----------------------Order Currency Conversion-------------------------------

 				LEFT OUTER JOIN R.FFCRET XO ON 
 	 				XO.FCUR = DCCURR AND 
 	 				XO.TCUR = 'US' AND 
					XO.RTYP = 'MA' AND 
					XO.PERD = SUBSTRING(CAST(N1CCYY AS VARCHAR(4)),3,2)+FORMAT(N1FSPP,'00')


				-----------------------Inventory Currency Conversion---------------------------

				LEFT OUTER JOIN R.FFCRET XC ON 
 	 				XC.FCUR = PL.CURR AND 
 	 				XC.TCUR = 'US' AND 
					XC.RTYP = 'MA' AND 
					XC.PERD = SUBSTRING(CAST(N1CCYY AS VARCHAR(4)),3,2)+FORMAT(N1FSPP,'00')

				-----------------------Terms--------------------------------------------------

				LEFT OUTER JOIN R.TMCD TC ON 
					TERM = DCTRCD

				-----------------------PriceQuote Files----------------------------------------

				LEFT OUTER JOIN PRICEQUOTE.DBO.FREIGHT PQF ON
					CUSTOMERNUMBER = DCSCUS AND
					MANUFACTURESOURCE = SUBSTRING(DDSTKL,1,3)

				LEFT OUTER JOIN PRICEQUOTE.DBO.CREDIT CRD ON
					CRD.BILLTONUMBER = DCBCUS

				LEFT OUTER JOIN PRICEQUOTE.DBO.REBATE RBT ON
					RBT.BILLTONUMBER = DCBCUS

				LEFT OUTER JOIN PRICEQUOTE.DBO.STANDARDTARGETPRICEHISTORY TMH ON
					TMH.PARTNUMBER = SUBSTRING(DDPART,1,8) AND
					TMH.GEO = T.GEO AND
					TMH.CHAN = C.CHAN AND
					TMH.EFFECTIVEFROM <= DCODAT AND
					COALESCE(EFFECTIVETO,CURRENT_TIMESTAMP) >= DCODAT

				LEFT OUTER JOIN PRICEQUOTE.DBO.STANDARDTARGETPRICE TMC ON
					TMC.PARTNUMBER = SUBSTRING(DDPART,1,8) AND
					TMC.GEO = T.GEO AND
					TMC.CHAN = C.CHAN
			WHERE
				DCODAT >= '2016-06-01' AND
				BC.BVCLAS NOT IN ('SALE','INTC','INTR') AND
				DDQTOI <> 0 AND
				DDTOTI <> 0 AND
				DCBCUS <> 'MISC0001' AND
				DCSCUS <> 'MISC0001' AND
				DCSCUS <> 'MISC0003' AND
				DDPART <> '' AND
				CASE DDITST WHEN 'C' THEN 
					CASE DDQTSI WHEN 0 THEN 'CANCELED' ELSE 'CLOSED' END 
					ELSE CASE WHEN DDQTSI >0 THEN 'BACKORDER' ELSE 'OPEN' END 
				END <> 'CANCELED' AND
				SUBSTRING(COALESCE(AWGLED, AVGLED),1,1) <= '2'
		) x
	) WS
OPTION (MAXDOP 8)