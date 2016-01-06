#!/usr/bin/env bash
# Copyright (c) 2013, the Dart project authors. Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# This script will download VAR_DOWNLOAD_URL to VAR_DESTINATION in the current
# working directory.

CHROMIUM_DIR="$(dirname $BASH_SOURCE)"
SDK_BIN="$CHROMIUM_DIR/../dart-sdk/bin"

DART="$SDK_BIN/dart"
DOWNLOAD_SCRIPT="$CHROMIUM_DIR/download_file.dart"

"$DART" "$DOWNLOAD_SCRIPT" "VAR_DOWNLOAD_URL" "VAR_DESTINATION"
