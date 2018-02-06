@echo off
REM Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
REM for details. All rights reserved. Use of this source code is governed by a
REM BSD-style license that can be found in the LICENSE file.

REM Script for running JIT mode VM with Dart 2 pipeline: using Fasta in DFE
REM isolate and strong mode semantics.

set SCRIPTPATH=%~dp0

REM Does the path have a trailing slash? If so, remove it.
if %SCRIPTPATH:~-1%==\ set SCRIPTPATH=%SCRIPTPATH:~0,-1%

set OUT_DIR=%SCRIPTPATH%/../../../out/

REM Remove trailing spaces if line is not empty
if not "%DART_CONFIGURATION%" == "" (
  set DART_CONFIGURATION=%DART_CONFIGURATION: =%
)
if "%DART_CONFIGURATION%"=="" set DART_CONFIGURATION=ReleaseX64

if "%DART_USE_SDK%"=="" set DART_USE_SDK=0
set BUILD_DIR=%OUT_DIR%%DART_CONFIGURATION%

if not "_%DART_VM_OPTIONS%_" == "__" (
  set EXTRA_VM_OPTIONS=%EXTRA_VM_OPTIONS% %DART_VM_OPTIONS%
)

if "%DART_USE_SDK%"=="1" (
  set DART_BINARY=%BUILD_DIR%/dart-sdk/bin/dart
  set KERNEL_BINARIES_DIR=%BUILD_DIR%/dart-sdk/lib/_internal
) else (
  set DART_BINARY=%BUILD_DIR%/dart
  set KERNEL_BINARIES_DIR=%BUILD_DIR%
)
set KERNEL_SERVICE_SNAPSHOT=%BUILD_DIR%/gen/kernel-service.dart.snapshot

"%DART_BINARY%" --strong --reify-generic-functions --limit-ints-to-64-bits --dfe="%KERNEL_SERVICE_SNAPSHOT%" --kernel-binaries="%KERNEL_BINARIES_DIR%" %*
