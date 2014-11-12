@echo off
REM Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
REM for details. All rights reserved. Use of this source code is governed by a
REM BSD-style license that can be found in the LICENSE file.

setlocal
rem Handle the case where dart-sdk/bin has been symlinked to.
set DIR_NAME_WITH_SLASH=%~dp0
set DIR_NAME=%DIR_NAME_WITH_SLASH:~0,-1%%
call :follow_links "%DIR_NAME%", RETURNED_BIN_DIR
rem Get rid of surrounding quotes.
for %%i in ("%RETURNED_BIN_DIR%") do set BIN_DIR=%%~fi

rem Get absolute full name for SDK_DIR.
for %%i in ("%BIN_DIR%\..\") do set SDK_DIR=%%~fi

rem Remove trailing backslash if there is one
IF %SDK_DIR:~-1%==\ set SDK_DIR=%SDK_DIR:~0,-1%

set DOCGEN=%SDK_DIR%\pkg\docgen\bin\docgen.dart
set DART=%BIN_DIR%\dart
set SNAPSHOT=%BIN_DIR%\snapshots\utils_wrapper.dart.snapshot

if not defined DART_CONFIGURATION set DART_CONFIGURATION=ReleaseIA32

set BUILD_DIR=%SDK_DIR%\..\build\%DART_CONFIGURATION%
if exist "%SNAPSHOT%" (
  "%DART%" "%SNAPSHOT%" "docgen" "--sdk=%SDK_DIR%" %*
) else (
  "%BUILD_DIR%\dart-sdk\bin\dart" "--package-root=%BUILD_DIR%\packages" "%DOCGEN%" "--sdk=%SDK_DIR%" %*
)

endlocal

exit /b %errorlevel%

:follow_links
setlocal
for %%i in (%1) do set result=%%~fi
set current=
for /f "tokens=2 delims=[]" %%i in ('dir /a:l ^"%~dp1^" 2^>nul ^
                                     ^| find ">     %~n1 ["') do (
  set current=%%i
)
if not "%current%"=="" call :follow_links "%current%", result
endlocal & set %~2=%result%
goto :eof

:end
