@echo off
REM Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
REM for details. All rights reserved. Use of this source code is governed by a
REM BSD-style license that can be found in the LICENSE file.

REM Run pub.dart on the Dart VM. This script assumes the Dart SDK's directory
REM structure.

set SCRIPTPATH=%~dp0

REM Does the string have a trailing slash? If so, remove it.
if %SCRIPTPATH:~-1%==\ set SCRIPTPATH=%SCRIPTPATH:~0,-1%

REM Set DART_SDK so pub can find SDK packages.
set DART_SDK=%SCRIPTPATH%\..\

"%SCRIPTPATH%\dart" "%SCRIPTPATH%\..\util\pub\pub.dart" %*
