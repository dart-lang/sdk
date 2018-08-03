// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check mixin of black-listed types.

import 'package:expect/expect.dart';

class C {}

class D {}

class C1 extends Object
with String //# 01: compile-time error
{}

class D1 extends Object with C
, Null //# 02: compile-time error
{}

class E1 extends Object
    with
int, //# 03: compile-time error
        C {}

class F1 extends Object
    with
        C
, double //# 04: compile-time error
        ,
        D {}

class C2 = Object with num; //# 05: compile-time error

class D2 = Object with C
, bool //# 06: compile-time error
    ;

class E2 = Object
    with
String, //# 07: compile-time error
        C;

class F2 = Object
    with
        C,
dynamic, //# 08: compile-time error
        D;

main() {
  Expect.isNotNull(new C1());
  Expect.isNotNull(new D1());
  Expect.isNotNull(new E1());
  Expect.isNotNull(new F1());
  Expect.isNotNull(new C2()); //# 05: continued
  Expect.isNotNull(new D2());
  Expect.isNotNull(new E2());
  Expect.isNotNull(new F2());
}
