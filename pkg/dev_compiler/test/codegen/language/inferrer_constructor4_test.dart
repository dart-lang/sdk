// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

escape(object) {
  print(object.field + 42);
}

class A {
  A() {
    escape(this);
  }
}

class B extends A {
  var field;
  B() {
    field = 42;
  }
}

main() {
  Expect.throws(() => new B(), (e) => e is NoSuchMethodError);
}
