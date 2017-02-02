CREATE OR REPLACE PROCEDURE RLARP.DYN_CING_TB_R1(IN VPERD VARCHAR(4))
	DYNAMIC RESULT SETS 1
	LANGUAGE SQL
	
	BEGIN

		DECLARE MC_MAX INT;
		DECLARE MC_CNT INT;
		DECLARE VTB VARCHAR(2);
		DECLARE VCONS VARCHAR(5);
		DECLARE MC CURSOR FOR SELECT TB, CONS FROM TABLE(RLARP.F_CONS_SEQ()) X;
		DECLARE FC CURSOR WITH RETURN TO CLIENT FOR 
		SELECT 
			W.*, F.FSTMT, F.FLVL0, F.FLVL1, F.FLVL2, F.FLVL3, H.L1, H.L2, H.L3, H.L4
		FROM 
			QTEMP.TBW W
			INNER JOIN RLARP.V_FGRP F ON
				F.FGRP = W.FGRP
			LEFT OUTER JOIN TABLE(RLARP.F_CONSH('19')) H ON	
				H.TB = W.TB
		
			
		-------temp table to hold intermediate results subject to hierarchacal operation--------
		
		INSERT INTO RLARP.FFLOG select session_user, current timestamp, 'procedure start' from sysibm.sysdummy1;
		
		
		DECLARE GLOBAL TEMPORARY TABLE  tbw(
			tb varchar(2),
			fsyr varchar(4),
			stat varchar(1),
			fgrp varchar(7),
			glcc varchar(10),
			acct varchar(12),
			curr varchar(2),
			perd varchar(4),
			ob dec(18,2),
			nt dec(18,2),
			eb dec(18,2),
			bg dec(18,2),
			fc dec(18,2)
		);



		------------insert initial result set---------------

		INSERT INTO 
			QTEMP.tbw
		SELECT
			SUBSTR(ACCT,1,2) TB,
			AJ4CCYY, 
			AZSTAT,
			AZGROP,
			AZFUT3,
			ACCT,
			AZFUT2, 
			PERD, 
			OB, 
			NT, 
			EB, 
			BG, 
			FC
		FROM	
			TABLE(RLARP.F_GLMT(VPERD,VPERD)) X
			INNER JOIN RLARP.VW_FFCOPR ON
				COMP = SUBSTR(ACCT,1,2)
		WHERE
			CONS LIKE 'TB%';
		
		
		INSERT INTO RLARP.FFLOG select session_user, current timestamp, 'records inserted' from sysibm.sysdummy1;

		-------------------sequential consolidation list from hierachy----------------
		
		--F_CONS_SEQ gives in the correct order the sequence of consolidation steps
		--the CONS field indicates if the consolidation is either an elimination of and IC balance
		--or or a currency translation
		SELECT COUNT(*) INTO MC_MAX FROM TABLE(RLARP.F_CONS_SEQ()) X;
		INSERT INTO RLARP.FFLOG select session_user, current timestamp, 'count temp file records '||mc_max from sysibm.sysdummy1;
		SET MC_CNT = 0;
		OPEN MC;
		INSERT INTO RLARP.FFLOG select session_user, current timestamp, 'open cursor' from sysibm.sysdummy1;
		WHILE MC_CNT < MC_MAX DO
			INSERT INTO RLARP.FFLOG select session_user, current timestamp, 'while condition evaluated' from sysibm.sysdummy1;
			FETCH MC INTO VTB, VCONS;
			INSERT INTO RLARP.FFLOG select session_user, current timestamp, 'fetch compelte' from sysibm.sysdummy1;
			SET MC_CNT = MC_CNT + 1;
			INSERT INTO RLARP.FFLOG select session_user, current timestamp, 'index counter' from sysibm.sysdummy1;
			IF SUBSTR(VCONS,1,2) = 'IC' THEN
				---------------ELIMINATIONS---------------------------
				INSERT INTO
					QTEMP.TBW
				SELECT 
					SUBSTR(DIGITS(D35USR4),9,2) TB, 
					FSYR, 
					STAT,
					CASE OS.FLAG
						WHEN 'CLEAR' THEN FGRP
						ELSE D35USR2 
					END FGRP,
					GLCC, 
					W.ACCT,
					CURR,
					PERD, 
					SUM(CASE OS.FLAG WHEN 'CLEAR' THEN -OB ELSE OB END) OB, 
					SUM(CASE OS.FLAG WHEN 'CLEAR' THEN -NT ELSE NT END) NT, 
					SUM(CASE OS.FLAG WHEN 'CLEAR' THEN -EB ELSE EB END) EB, 
					SUM(CASE OS.FLAG WHEN 'CLEAR' THEN -BG ELSE BG END) BG, 
					SUM(CASE OS.FLAG WHEN 'CLEAR' THEN -FC ELSE FC END) FC
				FROM 
					QTEMP.TBW W
					INNER JOIN LGDAT.GGTP G ON
						D35GCDE = W.GLCC	
					CROSS JOIN TABLE(VALUES 
						('CLEAR'),
						('OFFSET')
					) AS OS(FLAG)
				WHERE
					SUBSTR(DIGITS(D35USR4),9,2) = VTB AND
					D35USR4 <> 0 AND
					FGRP <> D35USR2
				GROUP BY
					SUBSTR(DIGITS(D35USR4),9,2), 
					FSYR, 
					STAT,
					CASE OS.FLAG
						WHEN 'CLEAR' THEN FGRP
						ELSE D35USR2 
					END,
					GLCC, 
					W.ACCT,
					CURR,
					PERD;
				INSERT INTO RLARP.FFLOG select session_user, current timestamp, 'insert elimination records' from sysibm.sysdummy1;
			ELSEIF SUBSTR(VCONS,1,2) = 'FX' THEN
				---------------CURRENCY TRANSLATION-------------------
				INSERT INTO 
					QTEMP.TBW
				SELECT
					VTB, 
					FSYR, 
					STAT, 
					CASE CF.FLAG WHEN 'ADJ' THEN W.FGRP ELSE '33020' END FGRP, 
					CASE CF.FLAG WHEN 'ADJ' THEN GLCC ELSE 'E00' END GLCC, 
					W.ACCT,
					W.CURR,
					W.PERD,  
					SUM(ROUND(OB*RATE-OB,2)*CASE FLAG WHEN 'OFFSET' THEN - 1 ELSE 1 END) OB, 
					SUM(ROUND(NT*RATE-NT,2)*CASE FLAG WHEN 'OFFSET' THEN - 1 ELSE 1 END) NT, 
					SUM(ROUND(EB*RATE-EB,2)*CASE FLAG WHEN 'OFFSET' THEN - 1 ELSE 1 END) EB, 
					SUM(ROUND(BG*RATE-BG,2)*CASE FLAG WHEN 'OFFSET' THEN - 1 ELSE 1 END) BG,
					SUM(ROUND(FC*RATE-FC,2)*CASE FLAG WHEN 'OFFSET' THEN - 1 ELSE 1 END) FC
				FROM
					TABLE(RLARP.F_CHILD_TB(VTB)) X
					INNER JOIN QTEMP.TBW W ON
						W.TB = X.COMP
					CROSS JOIN TABLE( VALUES
						('ADJ'),
						('OFFSET')
					) AS CF(FLAG)
					INNER JOIN RLARP.VW_FFCOPR CP ON
						CP.COMP = VTB
					LEFT OUTER JOIN RLARP.FFCRET E ON
						E.FCUR = W.CURR AND
						E.TCUR = CP.CURR AND
						E.RTYP = CASE WHEN SUBSTRING(W.FGRP,1,1) <= '3' THEN 'ME' ELSE 'MA' END AND
						E.PERD = W.PERD
				GROUP BY
					VTB, FSYR, STAT, 
					CASE CF.FLAG WHEN 'ADJ' THEN W.FGRP ELSE '33020' END, 
					CASE CF.FLAG WHEN 'ADJ' THEN GLCC ELSE 'E00' END, 
					W.ACCT,
					W.CURR,
					W.PERD;
				INSERT INTO RLARP.FFLOG select session_user, current timestamp, 'insert translation records' from sysibm.sysdummy1;
			END IF;
			INSERT INTO RLARP.FFLOG select session_user, current timestamp, 'end if' from sysibm.sysdummy1;
		END WHILE;
		INSERT INTO RLARP.FFLOG select session_user, current timestamp, 'end while' from sysibm.sysdummy1;
		CLOSE MC;
		INSERT INTO RLARP.FFLOG select session_user, current timestamp, 'close mc' from sysibm.sysdummy1;
		OPEN FC;

	END;