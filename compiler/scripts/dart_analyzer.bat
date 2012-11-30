@echo off
rem #!/bin/bash --posix
rem Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
rem for details. All rights reserved. Use of this source code is governed by a
rem BSD-style license that can be found in the LICENSE file.
rem 
rem stop if any of the steps fails
rem set -e
rem 

rem SCRIPT_DIR=$(dirname $0)
set SCRIPT_DIR=%~dp0
if %SCRIPT_DIR:~-1%==\ set SCRIPT_DIR=%SCRIPT_DIR:~0,-1%

rem DART_ANALYZER_HOME=$(dirname $SCRIPT_DIR)
for /f %%i in ('echo %SCRIPT_DIR%') do set DART_ANALYZER_HOME=%%~dpi
if %DART_ANALYZER_HOME:~-1%==\ set DART_ANALYZER_HOME=%DART_ANALYZER_HOME:~0,-1%

set FOUND_BATCH=0
set FOUND_SDK=0
for %%a in (%*) do (
  if [%%a] == [--batch] set FOUND_BATCH=1
  if [%%a] == [-b] set FOUND_BATCH=1
  if [%%a] == [--dart-sdk]  set FOUND_SDK=1
)

rem FOUND_BATCH=0
rem FOUND_SDK=0
rem for ARG in "$@"
rem do
rem   case $ARG in
rem     -batch|--batch)
rem       FOUND_BATCH=1
rem       ;;
rem     --dart-sdk)
rem       FOUND_SDK=1
rem       ;;
rem     *)
rem       ;;
rem   esac
rem done
rem 

setlocal EnableDelayedExpansion
set DART_SDK=""
if [%FOUND_SDK%] == [0] (
  if exist "%DART_ANALYZER_HOME%\lib\core\core.dart" (
    set DART_SDK=--dart-sdk %DART_ANALYZER_HOME%
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

rem DART_SDK=""
rem if [ $FOUND_SDK = 0 ] ; then
rem   if [ -f $DART_ANALYZER_HOME/lib/core/core.dart ] ; then
rem     DART_SDK="--dart-sdk $DART_ANALYZER_HOME"
rem   else
rem     DART_SDK_HOME=$(dirname $DART_ANALYZER_HOME)/dart-sdk
rem     if [ -d $DART_SDK_HOME ] ; then
rem       DART_SDK="--dart-sdk $DART_SDK_HOME"
rem     else
rem       DART_SDK_HOME=$(dirname $DART_SDK_HOME)/dart-sdk
rem       if [ -d $DART_SDK_HOME ] ; then
rem         DART_SDK="--dart-sdk $DART_SDK_HOME"
rem       else
rem         echo "Couldn't find Dart SDK. Specify with --dart-sdk cmdline argument"
rem       fi
rem     fi
rem   fi
rem fi
rem 

if exist "%DART_SDK_HOME%\util\analyzer\dart_analyzer.jar" (
  set DART_ANALYZER_LIBS=%DART_SDK_HOME%\util\analyzer
) else if exist "%DART_ANALYZER_HOME%\util\analyzer\dart_analyzer.jar" (
  set DART_ANALYZER_LIBS=%DART_ANALYZER_HOME%\util\analyzer
) else (
  echo Configuration problem. Couldn't find dart_analyzer.jar.
  exit /b 1
)

rem if [ -f $DART_SDK_HOME/util/analyzer/dart_analyzer.jar ] ; then
rem   DART_ANALYZER_LIBS=$DART_SDK_HOME/util/analyzer
rem elif [ -f $DART_ANALYZER_HOME/util/analyzer/dart_analyzer.jar ] ; then
rem   DART_ANALYZER_LIBS=$DART_ANALYZER_HOME/util/analyzer
rem else
rem   echo "Configuration problem. Couldn't find dart_analyzer.jar."
rem   exit 1
rem fi

rem 
rem if [ -x /usr/libexec/java_home ]; then
rem   export JAVA_HOME=$(/usr/libexec/java_home -v '1.6+')
rem fi
rem 

setlocal EnableDelayedExpansion
set EXTRA_JVMARGS=-Xss2M 
if [%FOUND_BATCH%] == [1] (
  set EXTRA_JVMARGS=!EXTRA_JVMARGS! -client
)
endlocal & set "EXTRA_JVMARGS=%EXTRA_JVMARGS%"

rem EXTRA_JVMARGS="-Xss2M "
rem OS=`uname | tr [A-Z] [a-z]`
rem if [ "$OS" == "darwin" ] ; then
rem   # Bump up the heap on Mac VMs, some of which default to 128M or less.
rem   # Users can specify DART_JVMARGS in the environment to override
rem   # this setting. Force to 32 bit client vm. 64 bit and server VM make for 
rem   # poor performance.
rem   EXTRA_JVMARGS+=" -Xmx256M -client -d32 "
rem else
rem   # On other architectures
rem   # -batch invocations will do better with a server vm
rem   # invocations for analyzing a single file do better with a client vm
rem   if [ $FOUND_BATCH = 0 ] ; then
rem     EXTRA_JVMARGS+=" -client "
rem   fi
rem fi
rem 

java %EXTRA_JVMARGS% %DART_JVMARGS% -ea -classpath "@CLASSPATH@" ^
  com.google.dart.compiler.DartCompiler %DART_SDK% %*

rem exec java $EXTRA_JVMARGS $DART_JVMARGS -ea -classpath "@CLASSPATH@" \
rem   com.google.dart.compiler.DartCompiler ${DART_SDK} $@
rem 
