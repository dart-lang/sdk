// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.set_field_with_final_inheritance;

import 'dart:mirrors';
import 'package:expect/expect.dart';

class S {
  var sideEffect = 0;

  var mutableWithInheritedMutable = 1;
  final mutableWithInheritedFinal = 2;
  set mutableWithInheritedSetter(x) => sideEffect = 3;

  var finalWithInheritedMutable = 4;
  final finalWithInheritedFinal = 5;
  set finalWithInheritedSetter(x) => sideEffect = 6;

  var setterWithInheritedMutable = 7;
  final setterWithInheritedFinal = 8;
  set setterWithInheritedSetter(x) => sideEffect = 9;
}

class C extends S {
  var mutableWithInheritedMutable = 10;
  var mutableWithInheritedFinal = 11;
  var mutableWithInheritedSetter = 12;

  final finalWithInheritedMutable = 13;
  final finalWithInheritedFinal = 14;
  final finalWithInheritedSetter = 15;

  set setterWithInheritedMutable(x) => sideEffect = 16;
  set setterWithInheritedFinal(x) => sideEffect = 17;
  set setterWithInheritedSetter(x) => sideEffect = 18;

  get superMutableWithInheritedMutable => super.mutableWithInheritedMutable;
  get superMutableWithInheritedFinal => super.mutableWithInheritedFinal;

  get superFinalWithInheritedMutable => super.finalWithInheritedMutable;
  get superFinalWithInheritedFinal => super.finalWithInheritedFinal;

  get superSetterWithInheritedMutable => super.setterWithInheritedMutable;
  get superSetterWithInheritedFinal => super.setterWithInheritedFinal;
}

main() {
  C c;
  InstanceMirror im;

  c = new C();
  im = reflect(c);
  Expect.equals(19, im.setField(#mutableWithInheritedMutable, 19).reflectee);
  Expect.equals(19, c.mutableWithInheritedMutable);
  Expect.equals(1, c.superMutableWithInheritedMutable);
  Expect.equals(0, c.sideEffect);

  c = new C();
  im = reflect(c);
  Expect.equals(20, im.setField(#mutableWithInheritedFinal, 20).reflectee);
  Expect.equals(20, c.mutableWithInheritedFinal);
  Expect.equals(2, c.superMutableWithInheritedFinal);
  Expect.equals(0, c.sideEffect);

  c = new C();
  im = reflect(c);
  Expect.equals(21, im.setField(#mutableWithInheritedSetter, 21).reflectee);
  Expect.equals(21, c.mutableWithInheritedSetter);
  Expect.equals(0, c.sideEffect);

  c = new C();
  im = reflect(c);
  Expect.equals(22, im.setField(#finalWithInheritedMutable, 22).reflectee);
  Expect.equals(13, c.finalWithInheritedMutable);
  Expect.equals(22, c.superFinalWithInheritedMutable);
  Expect.equals(0, c.sideEffect);

  c = new C();
  im = reflect(c);
  Expect.throws(() => im.setField(#finalWithInheritedFinal, 23),
      (e) => e is NoSuchMethodError);
  Expect.equals(14, c.finalWithInheritedFinal);
  Expect.equals(5, c.superFinalWithInheritedFinal);
  Expect.equals(0, c.sideEffect);

  c = new C();
  im = reflect(c);
  Expect.equals(24, im.setField(#finalWithInheritedSetter, 24).reflectee);
  Expect.equals(15, c.finalWithInheritedSetter);
  Expect.equals(6, c.sideEffect);

  c = new C();
  im = reflect(c);
  Expect.equals(25, im.setField(#setterWithInheritedMutable, 25).reflectee);
  Expect.equals(7, c.setterWithInheritedMutable);
  Expect.equals(7, c.superSetterWithInheritedMutable);
  Expect.equals(16, c.sideEffect);

  c = new C();
  im = reflect(c);
  Expect.equals(26, im.setField(#setterWithInheritedFinal, 26).reflectee);
  Expect.equals(8, c.setterWithInheritedFinal);
  Expect.equals(8, c.superSetterWithInheritedFinal);
  Expect.equals(17, c.sideEffect);

  c = new C();
  im = reflect(c);
  Expect.equals(27, im.setField(#setterWithInheritedSetter, 27).reflectee);
  Expect.equals(18, c.sideEffect);
}
