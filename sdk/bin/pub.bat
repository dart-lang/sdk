@echo off
REM Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
REM for details. All rights reserved. Use of this source code is governed by a
REM BSD-style license that can be found in the LICENSE file.

rem Run pub.dart on the Dart VM. This script is only used when running pub from
rem within the Dart source repo. The shipped SDK instead uses "pub_sdk.bat",
rem which is renamed to "pub.bat" when the SDK is built.

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

set VM_OPTIONS=

rem Give the VM extra memory for dart2js.
rem # TODO(rnystrom): Remove when #8355 is fixed.
rem See comments regarding options below in dart2js shell script.
set VM_OPTIONS=%VM_OPTIONS% --old_gen_heap_size=1024

rem Use the Dart binary in the built SDK so pub can find the version file next
rem to it.
set BUILD_DIR=%SDK_DIR%\..\build\ReleaseIA32
set PACKAGES_DIR=%BUILD_DIR%\pub_packages
set DART=%BUILD_DIR%\dart-sdk\bin\dart

rem Run the async/await compiled pub.
set PUB="%SDK_DIR%\lib\_internal\pub_generated\bin\pub.dart"
"%DART%" %VM_OPTIONS% --package-root="%PACKAGES_DIR%" "%PUB%" %*

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
