@echo off
REM Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
REM for details. All rights reserved. Use of this source code is governed by a
REM BSD-style license that can be found in the LICENSE file.

set SCRIPTPATH=%~dp0

REM Does the path have a trailing slash? If so, remove it.
if %SCRIPTPATH:~-1%== set SCRIPTPATH=%SCRIPTPATH:~0,-1%

REM DART_CONFIGURATION defaults to ReleaseX64
if "%DART_CONFIGURATION%"=="" set DART_CONFIGURATION=ReleaseX64

set arguments=%*

"%SCRIPTPATH%\..\..\out\%DART_CONFIGURATION%\dart.exe" %arguments%
