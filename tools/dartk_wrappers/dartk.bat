@echo off
REM Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
REM for details. All rights reserved. Use of this source code is governed by a
REM BSD-style license that can be found in the LICENSE file. 

set SCRIPTPATH=%~dp0

REM Does the path have a trailing slash? If so, remove it.
if %SCRIPTPATH:~-1%== set SCRIPTPATH=%SCRIPTPATH:~0,-1%

set DART_ROOT=%SCRIPTPATH%..\..\

rem Remove trailing backslash if there is one
if %DART_ROOT:~-1%==\ set DART_ROOT=%DART_ROOT:~0,-1%

set DARTK=%DART_ROOT%\pkg\kernel\tool\dartk.dart

set DART=%DART_ROOT%\tools\sdks\win\dart-sdk\bin\dart

"%DART%" --packages=.packages "%DARTK%" %*
