// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test. Failed due to trying to detach an HLocal twice.

// VMOptions=--enable_asserts

#import("compiler_helper.dart");

final String SOURCE = @"""
bool baz(int a, int b) {
  while (a == b || a < b) {
    a = a + b;
  }
  return a == b;
}
""";


main() {
  compile(SOURCE, "baz");
}
