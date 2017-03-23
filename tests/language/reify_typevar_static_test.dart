// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class C<T> {
  final x;
  C([this.x]);

  static staticFunction(bool b) =>
    b ? T : //                               //# 00: compile-time error
      null;
  factory C.factoryConstructor(bool b) => new C(
    b ? T : //                               //# 01: ok
      null);
  C.redirectingConstructor(bool b) : this(
    b ? T : //                               //# 02: ok
            null);
  C.ordinaryConstructor(bool b)
      : x =
    b ? T : //                               //# 03: ok
            null;
}

main() {
  Expect.equals(null, C.staticFunction(false));
  Expect.equals(null, new C.factoryConstructor(false).x);
  Expect.equals(null, new C.redirectingConstructor(false).x);
  Expect.equals(null, new C.ordinaryConstructor(false).x);
}
