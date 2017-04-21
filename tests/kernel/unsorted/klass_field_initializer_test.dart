// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class A {
  var intField = 1;
  var doubleField = 3.1415;
  var stringField = "hello";
  var o;

  A(this.o);
}

class B extends A {
  var nullField = null;
  var nullField2;

  var n;
  var m;

  B(this.n, o)
      : super(o),
        m = "m";
}

main() {
  var o = new B("n", "o");
  Expect.isTrue(o.intField == 1);
  Expect.isTrue(o.doubleField == 3.1415);
  Expect.isTrue(o.stringField == "hello");
  Expect.isTrue(o.nullField == null);
  Expect.isTrue(o.nullField2 == null);
  Expect.isTrue(o.m == 'm');
  Expect.isTrue(o.n == 'n');
  Expect.isTrue(o.o == 'o');
}
