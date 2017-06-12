// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library mirror_test;

@MirrorsUsed(targets: "mirror_test")
import 'dart:mirrors';

import 'package:expect/expect.dart';

class A {
  var req1, opt1, opt2;
  A.a0([opt1]) : this.opt1 = opt1;
  A.b0([opt1, opt2])
      : this.opt1 = opt1,
        this.opt2 = opt2;
  A.c0([opt1 = 499]) : this.opt1 = opt1;
  A.d0([opt1 = 499, opt2 = 42])
      : this.opt1 = opt1,
        this.opt2 = opt2;
  A.a1(req1, [opt1])
      : this.req1 = req1,
        this.opt1 = opt1;
  A.b1(req1, [opt1, opt2])
      : this.req1 = req1,
        this.opt1 = opt1,
        this.opt2 = opt2;
  A.c1(req1, [opt1 = 499])
      : this.req1 = req1,
        this.opt1 = opt1;
  A.d1(req1, [opt1 = 499, opt2 = 42])
      : this.req1 = req1,
        this.opt1 = opt1,
        this.opt2 = opt2;
}

main() {
  ClassMirror cm = reflectClass(A);

  var o;
  o = cm.newInstance(#a0, []).reflectee;
  Expect.equals(null, o.req1);
  Expect.equals(null, o.opt1);
  Expect.equals(null, o.opt2);
  o = cm.newInstance(#b0, []).reflectee;
  Expect.equals(null, o.req1);
  Expect.equals(null, o.opt1);
  Expect.equals(null, o.opt2);
  o = cm.newInstance(#c0, []).reflectee;
  Expect.equals(null, o.req1);
  Expect.equals(499, o.opt1);
  Expect.equals(null, o.opt2);
  o = cm.newInstance(#d0, []).reflectee;
  Expect.equals(null, o.req1);
  Expect.equals(499, o.opt1);
  Expect.equals(42, o.opt2);

  o = cm.newInstance(#a0, [77]).reflectee;
  Expect.equals(null, o.req1);
  Expect.equals(77, o.opt1);
  Expect.equals(null, o.opt2);
  o = cm.newInstance(#b0, [77]).reflectee;
  Expect.equals(null, o.req1);
  Expect.equals(77, o.opt1);
  Expect.equals(null, o.opt2);
  o = cm.newInstance(#c0, [77]).reflectee;
  Expect.equals(null, o.req1);
  Expect.equals(77, o.opt1);
  Expect.equals(null, o.opt2);
  o = cm.newInstance(#d0, [77]).reflectee;
  Expect.equals(null, o.req1);
  Expect.equals(77, o.opt1);
  Expect.equals(42, o.opt2);

  o = cm.newInstance(#b0, [77, 11]).reflectee;
  Expect.equals(null, o.req1);
  Expect.equals(77, o.opt1);
  Expect.equals(11, o.opt2);
  o = cm.newInstance(#d0, [77, 11]).reflectee;
  Expect.equals(null, o.req1);
  Expect.equals(77, o.opt1);
  Expect.equals(11, o.opt2);

  o = cm.newInstance(#a1, [123]).reflectee;
  Expect.equals(123, o.req1);
  Expect.equals(null, o.opt1);
  Expect.equals(null, o.opt2);
  o = cm.newInstance(#b1, [123]).reflectee;
  Expect.equals(123, o.req1);
  Expect.equals(null, o.opt1);
  Expect.equals(null, o.opt2);
  o = cm.newInstance(#c1, [123]).reflectee;
  Expect.equals(123, o.req1);
  Expect.equals(499, o.opt1);
  Expect.equals(null, o.opt2);
  o = cm.newInstance(#d1, [123]).reflectee;
  Expect.equals(123, o.req1);
  Expect.equals(499, o.opt1);
  Expect.equals(42, o.opt2);

  o = cm.newInstance(#a1, [123, 77]).reflectee;
  Expect.equals(123, o.req1);
  Expect.equals(77, o.opt1);
  Expect.equals(null, o.opt2);
  o = cm.newInstance(#b1, [123, 77]).reflectee;
  Expect.equals(123, o.req1);
  Expect.equals(77, o.opt1);
  Expect.equals(null, o.opt2);
  o = cm.newInstance(#c1, [123, 77]).reflectee;
  Expect.equals(123, o.req1);
  Expect.equals(77, o.opt1);
  Expect.equals(null, o.opt2);
  o = cm.newInstance(#d1, [123, 77]).reflectee;
  Expect.equals(123, o.req1);
  Expect.equals(77, o.opt1);
  Expect.equals(42, o.opt2);

  o = cm.newInstance(#b1, [123, 77, 11]).reflectee;
  Expect.equals(123, o.req1);
  Expect.equals(77, o.opt1);
  Expect.equals(11, o.opt2);
  o = cm.newInstance(#d1, [123, 77, 11]).reflectee;
  Expect.equals(123, o.req1);
  Expect.equals(77, o.opt1);
  Expect.equals(11, o.opt2);
}
