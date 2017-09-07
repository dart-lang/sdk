// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:mirrors";

import "package:expect/expect.dart";

doNothing42() {}

int _x = 5;
int get topGetter => _x;
void set topSetter(x) {
  _x = x;
}

abstract class AbstractC {
  AbstractC();

  void bar();
  get priv;
  set priv(value);
}

abstract class C extends AbstractC {
  static foo() {}

  C();
  C.other();
  C.other2() : this.other();

  var _priv;
  get priv => _priv;
  set priv(value) => _priv = value;
}

checkKinds(method, kinds) {
  Expect.equals(kinds[0], method.isStatic, "isStatic");
  Expect.equals(kinds[1], method.isAbstract, "isAbstract");
  Expect.equals(kinds[2], method.isGetter, "isGetter");
  Expect.equals(kinds[3], method.isSetter, "isSetter");
  Expect.equals(kinds[4], method.isConstructor, "isConstructor");
}

main() {
  // Top level functions should be static.
  var closureMirror = reflect(doNothing42);
  checkKinds(closureMirror.function, [true, false, false, false, false]);
  var libraryMirror = reflectClass(C).owner;
  checkKinds(libraryMirror.declarations[#topGetter],
      [true, false, true, false, false]);
  checkKinds(libraryMirror.declarations[const Symbol("topSetter=")],
      [true, false, false, true, false]);
  var classMirror;
  classMirror = reflectClass(C);
  checkKinds(
      classMirror.declarations[#foo], [true, false, false, false, false]);
  checkKinds(
      classMirror.declarations[#priv], [false, false, true, false, false]);
  checkKinds(classMirror.declarations[const Symbol("priv=")],
      [false, false, false, true, false]);
  checkKinds(classMirror.declarations[#C], [false, false, false, false, true]);
  checkKinds(
      classMirror.declarations[#C.other], [false, false, false, false, true]);
  checkKinds(
      classMirror.declarations[#C.other2], [false, false, false, false, true]);
  classMirror = reflectClass(AbstractC);
  checkKinds(
      classMirror.declarations[#AbstractC], [false, false, false, false, true]);
  checkKinds(
      classMirror.declarations[#bar], [false, true, false, false, false]);
  checkKinds(
      classMirror.declarations[#priv], [false, true, true, false, false]);
  checkKinds(classMirror.declarations[const Symbol("priv=")],
      [false, true, false, true, false]);
}
