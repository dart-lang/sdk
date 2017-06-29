// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Regression test for https://github.com/dart-lang/sdk/issues/29733 in DDC.
foo(a) {
  var a = 123;
  return a;
}

main() {
  Expect.equals(foo(42), 123);
}
