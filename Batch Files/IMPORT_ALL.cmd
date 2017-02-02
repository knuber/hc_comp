SETLOCAL
SET LOGDATE=%DATE:~10,4%-%DATE:~4,2%-%DATE:~7,2%_%TIME::=-%
SET LOGDATE=%LOGDATE:.=-%
SET LOGDATE=%LOGDATE: =0%
SET INCRFILE=C:\users\ptrowbridge\downloads\IMPORT_INCREMENTAL_%LOGDATE%
SET COSTFILE=C:\users\ptrowbridge\downloads\FFCOSTEFFD_UPDATE_%LOGDATE%
ECHO %INCRFILE%
ECHO %COSTFILE%

SQLCMD -S MID-SQL02 -Q "EXEC LGDAT.IMPORT_INCREMENTAL" -o %INCRFILE%
SQLCMD -S MID-SQL02 -Q "EXEC R.FFCOSTEFFD_UPDATE" -o %COSTFILE%