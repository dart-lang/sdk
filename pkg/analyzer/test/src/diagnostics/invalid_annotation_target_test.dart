// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.g.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidAnnotationTarget_MustBeOverriddenTest);
    defineReflectiveTests(InvalidAnnotationTarget_MustCallSuperTest);
    defineReflectiveTests(InvalidAnnotationTarget_RedeclareTest);
    defineReflectiveTests(InvalidAnnotationTargetTest);
  });
}

@reflectiveTest
class InvalidAnnotationTarget_MustBeOverriddenTest
    extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfigWithMeta();
  }

  test_class_instance_field() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @mustBeOverridden
  int f = 0;
}
''');
  }

  test_class_instance_getter() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @mustBeOverridden
  int get f => 0;
}
''');
  }

  test_class_instance_method() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @mustBeOverridden
  void m() {}
}
''');
  }

  test_class_instance_setter() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @mustBeOverridden
  void set s(int value) {}
}
''');
  }

  test_class_static_field() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';
class A {
  @mustBeOverridden
  static int f = 0;
}
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 46, 16),
    ]);
  }

  test_class_static_getter() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';
class A {
  @mustBeOverridden
  static int get f => 0;
}
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 46, 16),
    ]);
  }

  test_class_static_method() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';
class A {
  @mustBeOverridden
  static void m() {}
}
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 46, 16),
    ]);
  }

  test_class_static_setter() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';
class A {
  @mustBeOverridden
  static void set f(int value) {}
}
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 46, 16),
    ]);
  }

  test_constructor() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

class C {
  @mustBeOverridden
  C();
}
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 47, 16),
    ]);
  }

  test_enum_member() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

enum E {
  one, two;
  @mustBeOverridden
  void m() {}
}
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 58, 16),
    ]);
  }

  test_extension_member() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

extension E on String {
  @mustBeOverridden
  void m() {}
}
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 61, 16),
    ]);
  }

  test_mixin_instance_method() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

mixin M {
  @mustBeOverridden
  void m() {}
}
''');
  }

  test_topLevel() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

@mustBeOverridden
void m() {}
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 35, 16),
    ]);
  }
}

@reflectiveTest
class InvalidAnnotationTarget_MustCallSuperTest
    extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfigWithMeta();
  }

  test_class_instance_field() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @mustCallSuper
  int f = 0;
}
''');
  }

  test_class_instance_getter() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @mustCallSuper
  int get f => 0;
}
''');
  }

  test_class_instance_method() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @mustCallSuper
  void m() {}
}
''');
  }

  test_class_instance_setter() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @mustCallSuper
  void set s(int value) {}
}
''');
  }

  test_class_static_field() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';
class A {
  @mustCallSuper
  static int f = 0;
}
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 46, 13),
    ]);
  }

  test_class_static_getter() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';
class A {
  @mustCallSuper
  static int get f => 0;
}
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 46, 13),
    ]);
  }

  test_class_static_method() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';
class A {
  @mustCallSuper
  static void m() {}
}
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 46, 13),
    ]);
  }

  test_class_static_setter() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';
class A {
  @mustCallSuper
  static void set f(int value) {}
}
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 46, 13),
    ]);
  }

  test_constructor() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

class C {
  @mustCallSuper
  C();
}
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 47, 13),
    ]);
  }

  test_enum_member() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

enum E {
  one, two;
  @mustCallSuper
  void m() {}
}
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 58, 13),
    ]);
  }

  test_extension_member() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

extension E on String {
  @mustCallSuper
  void m() {}
}
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 61, 13),
    ]);
  }

  test_mixin_instance_method() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

mixin M {
  @mustCallSuper
  void m() {}
}
''');
  }

  test_topLevel() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

@mustCallSuper
void m() {}
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 35, 13),
    ]);
  }
}

@reflectiveTest
class InvalidAnnotationTarget_RedeclareTest extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfigWithMeta();
  }

  test_class_instance_method() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

class C {
  @redeclare
  void m() {}
}
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 47, 9),
    ]);
  }

  test_extensionType_instance_getter() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class C {
  int get g => 0; 
}

