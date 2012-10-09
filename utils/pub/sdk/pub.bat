@echo off
:: Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
:: for details. All rights reserved. Use of this source code is governed by a
:: BSD-style license that can be found in the LICENSE file.

:: Run pub.dart on the Dart VM. This script assumes the Dart SDK's directory
:: structure.

set SCRIPTPATH=%~dp0

:: Does the string have a trailing slash? If so, remove it.
if %SCRIPTPATH:~-1%==\ set SCRIPTPATH=%SCRIPTPATH:~0,-1%

:: Set DART_SDK so pub can find SDK packages.
set DART_SDK=%SCRIPTPATH%\..\

"%SCRIPTPATH%\dart.exe" "%SCRIPTPATH%\..\util\pub\pub.dart" %*
