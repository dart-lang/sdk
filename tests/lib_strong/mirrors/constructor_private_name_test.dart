// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.constructors_test;

// Regression test for C1 bug.

import 'dart:mirrors';

import 'package:expect/expect.dart';

class Foo {
  Foo._private();
}

class _Foo {
  _Foo._private();
}

main() {
  ClassMirror fooMirror = reflectClass(Foo);
  Symbol constructorName =
      (fooMirror.declarations[#Foo._private] as MethodMirror).constructorName;
  fooMirror.newInstance(constructorName, []);

  ClassMirror _fooMirror = reflectClass(_Foo);
  constructorName =
      (_fooMirror.declarations[#_Foo._private] as MethodMirror).constructorName;
  _fooMirror.newInstance(constructorName, []);
}
