@echo off
REM Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
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

set DART=%BIN_DIR%\dart

set EXTRA_OPTIONS=
set EXTRA_VM_OPTIONS=

if _%DART2JS_DEVELOPER_MODE%_ == _1_ (
  set EXTRA_VM_OPTIONS=%EXTRA_VM_OPTIONS% --checked
)

rem See comments regarding options below in dart2js shell script.
set EXTRA_VM_OPTIONS=%EXTRA_VM_OPTIONS% --heap_growth_rate=512

rem We allow extra vm options to be passed in through an environment variable.
if not "_%DART_VM_OPTIONS%_" == "__" (
  set EXTRA_VM_OPTIONS=%EXTRA_VM_OPTIONS% %DART_VM_OPTIONS%
)

rem Get absolute full name for DART_ROOT.
for %%i in ("%SDK_DIR%\..\") do set DART_ROOT=%%~fi

rem Remove trailing backslash if there is one
if %DART_ROOT:~-1%==\ set DART_ROOT=%DART_ROOT:~0,-1%

set DART2JS=%DART_ROOT%\pkg\compiler\lib\src\dart2js.dart

rem DART_CONFIGURATION defaults to ReleaseIA32
if "%DART_CONFIGURATION%"=="" set DART_CONFIGURATION=ReleaseIA32

set BUILD_DIR=%DART_ROOT%\build\%DART_CONFIGURATION%

set PACKAGE_ROOT=%BUILD_DIR%\packages

"%DART%" %EXTRA_VM_OPTIONS% "--package-root=%PACKAGE_ROOT%" "%DART2JS%" %EXTRA_OPTIONS% %*

endlocal

exit /b %errorlevel%

:follow_links
setlocal
for %%i in (%1) do set result=%%~fi
set current=
for /f "usebackq tokens=2 delims=[]" %%i in (`dir /a:l "%~dp1" 2^>nul ^
                                             ^| find ">     %~n1 ["`) do (
  set current=%%i
)
if not "%current%"=="" call :follow_links "%current%", result
endlocal & set %~2=%result%
goto :eof

:end
