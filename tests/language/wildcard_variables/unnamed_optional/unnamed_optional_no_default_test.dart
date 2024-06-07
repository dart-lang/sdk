// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Unnamed optional parameters, which are not initializing or super parameters,
// that have no default values, have no errors.

// SharedOptions=--enable-experiment=wildcard-variables

import 'package:expect/expect.dart';

class C {
  C([int _]) {}
  C.otherParams([int _, bool x = false, bool _ = true]) {}
  C.otherParams2([int _ = 1, bool x = false, bool _]) {}

  int foo([int _]) => 1;
  int foo2([bool x = false, bool _, int _]) => 1;
  int foo3([bool? x, bool _ = false, int _]) => 1;
  int foo4([int _, bool? x, bool _ = false]) => 1;

  static int fn([int _]) => 1;
  static int fn2([bool x = false, bool _, int _]) => 1;
  static int fn3([bool? x, bool _ = false, int _]) => 1;
  static int fn4([int _, bool? x, bool _ = false]) => 1;
}

int _([bool _]) => 1;
int topFoo2([bool x = false, bool _, int _]) => 1;
int topFoo3([bool? x, bool _ = false, int _]) => 1;
int topFoo4([int _, bool? x, bool _ = false]) => 1;

void main() {
  Expect.equals(1, _());
  Expect.equals(1, topFoo2());
  Expect.equals(1, topFoo3());
  Expect.equals(1, topFoo4());

  int foo([int _]) => 1;
  int foo2([bool x = false, bool _, int _]) => 1;
  int foo3([bool? x, bool _ = false, int _]) => 1;
  int foo4([int _, bool? x, bool _ = false]) => 1;
  Expect.equals(1, foo());
  Expect.equals(1, foo2());
  Expect.equals(1, foo3());
  Expect.equals(1, foo4());

  var c = C();
  Expect.equals(1, c.foo());
  Expect.equals(1, c.foo2());
  Expect.equals(1, c.foo3());
  Expect.equals(1, c.foo4());

  Expect.equals(1, C.otherParams().foo());
  Expect.equals(1, C.otherParams2().foo());

  Expect.equals(1, C.fn());
  Expect.equals(1, C.fn2());
  Expect.equals(1, C.fn3());
  Expect.equals(1, C.fn4());
}
