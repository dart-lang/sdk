#!/usr/bin/env bash

# Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

set -e

# Navigate to Dart SDK root directory
cd "$(dirname "$0")/../../.."

# Build DartPad worker and Dart SDK assets
./tools/build.py -m release -a x64 dartpad

# Build Flutter SDK assets (fails if Flutter is not available)
echo "Building Flutter assets..."
dart pkg/dartpad_worker/tool/setup_local_flutter.dart

# Run integration tests before copying files to web/
echo "Running integration tests..."
(cd pkg/dartpad_worker && dart test)

# Clean and recreate pkg/dartpad/web/
rm -rf pkg/dartpad/web
mkdir -p pkg/dartpad/web

# Copy compiled Dart SDK assets
cp -R out/ReleaseX64/dartpad/* pkg/dartpad/web/

# Copy Flutter assets if available (from .dart_tool/dartpad_worker/asset/)
ASSET_DIR="pkg/dartpad_worker/.dart_tool/dartpad_worker/asset"
if [ -d "$ASSET_DIR" ]; then
  echo "Copying extra assets to web/..."
  cp -R "$ASSET_DIR"/* pkg/dartpad/web/
fi

# Publish package:dartpad
cd pkg/dartpad
dart pub publish "$@"
