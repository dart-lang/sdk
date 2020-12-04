// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class A {
  num get getterFromGetter;

  set setterFromSetter(num value);

  set getterFromSetter(num value);

  num get setterFromGetter;

  num get getterFromGetterWithSetterConflict;
  set getterFromGetterWithSetterConflict(num);

  num get setterFromSetterWithGetterConflict;
  set setterFromSetterWithGetterConflict(num);
}

abstract class B {
  int get getterFromGetter;

  set setterFromSetter(int value);

  int get setterFromGetter;

  int get setterFromSetterWithGetterConflict;

  set getterFromGetterWithSetterConflict(int value);

  set getterFromSetter(int value);
}

abstract class C extends A {
  get getterFromGetter;

  set setterFromSetter(value);

  get getterFromSetter;

  set setterFromGetter(value);

  get getterFromGetterWithSetterConflict;

  set setterFromSetterWithGetterConflict(value);
}

abstract class D extends A implements B {
  get getterFromGetter;

  set setterFromSetter(value);

  get getterFromSetter;

  set setterFromGetter(value);

  get getterFromGetterWithSetterConflict;

  set setterFromSetterWithGetterConflict(value);
}

abstract class E implements A {
  get getterFromGetter;

  set setterFromSetter(value);

  get getterFromSetter;

  set setterFromGetter(value);

  get getterFromGetterWithSetterConflict;

  set setterFromSetterWithGetterConflict(value);
}

abstract class F implements A, B {
  get getterFromGetter;

  set setterFromSetter(value);

  get getterFromSetter;

  set setterFromGetter(value);

  get getterFromGetterWithSetterConflict;

  set setterFromSetterWithGetterConflict(value);
}

main() {}
