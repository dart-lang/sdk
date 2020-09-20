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

rem Get absolute full name for SDK_DIR.
for %%i in ("%BIN_DIR%\..\") do set SDK_DIR=%%~fi

rem Remove trailing backslash if there is one
if %SDK_DIR:~-1%==\ set SDK_DIR=%SDK_DIR:~0,-1%

set SDK_ARG=--dart-sdk=%SDK_DIR%

set EXTRA_VM_OPTIONS=

rem We allow extra vm options to be passed in through an environment variable.
if not "_%DART_VM_OPTIONS%_" == "__" (
  set EXTRA_VM_OPTIONS=%EXTRA_VM_OPTIONS% %DART_VM_OPTIONS%
)

rem Get absolute full name for DART_ROOT.
for %%i in ("%SDK_DIR%\..\") do set DART_ROOT=%%~fi

rem Remove trailing backslash if there is one
if %DART_ROOT:~-1%==\ set DART_ROOT=%DART_ROOT:~0,-1%

set DEV_COMPILER=%DART_ROOT%\third_party\pkg\dev_compiler\bin\dartdevc.dart

"%DART%" "--packages=%DART_ROOT%\.packages" %EXTRA_VM_OPTIONS% "DEV_COMPILER%" "%SDK_ARG%" %*

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
                                             ^| %SystemRoot%\System32\find.exe ">     %~n1 [" 2^>nul`) do (
  set current=%%i
)
if not "%current%"=="" call :follow_links "%current%", result
endlocal & set %~2=%result%
goto :eof

:end
