REM Copyright (c) 2013, the Dart project authors. Please see the AUTHORS file
REM for details. All rights reserved. Use of this source code is governed by a
REM BSD-style license that can be found in the LICENSE file.

REM This script will download VAR_DOWNLOAD_URL to VAR_DESTINATION in the current
REM working directory.

CHROMIUM_DIR="%~dp0"
SDK_BIN="%CHROMIUM_DIR%\..\dart-sdk\bin"

DART="%SDK_BIN%\dart.exe"
DOWNLOAD_SCRIPT="%CHROMIUM_DIR%\download_file.dart"

"%DART%" "%DOWNLOAD_SCRIPT%" "VAR_DOWNLOAD_URL" "VAR_DESTINATION"
