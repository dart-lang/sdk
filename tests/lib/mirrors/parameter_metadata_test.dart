// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.parameter_metadata_test;

@MirrorsUsed(targets: "test.parameter_metadata_test")
import 'dart:mirrors';

import 'metadata_test.dart';

const m1 = 'm1';
const m2 = #m2;
const m3 = const CustomAnnotation(3);

class CustomAnnotation {
  final value;
  const CustomAnnotation(this.value);
  toString() => 'CustomAnnotation($value)';
}

class B {
  B.foo(int x) {}
  factory B.bar(@m3 @m2 int z, x) {}

  baz(@m1 final int x, @m2 int y, @m3 final int z) {}
  qux(int x, [@m3 @m2 @m1 int y = 3 + 1]) {}
  quux(int x, {String str: "foo"}) {}
  corge({@m1 int x: 3 * 17, @m2 String str: "bar"}) {}

  set x(@m2 final value) {}
}

main() {
  ClassMirror cm = reflectClass(B);
  MethodMirror mm;

  mm = cm.declarations[#B.foo];
  checkMetadata(mm.parameters[0], []);

  mm = cm.declarations[#B.bar];
  checkMetadata(mm.parameters[0], [m3, m2]);
  checkMetadata(mm.parameters[1], []);

  mm = cm.declarations[#baz];
  checkMetadata(mm.parameters[0], [m1]);
  checkMetadata(mm.parameters[1], [m2]);
  checkMetadata(mm.parameters[2], [m3]);

  mm = cm.declarations[#qux];
  checkMetadata(mm.parameters[0], []);
  checkMetadata(mm.parameters[1], [m3, m2, m1]);

  mm = cm.declarations[#quux];
  checkMetadata(mm.parameters[0], []);
  checkMetadata(mm.parameters[1], []);

  mm = cm.declarations[#corge];
  checkMetadata(mm.parameters[0], [m1]);
  checkMetadata(mm.parameters[1], [m2]);

  mm = cm.declarations[const Symbol('x=')];
  checkMetadata(mm.parameters[0], [m2]);
}
