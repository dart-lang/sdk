@echo off
REM Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
REM for details. All rights reserved. Use of this source code is governed by a
REM BSD-style license that can be found in the LICENSE file.

REM Script for generating kernel files using Dart 2 pipeline: Fasta with
REM strong mode enabled.

set SCRIPTPATH=%~dp0

REM Does the path have a trailing slash? If so, remove it.
if %SCRIPTPATH:~-1%==\ set SCRIPTPATH=%SCRIPTPATH:~0,-1%

set SDK_DIR=%SCRIPTPATH%/../../../

set DART=%SDK_DIR%/tools/sdks/dart-sdk/bin/dart.exe

"%DART%" %DART_VM_OPTIONS% "%SDK_DIR%/pkg/vm/bin/gen_kernel.dart" %*
