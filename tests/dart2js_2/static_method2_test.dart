// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import "package:expect/expect.dart";

class A {
  static foo(res) {
    return res;
  }
}

main() {
  Expect.equals(42, A.foo(42));
}
