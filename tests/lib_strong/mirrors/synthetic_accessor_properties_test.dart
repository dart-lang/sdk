// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.synthetic_accessor_properties;

import 'dart:mirrors';
import 'package:expect/expect.dart';

import 'stringify.dart';

class C {
  String instanceField;
  final num finalInstanceField = 2;

  static bool staticField;
  static final int finalStaticField = 4;
}

String topLevelField;
final double finalTopLevelField = 6.0;

main() {
  ClassMirror cm = reflectClass(C);
  LibraryMirror lm = cm.owner;
  MethodMirror mm;
  ParameterMirror pm;

  mm = cm.instanceMembers[#instanceField];
  expect('Method(s(instanceField) in s(C), synthetic, getter)', mm);
  Expect.equals(reflectClass(String), mm.returnType);
  Expect.listEquals([], mm.parameters);

  mm = cm.instanceMembers[const Symbol('instanceField=')];
  expect('Method(s(instanceField=) in s(C), synthetic, setter)', mm);
  Expect.equals(reflectClass(String), mm.returnType);
  pm = mm.parameters.single;
  expect(
      'Parameter(s(instanceField) in s(instanceField=), final,'
      ' type = Class(s(String) in s(dart.core), top-level))',
      pm);

  mm = cm.instanceMembers[#finalInstanceField];
  expect('Method(s(finalInstanceField) in s(C), synthetic, getter)', mm);
  Expect.equals(reflectClass(num), mm.returnType);
  Expect.listEquals([], mm.parameters);

  mm = cm.instanceMembers[const Symbol('finalInstanceField=')];
  Expect.isNull(mm);

  mm = cm.staticMembers[#staticField];
  expect('Method(s(staticField) in s(C), synthetic, static, getter)', mm);
  Expect.equals(reflectClass(bool), mm.returnType);
  Expect.listEquals([], mm.parameters);

  mm = cm.staticMembers[const Symbol('staticField=')];
  expect('Method(s(staticField=) in s(C), synthetic, static, setter)', mm);
  Expect.equals(reflectClass(bool), mm.returnType);
  pm = mm.parameters.single;
  expect(
      'Parameter(s(staticField) in s(staticField=), final,'
      ' type = Class(s(bool) in s(dart.core), top-level))',
      pm);

  mm = cm.staticMembers[#finalStaticField];
  expect('Method(s(finalStaticField) in s(C), synthetic, static, getter)', mm);
  Expect.equals(reflectClass(int), mm.returnType);
  Expect.listEquals([], mm.parameters);

  mm = cm.staticMembers[const Symbol('finalStaticField=')];
  Expect.isNull(mm);
}
