// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:mirrors";

import "package:expect/expect.dart";

doNothing42() {}

int _x = 5;
int get topGetter => _x;
void set topSetter(x) { _x = x; }

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
  Expect.equals(method.isStatic, kinds[0]);
  Expect.equals(method.isAbstract, kinds[1]);
  Expect.equals(method.isGetter, kinds[2]);
  Expect.equals(method.isSetter, kinds[3]);
  Expect.equals(method.isConstructor, kinds[4]);
}

main() {
  // Top level functions should be static.
  var closureMirror = reflect(doNothing42);
  checkKinds(closureMirror.function,
      [true, false, false, false, false]);
  var libraryMirror = reflectClass(C).owner;
  checkKinds(libraryMirror.getters[#topGetter],
      [true, false, true, false, false]);
  checkKinds(libraryMirror.setters[const Symbol("topSetter=")],
      [true, false, false, true, false]);
  var classMirror;
  classMirror = reflectClass(C);
  checkKinds(classMirror.members[#foo],
      [true, false, false, false, false]);
  checkKinds(classMirror.members[#priv],
      [false, false, true, false, false]);
  checkKinds(classMirror.members[const Symbol("priv=")],
      [false, false, false, true, false]);
  checkKinds(classMirror.constructors[#C],
      [false, false, false, false, true]);
  checkKinds(classMirror.constructors[#C.other],
      [false, false, false, false, true]);
  checkKinds(classMirror.constructors[#C.other2],
      [false, false, false, false, true]);
  classMirror = reflectClass(AbstractC);
  checkKinds(classMirror.constructors[#AbstractC],
      [false, false, false, false, true]);
  checkKinds(classMirror.members[#bar],
      [false, true, false, false, false]);
  checkKinds(classMirror.members[#priv],
      [false, true, true, false, false]);
  checkKinds(classMirror.members[const Symbol("priv=")],
      [false, true, false, true, false]);
}
