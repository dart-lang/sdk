// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test uses the multi-test "ok" feature to create two positive tests from
// one file. One of these tests fail on dart2js, but pass on the VM, or vice
// versa.
// TODO(ahe): When both implementations agree, remove the multi-test parts.

library test.mixin_application_test;

import 'dart:mirrors';

import 'package:expect/expect.dart';

import 'model.dart';
import 'stringify.dart';

class Mixin {
  int i;
  m() {}
}

class Mixin2 {
  int i2;
  m2() {}
}

class MixinApplication = C with Mixin;
class MixinApplicationA = C with Mixin, Mixin2;

class UnusedMixinApplication = C with Mixin;

class Subclass extends C with Mixin {
  f() {}
}

class Subclass2 extends MixinApplication {
  g() {}
}

class SubclassA extends C with Mixin, Mixin2 {
  fa() {}
}

class Subclass2A extends MixinApplicationA {
  ga() {}
}

membersOf(ClassMirror cm) {
  var result = new Map();
  cm.declarations.forEach((k,v) {
    if(v is MethodMirror && !v.isConstructor) result[k] = v;
    if(v is VariableMirror) result[k] = v;
  });
  return result;
}

constructorsOf(ClassMirror cm) {
  var result = new Map();
  cm.declarations.forEach((k,v) {
    if(v is MethodMirror && v.isConstructor) result[k] = v;
  });
  return result;
}

checkClass(Type type, List<String> expectedSuperclasses) {
  int i = 0;
  for (var cls = reflectClass(type); cls != null; cls = cls.superclass) {
    expect(expectedSuperclasses[i++], cls);
  }
  Expect.equals(i, expectedSuperclasses.length, '$type');
}

expectSame(ClassMirror a, ClassMirror b) {
  Expect.equals(a, b);
  expect(stringify(a), b);
  expect(stringify(b), a);
}

testMixin() {
  checkClass(Mixin, [
      'Class(s(Mixin) in s(test.mixin_application_test), top-level)',
      'Class(s(Object) in s(dart.core), top-level)',
  ]);

  expect(
      '{i: Variable(s(i) in s(Mixin)),'
      ' m: Method(s(m) in s(Mixin))}',
      membersOf(reflectClass(Mixin)));

  expect('{Mixin: Method(s(Mixin) in s(Mixin), constructor)}',
         constructorsOf(reflectClass(Mixin)));
}

testMixin2() {
  checkClass(Mixin2, [
      'Class(s(Mixin2) in s(test.mixin_application_test), top-level)',
      'Class(s(Object) in s(dart.core), top-level)',
  ]);

  expect(
      '{i2: Variable(s(i2) in s(Mixin2)),'
      ' m2: Method(s(m2) in s(Mixin2))}',
      membersOf(reflectClass(Mixin2)));

  expect('{Mixin2: Method(s(Mixin2) in s(Mixin2), constructor)}',
         constructorsOf(reflectClass(Mixin2)));
}

testMixinApplication() {
  checkClass(MixinApplication, [
      'Class(s(MixinApplication) in s(test.mixin_application_test), top-level)',
      'Class(s(C) in s(test.model), top-level)',
      'Class(s(B) in s(test.model), top-level)',
      'Class(s(A) in s(test.model), top-level)',
      'Class(s(Object) in s(dart.core), top-level)',
  ]);

  String owner = 'Mixin';
  expect(
      '{i: Variable(s(i) in s($owner)),'
      ' m: Method(s(m) in s($owner))}',
      membersOf(reflectClass(MixinApplication)));

  expect('{MixinApplication: Method(s(MixinApplication) in s(MixinApplication),'
         ' constructor)}',
         constructorsOf(reflectClass(MixinApplication)));

  expectSame(reflectClass(C), reflectClass(MixinApplication).superclass);
}

