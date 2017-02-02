
-----------------------create table--------------------------

SELECT    
	COLUMN_NAME||' '||CASE DATA_TYPE WHEN 'CHAR' THEN 'VARCHAR' ELSE DATA_TYPE END||CASE DATA_TYPE WHEN 'DATE' THEN '' ELSE '('||LENGTH||COALESCE(','||NUMERIC_SCALE||')',')') END||',' 
FROM   
	QSYS2.SYSCOLUMNS  X 
WHERE   
	TABLE_NAME = 'STKMM' AND   
	TABLE_SCHEMA = 'LGDAT'
	
	
-----------------------column commnets------------------------

SELECT    
	'COMMENT ON COLUMN cms.'||LOWER(TABLE_NAME)||'.'||LOWER(COLUMN_NAME)||' IS '||CHR(39)||COLUMN_TEXT||CHR(39)||CHR(59)
FROM   
	QSYS2.SYSCOLUMNS  X 
WHERE   
	TABLE_NAME = 'STKMM' AND   
	TABLE_SCHEMA = 'LGDAT'
	
	
----------------------SELECT-------------------

SELECT    
	CASE DATA_TYPE
		WHEN 'CHAR' THEN 'REPLACE(REPLACE(RTRIM('||COLUMN_NAME||'),'||chr(39)||'\'||chr(39)||','||chr(39)||'\\'||chr(39)||'),'||chr(39)||'"'||chr(39)||','||chr(39)||'\"'||chr(39)||') '||COLUMN_NAME||','
		WHEN 'DATE' THEN 'CHAR('||COLUMN_NAME||') '||COLUMN_NAME||','
		ELSE COLUMN_NAME||','
	END
FROM   
	QSYS2.SYSCOLUMNS  X 
WHERE   
	TABLE_NAME = 'STKMM' AND   
	TABLE_SCHEMA = 'LGDAT'