extension type E(C c) implements C {
  @redeclare
  int get g => 0; 
}
''');
  }

  test_extensionType_instance_method() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class C {
  void m() {}
}

extension type E(C c) implements C {
  @redeclare
  void m() {}
}
''');
  }

  test_extensionType_instance_setter() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class C {
  set g(int i) {}
}

extension type E(C c) implements C {
  @redeclare
  set g(int i) {}
}
''');
  }

  test_extensionType_static_getter() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

class C {
  static int get g => 0; 
}

extension type E(C c) {
  @redeclare
  static int get g => 0; 
}
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 100, 9),
    ]);
  }

  test_extensionType_static_method() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

class C {
  static void m() {}
}

extension type E(C c) {
  @redeclare
  static void m() {}
}
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 95, 9),
    ]);
  }

  test_extensionType_static_setter() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

class C {
  static set g(int i) {}
}

extension type E(C c) {
  @redeclare
  static set g(int i) {}
}
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 99, 9),
    ]);
  }
}

@reflectiveTest
class InvalidAnnotationTargetTest extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfigWithMeta();
  }

  // TODO(pq): add tests for topLevelVariables:
  // https://dart-review.googlesource.com/c/sdk/+/200301
  void test_classType_class() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.classType})
class A {
  const A();
}

@A()
class C {}
''');
  }

  void test_classType_classTypeAlias() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.classType})
class A {
  const A();
}

mixin M {}

@A()
class C = Object with M;
''');
  }

  void test_classType_mixin() async {
    await assertErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.classType})
class A {
  const A();
}

@A()
mixin M {}
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 98, 1),
    ]);
  }

  void test_classType_topLevelVariable_constructor() async {
    await assertErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.classType})
class A {
  const A();
}

@A()
int x = 0;
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 98, 1),
    ]);
  }

  void test_classType_topLevelVariable_topLevelConstant() async {
    await assertErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.classType})
class A {
  const A();
}

const a = A();

@a
int x = 0;
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 114, 1),
    ]);
  }

  void test_constructor_constructor() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.constructor})
class A {
  const A();
}

class C {
  @A() C();
}
''');
  }

  void test_constructor_method() async {
    await assertErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.constructor})
class A {
  const A();
}

class C {
  @A() void m() {}
}
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 112, 1),
    ]);
  }

  void test_directive_class() async {
    await assertErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.directive})
class A {
  const A();
}

@A()
class C {}
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 98, 1),
    ]);
  }

  void test_directive_directive() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta_meta.dart';

@A()
import 'dart:core';

@Target({TargetKind.directive})
class A {
  const A();
}
''');
  }

  void test_enumType_class() async {
    await assertErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.enumType})
class A {
  const A();
}

@A()
class C {}
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 97, 1),
    ]);
  }

  void test_enumType_enum() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.enumType})
class A {
  const A();
}

@A()
enum E {a, b}
''');
  }

  void test_enumValue_enumValue() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.enumValue})
class A {
  const A();
}

enum E {
  @A() one, two;
}
''');
  }

  void test_enumValue_field() async {
    await assertErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.enumValue})
class A {
  const A();
}

class C {
  @A() int f = 7;
}
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 110, 1),
    ]);
  }

  void test_extension_class() async {
    await assertErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.extension})
class A {
  const A();
}

@A()
class C {}
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 98, 1),
    ]);
  }

  void test_extension_extension() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.extension})
class A {
  const A();
}

@A()
extension on C {}
class C {}
''');
  }

  void test_extension_type_parameter() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.parameter})
class A {
  const A();
}

extension type const E(@A() int x) {}
''');
  }

  void test_field_field() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.field})
class A {
  const A();
}

class C {
  @A()
  int f = 0;
}
''');
  }

  void test_function_function() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.function})
class A {
  const A();
}

