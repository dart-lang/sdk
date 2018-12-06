// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N annotate_overrides`

class A {
  int get x => 4;
  f() {}
  g() {}
}

class B extends A {
  int x = 5; //LINT
  f() {} //LINT
  @override
  g() {} //OK
}

class C extends A {
  int get x => 5; //LINT
}

class D extends A {
  @override
  int get x => 5; //OK
}

class E extends A {
  @override
  int x = 5; //OK
}

abstract class Dog {
  String get breed;
  void bark() {}
}

class Husky extends Dog {
  @override
  final String breed = 'Husky';
  @override
  void bark() {}
}
