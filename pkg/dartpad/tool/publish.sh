#!/usr/bin/env bash

# Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

set -e

# Navigate to Dart SDK root directory
cd "$(dirname "$0")/../../.."

# Build DartPad worker and Dart SDK assets
./tools/build.py -m release -a x64 dartpad

# Use Dart we just built!
DART="$PWD/out/ReleaseX64/dart-sdk/bin/dart"

# Build Flutter SDK assets for integration tests (fails if Flutter is not available)
echo "Building Flutter assets..."
"$DART" pkg/dartpad_worker/tool/setup_local_flutter.dart --web-sdk=build --use-cdn

# Run integration tests before publishing
echo "Running integration tests..."
(cd pkg/dartpad_worker && "$DART" test)
(cd pkg/dartpad && "$DART" test)

# Publish package:dartpad
cd pkg/dartpad
"$DART" pub publish "$@"
