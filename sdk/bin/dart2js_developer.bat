@echo off
REM Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
REM for details. All rights reserved. Use of this source code is governed by a
REM BSD-style license that can be found in the LICENSE file.

setlocal
set DART2JS_DEVELOPER_MODE=1
call "%~dp0dart2js.bat" %*
endlocal
exit /b %errorlevel%
