#!/bin/bash
# Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
set -euo pipefail

# Usage: ./read_patch.sh <change_number> [patchset]
# Example: ./read_patch.sh 459740
# Example: ./read_patch.sh 459740 2

CHANGE=${1:-}
if [ -z "$CHANGE" ]; then
  echo "Usage: $0 <change_number> [patchset]"
  exit 1
fi

if [[ ! "$CHANGE" =~ ^[0-9]+$ ]]; then
  echo "Error: change_number must be numeric" >&2
  exit 1
fi

PATCHSET=${2:-current}

if [[ "$PATCHSET" != "current" && ! "$PATCHSET" =~ ^[0-9]+$ ]]; then
  echo "Error: patchset must be 'current' or numeric" >&2
  exit 1
fi

command -v curl >/dev/null || { echo "Error: curl is required" >&2; exit 127; }
command -v base64 >/dev/null || { echo "Error: base64 is required" >&2; exit 127; }

GERRIT='https://dart-review.googlesource.com'
URL="$GERRIT/changes/$CHANGE/revisions/$PATCHSET/patch"

# 1. 'curl -fSsL' fetches data, follows redirects, and fails on server errors.
# 2. Gerrit API /patch endpoint returns base64 encoded content.
# 3. 'base64 --decode' decodes it back to the original unified diff text.
curl -fSsL "$URL" | base64 --decode
