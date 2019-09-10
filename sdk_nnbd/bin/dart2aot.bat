@echo off
REM Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
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

rem Get absolute full name for DART_ROOT.
for %%i in ("%SDK_DIR%\..\") do set DART_ROOT=%%~fi

rem Remove trailing backslash if there is one
if %DART_ROOT:~-1%==\ set DART_ROOT=%DART_ROOT:~0,-1%

set DART=%BIN_DIR%\dart.exe
set GEN_KERNEL=%BIN_DIR%\snapshots\gen_kernel.dart.snapshot
set VM_PLATFORM_STRONG=%SDK_DIR%\lib\_internal\vm_platform_strong.dill
set GEN_SNAPSHOT=%BIN_DIR%\utils\gen_snapshot.exe

set SOURCE_FILE=%1
set SNAPSHOT_FILE=%2
set GEN_SNAPSHOT_OPTION=--snapshot-kind=app-aot-blobs
set GEN_SNAPSHOT_FILENAME=--blobs_container_filename=%SNAPSHOT_FILE%

REM Step 1: Generate Kernel binary from the input Dart source.
%DART% %GEN_KERNEL% --platform %VM_PLATFORM_STRONG% --aot -Ddart.vm.product=true -o %SNAPSHOT_FILE%.dill %SOURCE_FILE%

REM Step 2: Generate snapshot from the Kernel binary.
%GEN_SNAPSHOT% %GEN_SNAPSHOT_OPTION% %GEN_SNAPSHOT_FILENAME% %SNAPSHOT_FILE%.dill

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
