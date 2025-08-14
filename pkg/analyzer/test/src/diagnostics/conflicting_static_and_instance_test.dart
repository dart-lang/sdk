// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConflictingStaticAndInstanceClassTest);
    defineReflectiveTests(ConflictingStaticAndInstanceEnumTest);
    defineReflectiveTests(ConflictingStaticAndInstanceMixinTest);
    defineReflectiveTests(ConflictingStaticAndInstanceExtensionTypeTest);
  });
}

@reflectiveTest
class ConflictingStaticAndInstanceClassTest extends PubPackageResolutionTest {
  test_inClass_instanceMethod_staticMethod() async {
    await assertErrorsInCode(
      r'''
class C {
  void foo() {}
  static void foo() {}
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 40, 3)],
    );
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_inClass_instanceMethod_staticMethodInAugmentation() async {
    await assertErrorsInCode(
      r'''
class A {
  void foo() {}
}

augment class A {
  static void foo() {}
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 61, 3)],
    );
  }

  test_inClass_staticGetter_instanceGetter() async {
    await assertErrorsInCode(
      r'''
class C {
  static int get foo => 0;
  int get foo => 0;
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 27, 3)],
    );
  }

  test_inClass_staticGetter_instanceMethod() async {
    await assertErrorsInCode(
      r'''
class C {
  static int get foo => 0;
  void foo() {}
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 27, 3)],
    );
  }

  test_inClass_staticGetter_instanceSetter() async {
    await assertErrorsInCode(
      r'''
class C {
  static int get foo => 0;
  set foo(_) {}
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 27, 3)],
    );
  }

  test_inClass_staticMethod_instanceGetter() async {
    await assertErrorsInCode(
      r'''
class C {
  static void foo() {}
  int get foo => 0;
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 24, 3)],
    );
  }

  test_inClass_staticMethod_instanceMethod() async {
    await assertErrorsInCode(
      r'''
class C {
  static void foo() {}
  void foo() {}
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 24, 3)],
    );
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_inClass_staticMethod_instanceMethodInAugmentation() async {
    await assertErrorsInCode(
      r'''
class A {
  static void foo() {}
}

augment class A {
  void foo() {}
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 24, 3)],
    );
  }

  test_inClass_staticMethod_instanceSetter() async {
    await assertErrorsInCode(
      r'''
class C {
  static void foo() {}
  set foo(_) {}
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 24, 3)],
    );
  }

  test_inClass_staticSetter_instanceGetter() async {
    await assertErrorsInCode(
      r'''
class C {
  static set foo(_) {}
  int get foo => 0;
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 23, 3)],
    );
  }

  test_inClass_staticSetter_instanceMethod() async {
    await assertErrorsInCode(
      r'''
class C {
  static set foo(_) {}
  void foo() {}
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 23, 3)],
    );
  }

  test_inClass_staticSetter_instanceSetter() async {
    await assertErrorsInCode(
      r'''
class C {
  static set foo(_) {}
  set foo(_) {}
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 23, 3)],
    );
  }

  test_inInterface_instanceGetter_staticGetter() async {
    await assertErrorsInCode(
      r'''
class A {
  int get foo => 0;
}
abstract class B implements A {
  static int get foo => 0;
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 81, 3)],
    );
  }

  test_inInterface_instanceGetter_staticMethod() async {
    await assertErrorsInCode(
      r'''
class A {
  int get foo => 0;
}
abstract class B implements A {
  static void foo() {}
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 78, 3)],
    );
  }

  test_inInterface_instanceMethod_staticMethod() async {
    await assertErrorsInCode(
      r'''
class A {
  void foo() {}
}
abstract class B implements A {
  static void foo() {}
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 74, 3)],
    );
  }

  test_inInterface_instanceMethod_staticSetter() async {
    await assertErrorsInCode(
      r'''
class A {
  void foo() {}
}
abstract class B implements A {
  static set foo(_) {}
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 73, 3)],
    );
  }

  test_inInterface_instanceSetter_staticGetter() async {
    await assertErrorsInCode(
      r'''
class A {
  set foo(_) {}
}
abstract class B implements A {
  static int get foo => 0;
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 77, 3)],
    );
  }

  test_inInterface_instanceSetter_staticMethod() async {
    await assertErrorsInCode(
      r'''
class A {
  set foo(_) {}
}
abstract class B implements A {
  static void foo() {}
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 74, 3)],
    );
  }

  test_inInterface_instanceSetter_staticSetter() async {
    await assertErrorsInCode(
      r'''
class A {
  set foo(_) {}
}
abstract class B implements A {
  static set foo(_) {}
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 73, 3)],
    );
  }

  test_inMixin_instanceGetter_staticGetter() async {
    await assertErrorsInCode(
      r'''
mixin A {
  int get foo => 0;
}
class B extends Object with A {
  static int get foo => 0;
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 81, 3)],
    );
  }

  test_inMixin_instanceGetter_staticMethod() async {
    await assertErrorsInCode(
      r'''
mixin A {
  int get foo => 0;
}
class B extends Object with A {
  static void foo() {}
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 78, 3)],
    );
  }

  test_inMixin_instanceMethod_staticMethod() async {
    await assertErrorsInCode(
      r'''
mixin A {
  void foo() {}
}
class B extends Object with A {
  static void foo() {}
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 74, 3)],
    );
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_inMixin_instanceMethod_staticMethodInAugmentation() async {
    await assertErrorsInCode(
      r'''
mixin A {
  void foo() {}
}

augment mixin A {
  static void foo() {}
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 61, 3)],
    );
  }

  test_inMixin_instanceMethod_staticSetter() async {
    await assertErrorsInCode(
      r'''
mixin A {
  void foo() {}
}
class B extends Object with A {
  static set foo(_) {}
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 73, 3)],
    );
  }

  test_inMixin_instanceSetter_staticGetter() async {
    await assertErrorsInCode(
      r'''
mixin A {
  set foo(_) {}
}
class B extends Object with A {
  static int get foo => 0;
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 77, 3)],
    );
  }

  test_inMixin_instanceSetter_staticMethod() async {
    await assertErrorsInCode(
      r'''
mixin A {
  set foo(_) {}
}
class B extends Object with A {
  static void foo() {}
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 74, 3)],
    );
  }

  test_inMixin_instanceSetter_staticSetter() async {
    await assertErrorsInCode(
      r'''
mixin A {
  set foo(_) {}
}
class B extends Object with A {
  static set foo(_) {}
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 73, 3)],
    );
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_inMixin_staticMethod_instanceMethodInAugmentation() async {
    await assertErrorsInCode(
      r'''
mixin A {
  static void foo() {}
}

augment mixin A {
  void foo() {}
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 24, 3)],
    );
  }

  test_inSuper_implicitObject_staticMethod_instanceGetter() async {
    await assertErrorsInCode(
      r'''
class A {
  static String runtimeType() => 'x';
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 26, 11)],
    );
  }

  test_inSuper_implicitObject_staticMethod_instanceMethod() async {
    await assertErrorsInCode(
      r'''
class A {
  static String toString() => 'x';
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 26, 8)],
    );
  }

  test_inSuper_instanceGetter_staticGetter() async {
    await assertErrorsInCode(
      r'''
class A {
  int get foo => 0;
}
class B extends A {
  static int get foo => 0;
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 69, 3)],
    );
  }

  test_inSuper_instanceGetter_staticMethod() async {
    await assertErrorsInCode(
      r'''
class A {
  int get foo => 0;
}
class B extends A {
  static void foo() {}
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 66, 3)],
    );
  }

  test_inSuper_instanceMethod_staticGetter() async {
    await assertErrorsInCode(
      r'''
class A {
  int get foo => 0;
}
class B extends A {
  static void foo() {}
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 66, 3)],
    );
  }

  test_inSuper_instanceMethod_staticMethod() async {
    await assertErrorsInCode(
      r'''
class A {
  void foo() {}
}
class B extends A {
  static void foo() {}
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 62, 3)],
    );
  }

  test_inSuper_instanceMethod_staticSetter() async {
    await assertErrorsInCode(
      r'''
class A {
  void foo() {}
}
class B extends A {
  static set foo(_) {}
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 61, 3)],
    );
  }

  test_inSuper_instanceSetter_staticGetter() async {
    await assertErrorsInCode(
      r'''
class A {
  set foo(_) {}
}
class B extends A {
  static int get foo => 0;
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 65, 3)],
    );
  }

  test_inSuper_instanceSetter_staticMethod() async {
    await assertErrorsInCode(
      r'''
class A {
  set foo(_) {}
}
class B extends A {
  static void foo() {}
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 62, 3)],
    );
  }

  test_inSuper_instanceSetter_staticSetter() async {
    await assertErrorsInCode(
      r'''
class A {
  set foo(_) {}
}
class B extends A {
  static set foo(_) {}
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 61, 3)],
    );
  }
}

