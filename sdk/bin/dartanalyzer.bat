@echo off
rem Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
rem for details. All rights reserved. Use of this source code is governed by a
rem BSD-style license that can be found in the LICENSE file.

set SCRIPT_DIR=%~dp0
if %SCRIPT_DIR:~-1%==\ set SCRIPT_DIR=%SCRIPT_DIR:~0,-1%

for %%I in ("%SCRIPT_DIR%\..") do set "DART_ANALYZER_HOME=%%~fI"
if %DART_ANALYZER_HOME:~-1%==\ set DART_ANALYZER_HOME=%DART_ANALYZER_HOME:~0,-1%

set FOUND_BATCH=0
set FOUND_SDK=0
for %%a in (%*) do (
  if [%%a] == [--batch] set FOUND_BATCH=1
  if [%%a] == [-b] set FOUND_BATCH=1
  if [%%a] == [--dart-sdk]  set FOUND_SDK=1
)

setlocal EnableDelayedExpansion
set DART_SDK=""
if [%FOUND_SDK%] == [0] (
  if exist "%DART_ANALYZER_HOME%\lib\core\core.dart" (
    set DART_SDK=--dart-sdk "%DART_ANALYZER_HOME%"
  ) else (
    for /f %%i in ('echo %DART_ANALYZER_HOME%') do set DART_SDK_HOME=%%~dpi\dart-sdk
    if exist "!DART_SDK_HOME!" (
      set DART_SDK=--dart-sdk !DART_SDK_HOME!
    ) else (
      for /f %%j in ('call echo !DART_SDK_HOME!') do set DART_SDK_HOME=%%~dpj\dart-sdk
      if exist "!DART_SDK_HOME!" (
        set DART_SDK=--dart-sdk !DART_SDK_HOME!
      ) else (
        echo Couldn't find Dart SDK. Specify with --dart-sdk cmdline argument
      )
    )
  )
)
endlocal & set "DART_SDK=%DART_SDK%" & set "DART_SDK_HOME=%DART_SDK_HOME%"

if exist "%DART_SDK_HOME%\util\dartanalyzer\dartanalyzer.jar" (
  set DART_ANALYZER_LIBS="%DART_SDK_HOME%\util\dartanalyzer"
) else if exist "%DART_ANALYZER_HOME%\util\dartanalyzer\dartanalyzer.jar" (
  set DART_ANALYZER_LIBS="%DART_ANALYZER_HOME%\util\dartanalyzer"
) else (
  echo Configuration problem. Couldn't find dartanalyzer.jar.
  exit /b 1
)

setlocal EnableDelayedExpansion
set EXTRA_JVMARGS=-Xss2M 
if [%FOUND_BATCH%] == [1] (
  set EXTRA_JVMARGS=!EXTRA_JVMARGS! -client
)
endlocal & set "EXTRA_JVMARGS=%EXTRA_JVMARGS%"

java %EXTRA_JVMARGS% %DART_JVMARGS% -ea -jar "%DART_ANALYZER_LIBS%\dartanalyzer.jar" %DART_SDK% %*
