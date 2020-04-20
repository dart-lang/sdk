// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

int counter = 0;

class Bar {
  Bar() {
    counter++;
  }
}

class A {
  var _bar = new Bar();
  A() : this._();
  A._() {
    () => 42;
  }
}

main() {
  new A();
  Expect.equals(1, counter);
}
