// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// For Dart VM: tests that a "const factory" with body produces an error.
// For DartC: tests that a "const factory" is illegal.

class ConstFactoryNegativeTest {
  const factory ConstFactoryNegativeTest.one() {
  }
}

main() {
  const ConstFactoryNegativeTest.one();
}
