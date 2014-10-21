@echo off
rem Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
rem for details. All rights reserved. Use of this source code is governed by a
rem BSD-style license that can be found in the LICENSE file.
rem 

rem This file is used to execute the analyzer by running the jar file.
rem It is a simple wrapper enabling us to have simpler command lines in
rem the testing infrastructure.

set SCRIPTPATH=%~dp0

rem Does the path have a trailing slash? If so, remove it.
if %SCRIPTPATH:~-1%==\ set SCRIPTPATH=%SCRIPTPATH:~0,-1%

rem DART_CONFIGURATION defaults to ReleaseIA32
if "%DART_CONFIGURATION%"=="" set DART_CONFIGURATION=ReleaseIA32

set arguments=%*

set "SDK_DIR=%SCRIPTPATH%\..\..\build\%DART_CONFIGURATION%\dart-sdk"

set "JAR_DIR=%SCRIPTPATH%\..\..\build\%DART_CONFIGURATION%\dartanalyzer"

set "JAR_FILE=%JAR_DIR%\dartanalyzer.jar"

java -jar "%JAR_FILE%" --dart-sdk "%SDK_DIR%" %arguments%
