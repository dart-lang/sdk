// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:mirrors';

import 'package:expect/expect.dart';
import 'stringify.dart';

const X = 'X';
const Y = 'Y';
const Z = 'Z';

class C {
  positional1(u, v, w, [@X int x = 1, @Y int y = 2, @Z int z = 3]) {}
  positional2(u, v, w, [@Y int y = 1, @Z int z = 2, @X int x = 3]) {}
  positional3(u, v, w, [@Z int z = 1, @X int x = 2, @Y int y = 3]) {}

  named1(u, v, w, {@X int x: 1, @Y int y: 2, @Z int z: 3}) {}
  named2(u, v, w, {@Y int y: 1, @Z int z: 2, @X int x: 3}) {}
  named3(u, v, w, {@Z int z: 1, @X int x: 2, @Y int y: 3}) {}
}

testPositional() {
  ClassMirror cm = reflectClass(C);

  MethodMirror positional1 = cm.declarations[#positional1] as MethodMirror;
  expect('Method(s(positional1) in s(C))', positional1);
  expect(
      'Parameter(s(x) in s(positional1), optional, value = Instance(value = 1), type = Class(s(int) in s(dart.core), top-level))',
      positional1.parameters[3]);
  expect(
      'Parameter(s(y) in s(positional1), optional, value = Instance(value = 2), type = Class(s(int) in s(dart.core), top-level))',
      positional1.parameters[4]);
  expect(
      'Parameter(s(z) in s(positional1), optional, value = Instance(value = 3), type = Class(s(int) in s(dart.core), top-level))',
      positional1.parameters[5]);

  MethodMirror positional2 = cm.declarations[#positional2] as MethodMirror;
  expect('Method(s(positional2) in s(C))', positional2);
  expect(
      'Parameter(s(y) in s(positional2), optional, value = Instance(value = 1), type = Class(s(int) in s(dart.core), top-level))',
      positional2.parameters[3]);
  expect(
      'Parameter(s(z) in s(positional2), optional, value = Instance(value = 2), type = Class(s(int) in s(dart.core), top-level))',
      positional2.parameters[4]);
  expect(
      'Parameter(s(x) in s(positional2), optional, value = Instance(value = 3), type = Class(s(int) in s(dart.core), top-level))',
      positional2.parameters[5]);

  MethodMirror positional3 = cm.declarations[#positional3] as MethodMirror;
  expect('Method(s(positional3) in s(C))', positional3);
  expect(
      'Parameter(s(z) in s(positional3), optional, value = Instance(value = 1), type = Class(s(int) in s(dart.core), top-level))',
      positional3.parameters[3]);
  expect(
      'Parameter(s(x) in s(positional3), optional, value = Instance(value = 2), type = Class(s(int) in s(dart.core), top-level))',
      positional3.parameters[4]);
  expect(
      'Parameter(s(y) in s(positional3), optional, value = Instance(value = 3), type = Class(s(int) in s(dart.core), top-level))',
      positional3.parameters[5]);
}

testNamed() {
  ClassMirror cm = reflectClass(C);

  MethodMirror named1 = cm.declarations[#named1] as MethodMirror;
  expect('Method(s(named1) in s(C))', named1);
  expect(
      'Parameter(s(x) in s(named1), optional, named, value = Instance(value = 1), type = Class(s(int) in s(dart.core), top-level))',
      named1.parameters[3]);
  expect(
      'Parameter(s(y) in s(named1), optional, named, value = Instance(value = 2), type = Class(s(int) in s(dart.core), top-level))',
      named1.parameters[4]);
  expect(
      'Parameter(s(z) in s(named1), optional, named, value = Instance(value = 3), type = Class(s(int) in s(dart.core), top-level))',
      named1.parameters[5]);

  MethodMirror named2 = cm.declarations[#named2] as MethodMirror;
  expect('Method(s(named2) in s(C))', named2);
  expect(
      'Parameter(s(y) in s(named2), optional, named, value = Instance(value = 1), type = Class(s(int) in s(dart.core), top-level))',
      named2.parameters[3]);
  expect(
      'Parameter(s(z) in s(named2), optional, named, value = Instance(value = 2), type = Class(s(int) in s(dart.core), top-level))',
      named2.parameters[4]);
  expect(
      'Parameter(s(x) in s(named2), optional, named, value = Instance(value = 3), type = Class(s(int) in s(dart.core), top-level))',
      named2.parameters[5]);

  MethodMirror named3 = cm.declarations[#named3] as MethodMirror;
  expect('Method(s(named3) in s(C))', named3);
  expect(
      'Parameter(s(z) in s(named3), optional, named, value = Instance(value = 1), type = Class(s(int) in s(dart.core), top-level))',
      named3.parameters[3]);
  expect(
      'Parameter(s(x) in s(named3), optional, named, value = Instance(value = 2), type = Class(s(int) in s(dart.core), top-level))',
      named3.parameters[4]);
  expect(
      'Parameter(s(y) in s(named3), optional, named, value = Instance(value = 3), type = Class(s(int) in s(dart.core), top-level))',
      named3.parameters[5]);
}

main() {
  testPositional();
  testNamed();
}
