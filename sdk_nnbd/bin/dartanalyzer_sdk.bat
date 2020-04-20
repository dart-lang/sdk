@echo off
REM Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
REM for details. All rights reserved. Use of this source code is governed by a
REM BSD-style license that can be found in the LICENSE file.

setlocal
rem Handle the case where dart-sdk/bin has been symlinked to.
set DIR_NAME_WITH_SLASH=%~dp0
set DIR_NAME=%DIR_NAME_WITH_SLASH:~0,-1%%
call :follow_links "%DIR_NAME%", RETURNED_BIN_DIR
rem Get rid of surrounding quotes.
for %%i in ("%RETURNED_BIN_DIR%") do set BIN_DIR=%%~fi

set DART=%BIN_DIR%\dart
set SNAPSHOT=%BIN_DIR%\snapshots\dartanalyzer.dart.snapshot

rem Get absolute full name for SDK_DIR.
for %%i in ("%BIN_DIR%\..\") do set SDK_DIR=%%~fi

rem Remove trailing backslash if there is one
if %SDK_DIR:~-1%==\ set SDK_DIR=%SDK_DIR:~0,-1%

set SDK_ARG=--dart-sdk=%SDK_DIR%

"%DART%" "%SNAPSHOT%" "%SDK_ARG%" %*

endlocal

exit /b %errorlevel%

rem Follow the symbolic links (junctions points) using `dir to determine the
rem canonical path. Output with a link looks something like this
rem
rem 01/03/2013  10:11 PM    <JUNCTION>     abc def
rem [c:\dart_bleeding\dart-repo.9\dart\out\ReleaseIA32\dart-sdk]
rem
rem So in the output of 'dir /a:l "targetdir"' we are looking for a filename
rem surrounded by right angle bracket and left square bracket. Once we get
rem the filename, which is name of the link, we recursively follow that.
:follow_links
setlocal
for %%i in (%1) do set result=%%~fi
set current=
for /f "usebackq tokens=2 delims=[]" %%i in (`dir /a:l "%~dp1" 2^>nul ^
                                             ^| find ">     %~n1 [" 2^>nul`) do (
  set current=%%i
)
if not "%current%"=="" call :follow_links "%current%", result
endlocal & set %~2=%result%
goto :eof

:end
