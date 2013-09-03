// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.parameter_metadata_test;

import 'dart:mirrors';

import 'metadata_test.dart';

const m1 = 'm1';
const m2 = const Symbol('m2');
const m3 = const CustomAnnotation(3);

class CustomAnnotation {
  final value;
  const CustomAnnotation(this.value);
  toString() => 'CustomAnnotation($value)';
}

class B {
  B.foo(int x);
  factory B.bar(@m3 @m2 int z, x){}

  baz(@m1 final int x, @m2 int y, @m3 final int z);
  qux(int x, [@m3 @m2 @m1 int y= 3 + 1]);
  quux(int x, {String str: "foo"});
  corge({@m1 int x: 3 * 17, @m2 String str: "bar"});

  set x(@m2 final value);
}

main() {
  ClassMirror cm = reflectClass(B);

  checkMetadata(cm.constructors[const Symbol('B.foo')].parameters[0], []);

  checkMetadata(cm.constructors[const Symbol('B.bar')].parameters[0], [m3, m2]);
  checkMetadata(cm.constructors[const Symbol('B.bar')].parameters[1], []);

  checkMetadata(cm.members[const Symbol('baz')].parameters[0], [m1]);
  checkMetadata(cm.members[const Symbol('baz')].parameters[1], [m2]);
  checkMetadata(cm.members[const Symbol('baz')].parameters[2], [m3]);

  checkMetadata(cm.members[const Symbol('qux')].parameters[0], []);
  checkMetadata(cm.members[const Symbol('qux')].parameters[1], [m3, m2, m1]);

  checkMetadata(cm.members[const Symbol('quux')].parameters[0], []);
  checkMetadata(cm.members[const Symbol('quux')].parameters[1], []);

  checkMetadata(cm.members[const Symbol('corge')].parameters[0], [m1]);
  checkMetadata(cm.members[const Symbol('corge')].parameters[1], [m2]);

  checkMetadata(cm.members[const Symbol('x=')].parameters[0], [m2]);
}