testMixinApplicationA() {
  String owner = ' in s(test.mixin_application_test)';
  checkClass(MixinApplicationA, [
      'Class(s(MixinApplicationA)'
      ' in s(test.mixin_application_test), top-level)',
      'Class(s(test.model.C with test.mixin_application_test.Mixin)'
      '$owner, top-level)',
      'Class(s(C) in s(test.model), top-level)',
      'Class(s(B) in s(test.model), top-level)',
      'Class(s(A) in s(test.model), top-level)',
      'Class(s(Object) in s(dart.core), top-level)',
  ]);

  owner = 'Mixin2';
  expect(
      '{i2: Variable(s(i2) in s($owner)),'
      ' m2: Method(s(m2) in s($owner))}',
      membersOf(reflectClass(MixinApplicationA)));

  expect(
      '{MixinApplicationA: Method(s(MixinApplicationA) in s(MixinApplicationA),'
      ' constructor)}',
      constructorsOf(reflectClass(MixinApplicationA)));

  expect(
      '{i: Variable(s(i) in s(Mixin)),'
      ' m: Method(s(m) in s(Mixin))}',
      membersOf(reflectClass(MixinApplicationA).superclass));

  String name = 'test.model.C with test.mixin_application_test.Mixin';
  expect(
      '{$name:'
      ' Method(s($name)'
      ' in s($name), constructor)}',
      constructorsOf(reflectClass(MixinApplicationA).superclass));

  expectSame(
      reflectClass(C),
      reflectClass(MixinApplicationA).superclass.superclass);
}

testUnusedMixinApplication() {
  checkClass(UnusedMixinApplication, [
      'Class(s(UnusedMixinApplication) in s(test.mixin_application_test),'
      ' top-level)',
      'Class(s(C) in s(test.model), top-level)',
      'Class(s(B) in s(test.model), top-level)',
      'Class(s(A) in s(test.model), top-level)',
      'Class(s(Object) in s(dart.core), top-level)',
  ]);

  String owner = 'Mixin';
  expect(
      '{i: Variable(s(i) in s($owner)),'
      ' m: Method(s(m) in s($owner))}',
      membersOf(reflectClass(UnusedMixinApplication)));

  expect(
      '{UnusedMixinApplication: Method(s(UnusedMixinApplication)'
      ' in s(UnusedMixinApplication), constructor)}',
      constructorsOf(reflectClass(UnusedMixinApplication)));

  expectSame(reflectClass(C), reflectClass(UnusedMixinApplication).superclass);
}

testSubclass() {
  String owner = ' in s(test.mixin_application_test)';
  checkClass(Subclass, [
      'Class(s(Subclass) in s(test.mixin_application_test), top-level)',
      'Class(s(test.model.C with test.mixin_application_test.Mixin)'
      '$owner, top-level)',
      'Class(s(C) in s(test.model), top-level)',
      'Class(s(B) in s(test.model), top-level)',
      'Class(s(A) in s(test.model), top-level)',
      'Class(s(Object) in s(dart.core), top-level)',
  ]);

  expect(
      '{f: Method(s(f) in s(Subclass))}',
      membersOf(reflectClass(Subclass)));

  expect(
      '{Subclass: Method(s(Subclass) in s(Subclass), constructor)}',
      constructorsOf(reflectClass(Subclass)));

  expect(
      '{i: Variable(s(i) in s(Mixin)),'
      ' m: Method(s(m) in s(Mixin))}',
      membersOf(reflectClass(Subclass).superclass));

  String name = 'test.model.C with test.mixin_application_test.Mixin';
  expect(
      '{$name:'
      ' Method(s($name)'
      ' in s($name), constructor)}',
      constructorsOf(reflectClass(Subclass).superclass));

  expectSame(
      reflectClass(C),
      reflectClass(Subclass).superclass.superclass);
}

