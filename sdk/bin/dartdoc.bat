@echo off
REM Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
REM for details. All rights reserved. Use of this source code is governed by a
REM BSD-style license that can be found in the LICENSE file.

set SCRIPTPATH=%~dp0

REM Does the path have a trailing slash? If so, remove it.
if %SCRIPTPATH:~-1%== set SCRIPTPATH=%SCRIPTPATH:~0,-1%

set arguments=%*
rem set SNAPSHOTNAME="%SCRIPTPATH%dartdoc.snapshot"
rem if exist %SNAPSHOTNAME% set SNAPSHOT=--use-script-snapshot=%SNAPSHOTNAME%

:: The trailing forward slash in --package-root is required because of issue
:: 9499.
"%SCRIPTPATH%dart" --heap_growth_rate=32 "--package-root=%SCRIPTPATH%..\packages/" %SNAPSHOT% "%SCRIPTPATH%..\lib\_internal\dartdoc\bin\dartdoc.dart" %arguments%