@reflectiveTest
class ConflictingStaticAndInstanceEnumTest extends PubPackageResolutionTest {
  test_constant_hashCode() async {
    await assertErrorsInCode(
      r'''
enum E {
  a, hashCode, b
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 14, 8)],
    );
  }

  test_constant_index() async {
    await assertErrorsInCode(
      r'''
enum E {
  a, index, b
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 14, 5)],
    );
  }

  test_constant_instanceSetter() async {
    await assertErrorsInCode(
      r'''
enum E {
  foo;
  set foo(_) {}
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 11, 3)],
    );
  }

  test_constant_noSuchMethod() async {
    await assertErrorsInCode(
      r'''
enum E {
  a, noSuchMethod, b
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 14, 12)],
    );
  }

  test_constant_runtimeType() async {
    await assertErrorsInCode(
      r'''
enum E {
  a, runtimeType, b
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 14, 11)],
    );
  }

  test_constant_staticMethod() async {
    await assertErrorsInCode(
      r'''
enum E {
  foo;
  void foo() {}
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 11, 3)],
    );
  }

  test_constant_toString() async {
    await assertErrorsInCode(
      r'''
enum E {
  a, toString, b
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 14, 8)],
    );
  }

  test_field_dartCoreEnum() async {
    await assertErrorsInCode(
      r'''
enum E {
  v;
  static final int hashCode = 0;
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 33, 8)],
    );
  }

  test_field_mixin_getter() async {
    await assertErrorsInCode(
      r'''
mixin M {
  int get foo => 0;
}

enum E with M {
  v;
  static final int foo = 0;
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 73, 3)],
    );
  }

  test_field_mixin_method() async {
    await assertErrorsInCode(
      r'''
mixin M {
  void foo() {}
}

enum E with M {
  v;
  static final int foo = 0;
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 69, 3)],
    );
  }

  test_field_mixin_setter() async {
    await assertErrorsInCode(
      r'''
mixin M {
  set foo(int _) {}
}

enum E with M {
  v;
  static final int foo = 0;
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 73, 3)],
    );
  }

  test_field_this_constant() async {
    await assertErrorsInCode(
      r'''
enum E {
  foo;
  int get foo => 0;
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 11, 3)],
    );
  }

  test_field_this_getter() async {
    await assertErrorsInCode(
      r'''
enum E {
  v;
  static final int foo = 0;
  int get foo => 0;
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 33, 3)],
    );
  }

  test_field_this_method() async {
    await assertErrorsInCode(
      r'''
enum E {
  v;
  static final int foo = 0;
  void foo() {}
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 33, 3)],
    );
  }

  test_field_this_setter() async {
    await assertErrorsInCode(
      r'''
enum E {
  v;
  static final int foo = 0;
  set foo(int _) {}
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 33, 3)],
    );
  }

  test_method_dartCoreEnum() async {
    await assertErrorsInCode(
      r'''
enum E {
  v;
  static int hashCode() => 0;
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 27, 8)],
    );
  }

  test_method_mixin_getter() async {
    await assertErrorsInCode(
      r'''
mixin M {
  int get foo => 0;
}

enum E with M {
  v;
  static void foo() {}
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 68, 3)],
    );
  }

  test_method_mixin_method() async {
    await assertErrorsInCode(
      r'''
mixin M {
  void foo() {}
}

enum E with M {
  v;
  static void foo() {}
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 64, 3)],
    );
  }

  test_method_mixin_setter() async {
    await assertErrorsInCode(
      r'''
mixin M {
  set foo(int _) {}
}

enum E with M {
  v;
  static void foo() {}
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 68, 3)],
    );
  }

  test_staticGetter_instanceSetter() async {
    await assertErrorsInCode(
      r'''
enum E {
  v;
  static int get foo => 0;
  set foo(_) {}
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 31, 3)],
    );
  }

  test_staticMethod_instanceGetter() async {
    await assertErrorsInCode(
      r'''
enum E {
  v;
  static void foo() {}
  int get foo => 0;
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 28, 3)],
    );
  }

  test_staticMethod_instanceMethod() async {
    await assertErrorsInCode(
      r'''
enum E {
  v;
  static void foo() {}
  void foo() {}
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 28, 3)],
    );
  }

  test_staticMethod_instanceSetter() async {
    await assertErrorsInCode(
      r'''
enum E {
  v;
  static void foo() {}
  set foo(int _) {}
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 28, 3)],
    );
  }

  test_staticSetter_instanceGetter() async {
    await assertErrorsInCode(
      r'''
enum E {
  v;
  static set foo(_) {}
  int get foo => 0;
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 27, 3)],
    );
  }
}

