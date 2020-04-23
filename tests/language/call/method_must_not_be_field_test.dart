// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program to test arithmetic operations.

import "package:expect/expect.dart";

class C {
  void Function() call = () {};
}

main() {
  C c = new C();
  dynamic d = c;

  // The presence of a field named `call` does not permit the class `C` to be
  // implicitly called.
  c(); //# 01: compile-time error
  // Nor does it permit an implicit tear-off of `call`.
  void Function() f = c; //# 02: compile-time error
  // Nor does it permit a dynamic invocation of `call`.
  Expect.throws(() => d()); //# 03: ok

  // However, all these things are possible if `call` is mentioned explicitly.
  c.call(); //# 04: ok
  void Function() f = c.call; //# 05: ok
  d.call(); //# 06: ok
  (d.call)(); //# 07: ok
}
