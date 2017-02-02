CREATE OR REPLACE VIEW RLARP.VVDH AS
SELECT
	SYSTEM_VIEW_SCHEMA PLIB,
	SYSTEM_VIEW_NAME PVW,
	SYSTEM_TABLE_SCHEMA CLIB,
	SYSTEM_TABLE_NAME CVW
FROM	
	RLARP.SYSVIEWDEP
WHERE	
	SUBSTR(SYSTEM_VIEW_NAME,1,3) <> 'SYS'