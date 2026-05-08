#!/bin/bash
# Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
set -euo pipefail

# Usage: ./read_comments.sh <change_number>
# Example: ./read_comments.sh 475600

CHANGE=${1:-}
if [ -z "$CHANGE" ]; then
  echo "Usage: $0 <change_number>"
  exit 1
fi

if [[ ! "$CHANGE" =~ ^[0-9]+$ ]]; then
  echo "Error: change_number must be numeric" >&2
  exit 1
fi

command -v curl >/dev/null || { echo "Error: curl is required" >&2; exit 127; }
command -v jq   >/dev/null || { echo "Error: jq is required"   >&2; exit 127; }

GERRIT='https://dart-review.googlesource.com'
URL="$GERRIT/changes/$CHANGE/comments"

# 1. 'curl -fSsL' fetches data, follows redirects, and fails on server errors.
# 2. 'sed 1d' strips Gerrit's XSSI prefix (the magic ')]}' string) to make it valid JSON.
# 3. 'jq' parses the cleaned string, validates it, and pretty-prints it for readability.
curl -fSsL "$URL" | sed '1d' | jq '.'
