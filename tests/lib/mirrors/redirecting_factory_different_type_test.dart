// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library mirror_test;

@MirrorsUsed(targets: "mirror_test")
import 'dart:mirrors';

import 'package:expect/expect.dart';

class A {
  factory A(
    String   /// 01: static type warning
    x) = B;
  A._();
}

class B extends A {
  var x;
  B(int x) : super._(), this.x = x;
}

main() {
  var cm = reflectClass(A);
  // The type-annotation in A's constructor must be ignored.
  var b = cm.newInstance(const Symbol(''), [499]).reflectee;
  Expect.equals(499, b.x);
  Expect.throws(() => cm.newInstance(const Symbol(''), ["str"]),
                (e) => e is TypeError);
}
