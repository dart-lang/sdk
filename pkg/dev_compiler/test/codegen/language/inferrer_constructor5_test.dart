// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  A() {
    print(field + 42); /// 01: static type warning
  }
}

class B extends A {
  var field;
  B() {
    field = 42;
  }
}

main() {
  Expect.throws(() => new B(), (e) => e is NoSuchMethodError); /// 01: continued
}
