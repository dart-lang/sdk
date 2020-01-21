// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

/// Test that we produce a compile-time error when magic constness would
/// otherwise apply.
// TODO(ahe): Update this test when we implement magic constness correctly.

class Constant {
  const Constant();
}

class NotConstant {}

foo({a: Constant(), b: Constant(), c: []}) {}

test() {
  const NotConstant();
  Constant();
  const x = Constant();
  bool.fromEnvironment("fisk");
  const b = bool.fromEnvironment("fisk");
}

main() {
  // Don't invoke [test] as it throws a compile-time due to `const NotConstant()`.
}
