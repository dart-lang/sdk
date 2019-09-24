// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UndefinedGetterTest);
    defineReflectiveTests(UndefinedGetterWithExtensionMethodsTest);
  });
}

@reflectiveTest
class UndefinedGetterTest extends DriverResolutionTest {
  test_compoundAssignment_hasSetter_instance() async {
    await assertErrorsInCode('''
class C {
  set foo(int _) {}
}

f(C c) {
  c.foo += 1;
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_GETTER, 46, 3),
    ]);
  }

  test_compoundAssignment_hasSetter_static() async {
    await assertErrorsInCode('''
class C {
  static set foo(int _) {}
}

f() {
  C.foo += 1;
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_GETTER, 50, 3),
    ]);
  }

  test_ifElement_inList_notPromoted() async {
    await assertErrorsInCode('''
f(int x) {
  return [if (x is String) x.length];
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_GETTER, 40, 6),
    ]);
  }

  test_ifElement_inList_promoted() async {
    await assertNoErrorsInCode('''
f(Object x) {
  return [if (x is String) x.length];
}
''');
  }

  test_ifElement_inMap_notPromoted() async {
    await assertErrorsInCode('''
f(int x) {
  return {if (x is String) x : x.length};
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_GETTER, 44, 6),
    ]);
  }

  test_ifElement_inMap_promoted() async {
    await assertNoErrorsInCode('''
f(Object x) {
  return {if (x is String) x : x.length};
}
''');
  }

  test_ifElement_inSet_notPromoted() async {
    await assertErrorsInCode('''
f(int x) {
  return {if (x is String) x.length};
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_GETTER, 40, 6),
    ]);
  }

  test_ifElement_inSet_promoted() async {
    await assertNoErrorsInCode('''
f(Object x) {
  return {if (x is String) x.length};
}
''');
  }

  test_ifStatement_notPromoted() async {
    await assertErrorsInCode('''
f(int x) {
  if (x is String) {
    x.length;
  }
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_GETTER, 38, 6),
    ]);
  }

  test_ifStatement_promoted() async {
    await assertNoErrorsInCode('''
f(Object x) {
  if (x is String) {
    x.length;
  }
}
''');
  }

  test_nullMember_undefined() async {
    await assertErrorsInCode(r'''
m() {
  Null _null;
  _null.foo;
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_GETTER, 28, 3),
    ]);
  }

  test_promotedTypeParameter_regress35305() async {
    await assertErrorsInCode(r'''
void f<X extends num, Y extends X>(Y y) {
  if (y is int) {
    y.isEven;
  }
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_GETTER, 66, 6),
    ]);
  }

  test_static_definedInSuperclass() async {
    await assertErrorsInCode('''
class S {
  static int get g => 0;
}
class C extends S {}
f(var p) {
  f(C.g);
}''', [
      error(StaticTypeWarningCode.UNDEFINED_GETTER, 75, 1),
    ]);
  }

  test_static_undefined() async {
    await assertErrorsInCode('''
class C {}
f(var p) {
  f(C.m);
}''', [
      error(StaticTypeWarningCode.UNDEFINED_GETTER, 28, 1),
    ]);
  }
}

@reflectiveTest
class UndefinedGetterWithExtensionMethodsTest extends UndefinedGetterTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..contextFeatures = new FeatureSet.forTesting(
        sdkVersion: '2.3.0', additionalFeatures: [Feature.extension_methods]);

  test_instance_extendedHasSetter_extensionHasGetter() async {
    await assertErrorsInCode('''
class C {
  void set foo(int _) {}
}

extension E on C {
  int get foo => 0;

  f() {
    this.foo;
  }
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_GETTER, 95, 3),
    ]);
  }

  test_instance_undefined_hasSetter() async {
    await assertErrorsInCode('''
extension E on int {
  void set foo(int _) {}
}
f() {
  0.foo;
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_GETTER, 58, 3),
    ]);
  }

  test_instance_withInference() async {
    await assertErrorsInCode(r'''
extension E on int {}
var a = 3.v;
''', [
      error(StaticTypeWarningCode.UNDEFINED_GETTER, 32, 1),
    ]);
  }

  test_instance_withoutInference() async {
    await assertErrorsInCode(r'''
class C {}

extension E on C {}

f(C c) {
  c.a;
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_GETTER, 46, 1),
    ]);
  }

  test_this_extendedHasSetter_extensionHasGetter() async {
    await assertErrorsInCode('''
class C {
  void set foo(int _) {}
}

extension E on C {
  int get foo => 0;
}

f(C c) {
  c.foo;
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_GETTER, 93, 3),
    ]);
  }
}