testSubclass2() {
  checkClass(Subclass2, [
      'Class(s(Subclass2) in s(test.mixin_application_test), top-level)',
      'Class(s(MixinApplication) in s(test.mixin_application_test), top-level)',
      'Class(s(C) in s(test.model), top-level)',
      'Class(s(B) in s(test.model), top-level)',
      'Class(s(A) in s(test.model), top-level)',
      'Class(s(Object) in s(dart.core), top-level)',
  ]);

  expect(
      '{g: Method(s(g) in s(Subclass2))}',
      membersOf(reflectClass(Subclass2)));

  expect(
      '{Subclass2: Method(s(Subclass2) in s(Subclass2), constructor)}',
      constructorsOf(reflectClass(Subclass2)));

  expectSame(
      reflectClass(MixinApplication),
      reflectClass(Subclass2).superclass);
}

testSubclassA() {
  String owner = ' in s(test.mixin_application_test)';
  checkClass(SubclassA, [
      'Class(s(SubclassA) in s(test.mixin_application_test), top-level)',
      'Class(s(test.model.C with test.mixin_application_test.Mixin,'
      ' test.mixin_application_test.Mixin2)$owner, top-level)',
      'Class(s(test.model.C with test.mixin_application_test.Mixin)$owner,'
      ' top-level)',
      'Class(s(C) in s(test.model), top-level)',
      'Class(s(B) in s(test.model), top-level)',
      'Class(s(A) in s(test.model), top-level)',
      'Class(s(Object) in s(dart.core), top-level)',
  ]);

  expect(
      '{fa: Method(s(fa) in s(SubclassA))}',
      membersOf(reflectClass(SubclassA)));

  expect(
      '{SubclassA: Method(s(SubclassA) in s(SubclassA), constructor)}',
      constructorsOf(reflectClass(SubclassA)));

  expect(
      '{i2: Variable(s(i2) in s(Mixin2)),'
      ' m2: Method(s(m2) in s(Mixin2))}',
      membersOf(reflectClass(SubclassA).superclass));

  String name =
      'test.model.C with test.mixin_application_test.Mixin,'
      ' test.mixin_application_test.Mixin2';
  expect(
      '{$name: Method(s($name) in s($name), constructor)}',
      constructorsOf(reflectClass(SubclassA).superclass));

  expect(
      '{i: Variable(s(i) in s(Mixin)),'
      ' m: Method(s(m) in s(Mixin))}',
      membersOf(reflectClass(SubclassA).superclass.superclass));

  name = 'test.model.C with test.mixin_application_test.Mixin';
  expect(
      '{$name:'
      ' Method(s($name)'
      ' in s($name), constructor)}',
      constructorsOf(reflectClass(SubclassA).superclass.superclass));

  expectSame(
      reflectClass(C),
      reflectClass(SubclassA).superclass.superclass.superclass);
}

testSubclass2A() {
  String owner = ' in s(test.mixin_application_test)';
  checkClass(Subclass2A, [
      'Class(s(Subclass2A) in s(test.mixin_application_test), top-level)',
      'Class(s(MixinApplicationA) in s(test.mixin_application_test),'
      ' top-level)',
      'Class(s(test.model.C with test.mixin_application_test.Mixin)$owner,'
      ' top-level)',
      'Class(s(C) in s(test.model), top-level)',
      'Class(s(B) in s(test.model), top-level)',
      'Class(s(A) in s(test.model), top-level)',
      'Class(s(Object) in s(dart.core), top-level)',
  ]);

  expect(
      '{ga: Method(s(ga) in s(Subclass2A))}',
      membersOf(reflectClass(Subclass2A)));

  expect(
      '{Subclass2A: Method(s(Subclass2A) in s(Subclass2A), constructor)}',
      constructorsOf(reflectClass(Subclass2A)));

  expectSame(reflectClass(MixinApplicationA),
             reflectClass(Subclass2A).superclass);
}

main() {
  testMixin();
  testMixin2();
  testMixinApplication();
  testMixinApplicationA();
  testUnusedMixinApplication();
  testSubclass();
  testSubclass2();
  testSubclassA();
  testSubclass2A();
}
