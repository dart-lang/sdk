// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that the body of an if element with unevaluated condition can
// contain a spread.
// Regression test for https://github.com/dart-lang/sdk/issues/36812

const b = bool.fromEnvironment("foo");

main() {
  const l1 = [1, 2, 3];
  const l2 = [if (b) ...l1];
  print(l2);
}
