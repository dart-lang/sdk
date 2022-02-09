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

rem We allow extra vm options to be passed in through an environment variable.
if not "_%DART_VM_OPTIONS%_" == "__" (
  set VM_OPTIONS=%VM_OPTIONS% %DART_VM_OPTIONS%
)

rem Use the Dart binary in the built SDK so pub can find the version file next
rem to it.
set BUILD_DIR=%SDK_DIR%\..\out\ReleaseX64
set DART=%BUILD_DIR%\dart-sdk\bin\dart

rem Run pub.
set PUB="%SDK_DIR%\..\third_party\pkg\pub\bin\pub.dart"
"%DART%" "--packages=%SDK_DIR%\..\.packages" %VM_OPTIONS% "%PUB%" %*

endlocal

exit /b %errorlevel%

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
