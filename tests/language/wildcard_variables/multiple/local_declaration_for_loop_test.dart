// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests for-loop wildcard variable declarations.

// SharedOptions=--enable-experiment=wildcard-variables

void main() async {
  // Multiple for-loop wildcard declarations.
  for (int _ = 0, _ = 2;;) {
    break;
  }

  var list = [];
  for (var _ in list) {}

  var stream = Stream.empty();
  await for (var _ in stream) {}
}
