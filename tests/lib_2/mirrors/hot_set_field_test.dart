// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.hot_set_field;

import 'dart:mirrors';
import 'package:expect/expect.dart';

class C {
  var field;
  var _field;
}

const int optimizationThreshold = 20;

testPublic() {
  var c = new C();
  var im = reflect(c);

  for (int i = 0; i < (2 * optimizationThreshold); i++) {
    im.setField(#field, i);
    Expect.equals(i, c.field);
  }
}

testPrivate() {
  var c = new C();
  var im = reflect(c);

  for (int i = 0; i < (2 * optimizationThreshold); i++) {
    im.setField(#_field, i);
    Expect.equals(i, c._field);
  }
}

testPrivateWrongLibrary() {
  var c = new C();
  var im = reflect(c);
  var selector = MirrorSystem.getSymbol('_field', reflectClass(Mirror).owner);

  for (int i = 0; i < (2 * optimizationThreshold); i++) {
    Expect.throwsNoSuchMethodError(() => im.setField(selector, i));
  }
}

main() {
  testPublic();
  testPrivate();
  testPrivateWrongLibrary();
}
