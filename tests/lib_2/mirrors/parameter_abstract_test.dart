// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// BOGUS: Note that both AST and bytecode modes are missing default values.

import 'dart:mirrors';

import 'package:expect/expect.dart';
import 'stringify.dart';

const X = 'X';
const Y = 'Y';
const Z = 'Z';

abstract class C {
  foo1({@X int x: 1, @Y int y: 2, @Z int z: 3});
}

main() {
  ClassMirror cm = reflectClass(C);

  MethodMirror foo1 = cm.declarations[#foo1];
  expect('Method(s(foo1) in s(C), abstract)', foo1);
  expect(
      'Parameter(s(x) in s(foo1), optional, named, value = Instance(value = 1), type = Class(s(int) in s(dart.core), top-level))',
      foo1.parameters[0]);
  expect(
      'Parameter(s(y) in s(foo1), optional, named, value = Instance(value = 2), type = Class(s(int) in s(dart.core), top-level))',
      foo1.parameters[1]);
  expect(
      'Parameter(s(z) in s(foo1), optional, named, value = Instance(value = 3), type = Class(s(int) in s(dart.core), top-level))',
      foo1.parameters[2]);
}
