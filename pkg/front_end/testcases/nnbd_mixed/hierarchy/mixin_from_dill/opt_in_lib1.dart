// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {}

class B extends A {
  int get property => 0;
}

class C extends A {}

class Base {
  B get _privateGetter => new B();
  void set _privateSetter(A a) {}
}

abstract class Interface1 {
  A get getter;
  void set setter(C c);
}

abstract class Interface2 {
  A get _privateGetter;
  void set _privateSetter(C c);
}

testInterface2(Interface2 c) {
  try {
    c._privateGetter;
    throw 'Expected NoSuchMethodError';
  } on NoSuchMethodError (e) {
    print(e);
  }
  try {
    c._privateSetter = new C();
    throw 'Expected NoSuchMethodError';
  } on NoSuchMethodError (e) {
    print(e);
  }
}
