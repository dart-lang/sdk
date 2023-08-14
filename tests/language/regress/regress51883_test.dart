// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that constant-like records are correctly simplified into a constant
// record by the backends who perform such optimizations.
//
// Regression test for https://github.com/dart-lang/sdk/issues/51883.

void main() {
  final x = ([1, 2], 3);
  (x.$1).add(4);
}
