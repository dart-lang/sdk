// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.hot_get_field;

import 'dart:mirrors';
import 'package:expect/expect.dart';

class C {
  var field;
  var _field;
  operator +(other) => field + other;
}

const int optimizationThreshold = 20;

testPublic() {
  var c = new C();
  var im = reflect(c);

  for (int i = 0; i < (2 * optimizationThreshold); i++) {
    c.field = i;
    Expect.equals(i, im.getField(#field).reflectee);
  }
}

testPrivate() {
  var c = new C();
  var im = reflect(c);

  for (int i = 0; i < (2 * optimizationThreshold); i++) {
    c._field = i;
    Expect.equals(i, im.getField(#_field).reflectee);
  }
}

testPrivateWrongLibrary() {
  var c = new C();
  var im = reflect(c);
  var selector = MirrorSystem.getSymbol('_field', reflectClass(Mirror).owner);

  for (int i = 0; i < (2 * optimizationThreshold); i++) {
    Expect.throws(() => im.getField(selector), (e) => e is NoSuchMethodError);
  }
}

testOperator() {
  var plus = const Symbol("+");
  var c = new C();
  var im = reflect(c);

  for (int i = 0; i < (2 * optimizationThreshold); i++) {
    c.field = i;
    var closurizedPlus = im.getField(plus).reflectee;
    Expect.isTrue(closurizedPlus is Function);
    Expect.equals(2 * i, closurizedPlus(i));
  }
}

main() {
  testPublic();
  testPrivate();
  testPrivateWrongLibrary();
  testOperator();
}