@reflectiveTest
class ConflictingStaticAndInstanceExtensionTypeTest
    extends PubPackageResolutionTest {
  test_inExtensionType_staticGetter_instanceGetter() async {
    await assertErrorsInCode(
      r'''
extension type A(int it) {
  static int get foo => 0;
  int get foo => 0;
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 44, 3)],
    );
  }

  test_inExtensionType_staticGetter_instanceMethod() async {
    await assertErrorsInCode(
      r'''
extension type A(int t) {
  static int get foo => 0;
  void foo() {}
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 43, 3)],
    );
  }

  test_inExtensionType_staticGetter_instanceSetter() async {
    await assertErrorsInCode(
      r'''
extension type A(int it) {
  static int get foo => 0;
  set foo(_) {}
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 44, 3)],
    );
  }

  test_inExtensionType_staticMethod_instanceGetter() async {
    await assertErrorsInCode(
      r'''
extension type A(int it) {
  static void foo() {}
  int get foo => 0;
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 41, 3)],
    );
  }

  test_inExtensionType_staticMethod_instanceMethod() async {
    await assertErrorsInCode(
      r'''
extension type A(int it) {
  static void foo() {}
  void foo() {}
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 41, 3)],
    );
  }

  test_inExtensionType_staticMethod_instanceSetter() async {
    await assertErrorsInCode(
      r'''
extension type A(int it) {
  static void foo() {}
  set foo(_) {}
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 41, 3)],
    );
  }

  test_inExtensionType_staticSetter_instanceGetter() async {
    await assertErrorsInCode(
      r'''
extension type A(int it) {
  static set foo(_) {}
  int get foo => 0;
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 40, 3)],
    );
  }

  test_inExtensionType_staticSetter_instanceMethod() async {
    await assertErrorsInCode(
      r'''
extension type A(int it) {
  static set foo(_) {}
  void foo() {}
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 40, 3)],
    );
  }

  test_inExtensionType_staticSetter_instanceSetter() async {
    await assertErrorsInCode(
      r'''
extension type A(int it) {
  static set foo(_) {}
  set foo(_) {}
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 40, 3)],
    );
  }

  test_inInterface_instanceGetter_staticGetter() async {
    await assertErrorsInCode(
      r'''
extension type A(int it) {
  int get foo => 0;
}

extension type B(int it) implements A {
  static int get foo => 0;
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 107, 3)],
    );
  }

  test_inInterface_instanceGetter_staticMethod() async {
    await assertErrorsInCode(
      r'''
extension type A(int it) {
  int get foo => 0;
}

extension type B(int it) implements A {
  static void foo() {}
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 104, 3)],
    );
  }

  test_inInterface_instanceMethod_staticGetter() async {
    await assertErrorsInCode(
      r'''
extension type A(int it) {
  int get foo => 0;
}

extension type B(int it) implements A {
  static void foo() {}
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 104, 3)],
    );
  }

  test_inInterface_instanceMethod_staticMethod() async {
    await assertErrorsInCode(
      r'''
extension type A(int it) {
  void foo() {}
}

extension type B(int it) implements A {
  static void foo() {}
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 100, 3)],
    );
  }

  test_inInterface_instanceMethod_staticSetter() async {
    await assertErrorsInCode(
      r'''
extension type A(int it) {
  void foo() {}
}

extension type B(int it) implements A {
  static set foo(_) {}
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 99, 3)],
    );
  }

  test_inInterface_instanceSetter_staticGetter() async {
    await assertErrorsInCode(
      r'''
extension type A(int it) {
  set foo(_) {}
}

extension type B(int it) implements A {
  static int get foo => 0;
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 103, 3)],
    );
  }

  test_inInterface_instanceSetter_staticMethod() async {
    await assertErrorsInCode(
      r'''
extension type A(int it) {
  set foo(_) {}
}

extension type B(int it) implements A {
  static void foo() {}
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 100, 3)],
    );
  }

  test_inInterface_instanceSetter_staticSetter() async {
    await assertErrorsInCode(
      r'''
extension type A(int it) {
  set foo(_) {}
}

extension type B(int it) implements A {
  static set foo(_) {}
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 99, 3)],
    );
  }
}

@reflectiveTest
class ConflictingStaticAndInstanceMixinTest extends PubPackageResolutionTest {
  test_dartCoreEnum_index_field() async {
    await assertErrorsInCode(
      r'''
mixin M on Enum {
  static int index = 0;
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 31, 5)],
    );
  }

  test_dartCoreEnum_index_getter() async {
    await assertErrorsInCode(
      r'''
mixin M on Enum {
  static int get index => 0;
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 35, 5)],
    );
  }

  test_dartCoreEnum_index_method() async {
    await assertErrorsInCode(
      r'''
mixin M on Enum {
  static int index() => 0;
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 31, 5)],
    );
  }

  test_dartCoreEnum_index_setter() async {
    await assertErrorsInCode(
      r'''
mixin M on Enum {
  static set index(int _) {}
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 31, 5)],
    );
  }

  test_inConstraint_implicitObject_staticMethod_instanceGetter() async {
    await assertErrorsInCode(
      r'''
mixin M {
  static String runtimeType() => 'x';
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 26, 11)],
    );
  }

  test_inConstraint_implicitObject_staticMethod_instanceMethod() async {
    await assertErrorsInCode(
      r'''
mixin M {
  static String toString() => 'x';
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 26, 8)],
    );
  }

  test_inConstraint_instanceGetter_staticGetter() async {
    await assertErrorsInCode(
      r'''
class A {
  int get foo => 0;
}
mixin M on A {
  static int get foo => 0;
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 64, 3)],
    );
  }

  test_inConstraint_instanceGetter_staticMethod() async {
    await assertErrorsInCode(
      r'''
class A {
  int get foo => 0;
}
mixin M on A {
  static void foo() {}
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 61, 3)],
    );
  }

  test_inConstraint_instanceMethod_staticMethod() async {
    await assertErrorsInCode(
      r'''
class A {
  void foo() {}
}
mixin M on A {
  static void foo() {}
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 57, 3)],
    );
  }

  test_inConstraint_instanceMethod_staticSetter() async {
    await assertErrorsInCode(
      r'''
class A {
  void foo() {}
}
mixin M on A {
  static set foo(_) {}
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 56, 3)],
    );
  }

  test_inConstraint_instanceSetter_staticGetter() async {
    await assertErrorsInCode(
      r'''
class A {
  set foo(_) {}
}
mixin M on A {
  static int get foo => 0;
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 60, 3)],
    );
  }

  test_inConstraint_instanceSetter_staticMethod() async {
    await assertErrorsInCode(
      r'''
class A {
  set foo(_) {}
}
mixin M on A {
  static void foo() {}
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 57, 3)],
    );
  }

  test_inConstraint_instanceSetter_staticSetter() async {
    await assertErrorsInCode(
      r'''
class A {
  set foo(_) {}
}
mixin M on A {
  static set foo(_) {}
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 56, 3)],
    );
  }

  test_inInterface_instanceGetter_staticGetter() async {
    await assertErrorsInCode(
      r'''
class A {
  int get foo => 0;
}
mixin M implements A {
  static int get foo => 0;
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 72, 3)],
    );
  }

  test_inInterface_instanceGetter_staticMethod() async {
    await assertErrorsInCode(
      r'''
class A {
  int get foo => 0;
}
mixin M implements A {
  static void foo() {}
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 69, 3)],
    );
  }

  test_inInterface_instanceMethod_staticGetter() async {
    await assertErrorsInCode(
      r'''
class A {
  int get foo => 0;
}
mixin M implements A {
  static void foo() {}
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 69, 3)],
    );
  }

  test_inInterface_instanceMethod_staticMethod() async {
    await assertErrorsInCode(
      r'''
class A {
  void foo() {}
}
mixin M implements A {
  static void foo() {}
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 65, 3)],
    );
  }

  test_inInterface_instanceMethod_staticSetter() async {
    await assertErrorsInCode(
      r'''
class A {
  void foo() {}
}
mixin M implements A {
  static set foo(_) {}
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 64, 3)],
    );
  }

  test_inInterface_instanceSetter_staticGetter() async {
    await assertErrorsInCode(
      r'''
class A {
  set foo(_) {}
}
mixin M implements A {
  static int get foo => 0;
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 68, 3)],
    );
  }

  test_inInterface_instanceSetter_staticMethod() async {
    await assertErrorsInCode(
      r'''
class A {
  set foo(_) {}
}
mixin M implements A {
  static void foo() {}
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 65, 3)],
    );
  }

  test_inInterface_instanceSetter_staticSetter() async {
    await assertErrorsInCode(
      r'''
class A {
  set foo(_) {}
}
mixin M implements A {
  static set foo(_) {}
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 64, 3)],
    );
  }

  test_inMixin_staticGetter_instanceGetter() async {
    await assertErrorsInCode(
      r'''
mixin M {
  static int get foo => 0;
  int get foo => 0;
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 27, 3)],
    );
  }

  test_inMixin_staticGetter_instanceMethod() async {
    await assertErrorsInCode(
      r'''
mixin M {
  static int get foo => 0;
  void foo() {}
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 27, 3)],
    );
  }

  test_inMixin_staticGetter_instanceSetter() async {
    await assertErrorsInCode(
      r'''
mixin M {
  static int get foo => 0;
  set foo(_) {}
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 27, 3)],
    );
  }

  test_inMixin_staticMethod_instanceGetter() async {
    await assertErrorsInCode(
      r'''
mixin M {
  static void foo() {}
  int get foo => 0;
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 24, 3)],
    );
  }

  test_inMixin_staticMethod_instanceMethod() async {
    await assertErrorsInCode(
      r'''
mixin M {
  static void foo() {}
  void foo() {}
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 24, 3)],
    );
  }

  test_inMixin_staticMethod_instanceSetter() async {
    await assertErrorsInCode(
      r'''
mixin M {
  static void foo() {}
  set foo(_) {}
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 24, 3)],
    );
  }

  test_inMixin_staticSetter_instanceGetter() async {
    await assertErrorsInCode(
      r'''
mixin M {
  static set foo(_) {}
  int get foo => 0;
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 23, 3)],
    );
  }

  test_inMixin_staticSetter_instanceMethod() async {
    await assertErrorsInCode(
      r'''
mixin M {
  static set foo(_) {}
  void foo() {}
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 23, 3)],
    );
  }

  test_inMixin_staticSetter_instanceSetter() async {
    await assertErrorsInCode(
      r'''
mixin M {
  static set foo(_) {}
  set foo(_) {}
}
''',
      [error(CompileTimeErrorCode.conflictingStaticAndInstance, 23, 3)],
    );
  }
}
