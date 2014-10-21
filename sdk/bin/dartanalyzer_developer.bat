@echo off
REM Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
REM for details. All rights reserved. Use of this source code is governed by a
REM BSD-style license that can be found in the LICENSE file.

setlocal
set DARTANALYZER_DEVELOPER_MODE=1
call "%~dp0dartanalyzer.bat" %*
endlocal
exit /b %errorlevel%
