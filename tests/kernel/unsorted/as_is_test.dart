// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests of class literals, is, and as expressions.

import 'package:expect/expect.dart';

class C {}

class D extends C {}

test0() => C;
test1() => D;

main() {
  var c = new C();
  var d = new D();
  Expect.isTrue(test0() == C);
  Expect.isTrue(test1() == D);
  Expect.isTrue(c is C);
  Expect.isTrue(c is! D);
  Expect.isTrue(d is C);
  Expect.isTrue(d is D);
  Expect.isTrue(c as C == c);
  Expect.isTrue(d as C == d);
  Expect.isTrue(d as D == d);
}