@A()
int f(int x) => 0;
''');
  }

  void test_function_method() async {
    await assertErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.function})
class A {
  const A();
}

class C {
  @A()
  int M(int x) => 0;
}
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 109, 1),
    ]);
  }

  void test_function_topLevelGetter() async {
    await assertErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.function})
class A {
  const A();
}

@A()
int get x => 0;
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 97, 1),
    ]);
  }

  void test_function_topLevelSetter() async {
    await assertErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.function})
class A {
  const A();
}

@A()
set x(_x) {}
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 97, 1),
    ]);
  }

  void test_getter_getter() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.getter})
class A {
  const A();
}

class C {
  @A()
  int get x => 0;
}
''');
  }

  void test_getter_method() async {
    await assertErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.getter})
class A {
  const A();
}

class C {
  @A()
  int m(int x) => x;
}
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 107, 1),
    ]);
  }

  void test_getter_setter() async {
    await assertErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.getter})
class A {
  const A();
}

class C {
  @A()
  set x(int _x) {}
}
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 107, 1),
    ]);
  }

  void test_getter_topLevelGetter() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.getter})
class A {
  const A();
}

@A()
int get x => 0;
''');
  }

  void test_library_class() async {
    await assertErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.library})
class A {
  const A();
}

@A()
class C {}
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 96, 1),
    ]);
  }

  void test_library_import() async {
    await assertNoErrorsInCode('''
@A()
import 'package:meta/meta_meta.dart';

@Target({TargetKind.library})
class A {
  const A();
}
''');
  }

  void test_library_library() async {
    await assertNoErrorsInCode('''
@A()
library test;

import 'package:meta/meta_meta.dart';

@Target({TargetKind.library})
class A {
  const A();
}
''');
  }

  void test_method_getter() async {
    await assertErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.method})
class A {
  const A();
}

class C {
  @A()
  int get x => 0;
}
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 107, 1),
    ]);
  }

  void test_method_method() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.method})
class A {
  const A();
}

class C {
  @A()
  int m(int x) => x;
}
''');
  }

  void test_method_operator() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.method})
class A {
  const A();
}

class C {
  @A()
  int operator +(int x) => x;
}
''');
  }

  void test_method_setter() async {
    await assertErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.method})
class A {
  const A();
}

class C {
  @A()
  set x(int _x) {}
}
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 107, 1),
    ]);
  }

  void test_method_topLevelFunction() async {
    await assertErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.method})
class A {
  const A();
}

@A()
int f(int x) => x;
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 95, 1),
    ]);
  }

  void test_mixinType_class() async {
    await assertErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.mixinType})
class A {
  const A();
}

@A()
class C {}
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 98, 1),
    ]);
  }

  void test_mixinType_mixin() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.mixinType})
class A {
  const A();
}

@A()
mixin M {}
''');
  }

  void test_multiple_invalid() async {
    await assertErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.classType, TargetKind.method})
class A {
  const A();
}

@A()
int x = 0;
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 117, 1),
    ]);
  }

  void test_multiple_valid() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.classType, TargetKind.method})
class A {
  const A();
}

@A()
class C {
  @A()
  int m(int x) => x;
}
''');
  }

  void test_optionalParameter_optionalNamed() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.optionalParameter})
class A {
  const A();
}

void f({@A() int? x}) {}
''');
  }

  void test_optionalParameter_optionalPositional() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.optionalParameter})
class A {
  const A();
}

void f([@A() int? x]) {}
''');
  }

  void test_optionalParameter_requiredNamed() async {
    await assertErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.optionalParameter})
class A {
  const A();
}

void f({@A() required int x}) {}
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 114, 1),
    ]);
  }

  void test_optionalParameter_requiredPositional() async {
    await assertErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.optionalParameter})
class A {
  const A();
}

void f(@A() int x) {}
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 113, 1),
    ]);
  }

  void test_overridableMember_constructor() async {
    await assertErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.overridableMember})
class A {
  const A();
}

class C {
  @A()
  C();
}
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 118, 1),
    ]);
  }

  void test_overridableMember_instanceGetter() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.overridableMember})
class A {
  const A();
}

class C {
  @A()
  int get x => 0;
}
''');
  }

  void test_overridableMember_instanceMethod() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.overridableMember})
