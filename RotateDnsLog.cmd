@ECHO OFF && SETLOCAL ENABLEDELAYEDEXPANSION && ECHO ROTATE DNS LOG FILE && ECHO.


::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::: Name         :: RotateDnsLog.cmd
::: Version      :: 1.1
::: License      :: MIT
::: Author       :: Bouke J. Henstra

::: Description  :: This is a complete rewrite of Moonpoint's rotate DNS batch file. 
                 :: The location of the original batch file is: http://support.moonpoint.com/downloads/computer_languages/mswin_batch/rotatednslog.bat

::: Disclaimer   :: The author does not assume any liability for direct, indirect, material or immaterial damages that may arise from the use of the provided software and/or (other) materials. 
                 :: Subject to the foregoing, the use of the provided software and/or (other) materials  is at the user's own personal risk.
                 :: Some jurisdictions may not permit certain disclaimers of warranties, so some of the exclusions above may not apply to you. 
                 :: In such jurisdictions, we disclaim warranties to the fullest extent permitted by applicable law.

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


::: ReadMe       :: ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
    ::: When scheduled to run [eg at the end of each day], this batch file will roate the DNS server log. The DNS server service will be stopped temporarily, so the current DNS log can be renamed to a log file 
    ::: with the name dnslog_YYYYMMDD.ext, where YYYY is the year, MM the month, DD the day. The DNS server service will then be restarted creating a new DNS log file. 
    ::: The current location of the DNS log file is obtained from the Windows Registry. 
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


::: Variables    :: ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
    ::: You can adjust the variables below. 
    ::: 7-Zip from https://www.7-zip.org/ is used to cmpress the rotated log files (but it's not a requirement to run this batch file).
    ::: It's a good idea to purge rotated logs after some time. 

::: Compress rotated DNS log file? Options: 'yes' or 'no'
    ::: Note: this requires 7-Zip: 7z.exe
    set compress=yes

::: Purge rotated log fils? Options: 'yes' or 'no'
    SET purgelogs=yes
::: Purge rotated log files after nn days, eg 90
    set purgelogsdays=90
::: Purge extension
    set purgeext=7z

::: Binaries
    ::: 7-zip
        ::: 7z.exe is required to compress the log file after it has been rotated.
                set exec7z=7z.exe
                set path7z=%ProgramFiles%\7-zip
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
			
			
::: Do stuff     :: ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

::: Windows Registry key holding the location of the DNS log file
     SET regkey="HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\DNS\Parameters"
     ::: Extract value from registry key
         for /f "tokens=2*" %%a in ('reg query "%regkey%" /v LogFilePath 2^>^&1^|find "REG_"') do @set regvalue=%%b
         ::: Stop if DNS log file not found...
		     if "%regvalue%"=="" echo DNS log file not found. Sorry. && goto :END

     ::: Extract drive letter, path, filename and extention of the log file
	::: Note: the new variables will be 'log_drive', 'log_path', 'log_name' and 'log_ext'
	    set inlogfile=%regvalue%
            FOR %%i IN ("%inlogfile%") DO (
            set log_drive=%%~di
            set log_path=%%~pi
            set log_name=%%~ni
            set log_ext=%%~xi
            )

::: Set the variable YYYYMMDD to today's date in YYYYMMDD format
    ::: YYYY = 4-digit year, MM is month (1-12), and DD is day (1-31)
    ::: adapted from http://stackoverflow.com/a/10945887/1810071
        for /f "skip=1" %%x in ('wmic os get localdatetime') do if not defined MyDate set MyDate=%%x
        for /f %%x in ('wmic path win32_localtime get /format:list ^| findstr "="') do set %%x
        set fmonth=00%Month%
        set fday=00%Day%
        set today=%Year%%fmonth:~-2%%fday:~-2%
        set YYYYMMDD=%today%
    
::: Rename the log file
    ::: Note: set the name for the rotated log file to have "_YYYYMMDD.log" at the end of the file name.  Need to use delayed expansion.
     set in_original_log=%log_name%%log_ext%
	set out_rotated_log=%log_name%_%YYYYMMDD%%log_ext%
	set out_rotated_7z=%log_name%_%YYYYMMDD%.7z
 
	   ::: Dive into the log directory
	       PUSHD %log_drive%%log_path%

       ::: Rename the log file
           ::: Note: original author utilizes 'move' command.
	       ::: ::::: Changed 'move' to 'rename' by utilizing 'pushd' but please feel free to use move:
		   ::: ::::: move /Y "%log_drive%%log_path%%in_original_log%" "%log_drive%%log_path%%out_rotated_log%"
           
		   ::: Check if we can find the log file
		       if not exist "%log_drive%%log_path%%in_original_log%" ( echo Sorry, "%in_original_log%" was not found at "%log_drive%%log_path%" && goto :END )
		   
		       :::Check if the log file has been rotated already...
			  if exist "%log_drive%%log_path%%out_rotated_log%" ( echo It looks like the log file has been rotated already - skipping - remove or rename "%out_rotated_log%" manually if you realy want to rotate the DNS log file now. && echo The location of the rotated log file is "%log_drive%%log_path%". && echo. && goto :END )
		   
		   ::: Stop the DNS server service
		       echo The DNS server service will be stopped now - it will be started after log rotation... && echo.
			    NET STOP "DNS Server"
		   
		   ::: Rename the log file (use 'move' or 'rename')
		       rem move /Y "%log_drive%%log_path%%in_original_log%" "%log_drive%%log_path%%out_rotated_log%"
			rename "%log_drive%%log_path%%in_original_log%" "%out_rotated_log%"
			 if exist "%log_drive%%log_path%%out_rotated_log%" ( echo The DNS log file has been rotated: "%log_drive%%log_path%%out_rotated_log%" && echo. ) else ( echo Sorry, the DNS log file has not been rotated... && echo. ) 
			   
		   ::: Start the DNS server service
		       
			   echo The DNS server service is being started now. && echo.
			   NET START "DNS Server"

       ::: Compress the log file
	       if "%compress%" NEQ "yes" goto :7zEnd

		   if not exist "%path7z%\%exec7z%" ( 
		      echo Please note "%exec7z%" was not found in path "%path7z%". Unable to compress the rotated log file.
			  goto :7zEnd
			  )

		   if exist "%path7z%\%exec7z%" (
		      if exist "%log_drive%%log_path%%out_rotated_7z%" ( echo It looks like the log file was rotated already today - skipping compression && goto :END )
		      
			  echo Compressing... && echo. && echo 7-Zip outpunt below this line --- && echo.
			  "%path7z%\%exec7z%" a -sdel -mx9 -y "%log_drive%%log_path%%out_rotated_7z%" "%log_drive%%log_path%%out_rotated_log%"
			  echo. && echo --- 7-Zip output above this line && echo.
			  if exist "%log_drive%%log_path%%out_rotated_7z%" echo The rotated log file "%log_drive%%log_path%%out_rotated_log%" has been archived and replaced by "%log_drive%%log_path%%out_rotated_7z%"
		      )
           :7zEnd

::: Purge log files
    if "%purgelogs%" NEQ "yes" goto :purgeEnd
	echo. && echo Purging old rotated logs... && echo.
	%SystemRoot%\System32\forfiles.exe /P %log_drive%%log_path% /S /M *.%purgeext% /D -%purgelogsdays% /C "%comspec% /C DEL "@file"" >NUL 2>&1
   :purgeEnd


	::: Leave the log directory
	POPD

GOTO :END

:::EOF
  :END
  :EOF
