// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@MirrorsUsed(targets: "A")
import 'dart:mirrors';

import 'package:expect/expect.dart';

class A {
  static foo(y, [x]) => y;
  static get bar => 499;
  static operator$foo([optional = 499]) => optional;
  static var x = 42;
  static final y = "toto";
  static const z = true;
}

main() {
  var cm = reflectClass(A);
  var closure = cm.getField(#foo).reflectee;
  Expect.equals("b", closure("b"));

  closure = cm.getField(#operator$foo).reflectee;
  Expect.equals(499, closure());

  Expect.equals(499, cm.getField(#bar).reflectee);
  Expect.equals(42, cm.getField(#x).reflectee);
  Expect.equals("toto", cm.getField(#y).reflectee);  /// 00: ok
  Expect.equals(true, cm.getField(#z).reflectee);    /// 00: ok
}