class A {
  const A();
}

class C {
  @A()
  int x() => 0;
}
''');
  }

  void test_overridableMember_instanceMethod_onEnum() async {
    await assertErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.overridableMember})
class A {
  const A();
}

enum E {
  one, two;
  @A()
  int x() => 0;
}
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 129, 1),
    ]);
  }

  void test_overridableMember_instanceMethod_onExtension() async {
    await assertErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.overridableMember})
class A {
  const A();
}

extension E on int {
  @A()
  int x() => 0;
}
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 129, 1),
    ]);
  }

  void test_overridableMember_instanceMethod_onMixin() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.overridableMember})
class A {
  const A();
}

mixin M {
  @A()
  int x() => 0;
}
''');
  }

  void test_overridableMember_instanceOperator() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.overridableMember})
class A {
  const A();
}

class C {
  @A()
  int operator +(int value) => 0;
}
''');
  }

  void test_overridableMember_instanceSetter() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.overridableMember})
class A {
  const A();
}

class C {
  @A()
  set x(int value) {}
}
''');
  }

  void test_overridableMember_staticMethod() async {
    await assertErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.overridableMember})
class A {
  const A();
}

class C {
  @A()
  static int x() => 0;
}
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 118, 1),
    ]);
  }

  void test_parameter_function() async {
    await assertErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.parameter})
class A {
  const A();
}

@A()
void f(int x) {}
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 98, 1),
    ]);
  }

  void test_parameter_parameter() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.parameter})
class A {
  const A();
}

void f(@A() int x) {}
''');
  }

  void test_setter_getter() async {
    await assertErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.setter})
class A {
  const A();
}

class C {
  @A()
  int get x => 0;
}
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 107, 1),
    ]);
  }

  void test_setter_method() async {
    await assertErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.setter})
class A {
  const A();
}

class C {
  @A()
  int m(int x) => x;
}
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 107, 1),
    ]);
  }

  void test_setter_setter() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.setter})
class A {
  const A();
}

class C {
  @A()
  set x(int _x) {}
}
''');
  }

  void test_setter_topLevelSetter() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.setter})
class A {
  const A();
}

@A()
set x(_x) {}
''');
  }

  void test_topLevelVariable_field() async {
    await assertErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.topLevelVariable})
class A {
  const A();
}

class B {
  @A()
  int f = 0;
}
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 117, 1),
    ]);
  }

  void test_topLevelVariable_topLevelVariable() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.topLevelVariable})
class A {
  const A();
}

@A()
int f = 0;
''');
  }

  void test_type_class() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.type})
class A {
  const A();
}

@A()
class C {}
''');
  }

  void test_type_classTypeAlias() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.type})
class A {
  const A();
}

mixin M {}

@A()
class C = Object with M;
''');
  }

  void test_type_enum() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.type})
class A {
  const A();
}

@A()
enum E {a, b}
''');
  }

  void test_type_extension() async {
    await assertErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.type})
class A {
  const A();
}

@A()
extension on C {}
class C {}
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 93, 1),
    ]);
  }

  void test_type_genericTypeAlias() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.type})
class A {
  const A();
}

@A()
typedef F = void Function(int);
''');
  }

  void test_type_mixin() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.type})
class A {
  const A();
}

@A()
mixin M {}
''');
  }

  void test_typedefType_genericTypeAlias() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.typedefType})
class A {
  const A();
}

@A()
typedef F = void Function(int);
''');
  }

  void test_typeParameter_parameter() async {
    await assertErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.typeParameter})
class A {
  const A();
}

void f(@A() p) {}
''', [
      error(WarningCode.INVALID_ANNOTATION_TARGET, 109, 1),
    ]);
  }

  void test_typeParameter_typeParameter() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta_meta.dart';

@Target({TargetKind.typeParameter})
class A {
  const A();
}

class C<@A() T> {}
''');
  }
}
