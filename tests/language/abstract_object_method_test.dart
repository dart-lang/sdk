// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  noSuchMethod(_) {
    Expect.fail('Should not reach here');
  }
}

class B extends A {
  operator ==(other);
}

class C extends B {}

var a = [new C()];

main() {
  C c = a[0];
  a.add(c);
  Expect.isTrue(c == a[1]);
}
