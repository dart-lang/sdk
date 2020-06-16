// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConflictingStaticAndInstanceClassTest);
    defineReflectiveTests(ConflictingStaticAndInstanceEnumTest);
    defineReflectiveTests(ConflictingStaticAndInstanceMixinTest);
  });
}

@reflectiveTest
class ConflictingStaticAndInstanceClassTest extends DriverResolutionTest {
  test_inClass_getter_getter() async {
    await assertErrorsInCode(r'''
class C {
  static int get foo => 0;
  int get foo => 0;
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 27, 3),
    ]);
  }

  test_inClass_getter_method() async {
    await assertErrorsInCode(r'''
class C {
  static int get foo => 0;
  void foo() {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 27, 3),
    ]);
  }

  test_inClass_getter_setter() async {
    await assertErrorsInCode(r'''
class C {
  static int get foo => 0;
  set foo(_) {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 27, 3),
    ]);
  }

  test_inClass_method_getter() async {
    await assertErrorsInCode(r'''
class C {
  static void foo() {}
  int get foo => 0;
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 24, 3),
    ]);
  }

  test_inClass_method_method() async {
    await assertErrorsInCode(r'''
class C {
  static void foo() {}
  void foo() {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 24, 3),
    ]);
  }

  test_inClass_method_setter() async {
    await assertErrorsInCode(r'''
class C {
  static void foo() {}
  set foo(_) {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 24, 3),
    ]);
  }

  test_inClass_setter_getter() async {
    await assertErrorsInCode(r'''
class C {
  static set foo(_) {}
  int get foo => 0;
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 23, 3),
    ]);
  }

  test_inClass_setter_method() async {
    await assertErrorsInCode(r'''
class C {
  static set foo(_) {}
  void foo() {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 23, 3),
    ]);
  }

  test_inClass_setter_setter() async {
    await assertErrorsInCode(r'''
class C {
  static set foo(_) {}
  set foo(_) {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 23, 3),
    ]);
  }

  test_inInterface_getter_getter() async {
    await assertErrorsInCode(r'''
class A {
  int get foo => 0;
}
abstract class B implements A {
  static int get foo => 0;
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 81, 3),
    ]);
  }

  test_inInterface_getter_method() async {
    await assertErrorsInCode(r'''
class A {
  int get foo => 0;
}
abstract class B implements A {
  static void foo() {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 78, 3),
    ]);
  }

  test_inInterface_getter_setter() async {
    await assertErrorsInCode(r'''
class A {
  set foo(_) {}
}
abstract class B implements A {
  static int get foo => 0;
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 77, 3),
    ]);
  }

  test_inInterface_method_getter() async {
    await assertErrorsInCode(r'''
class A {
  int get foo => 0;
}
abstract class B implements A {
  static void foo() {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 78, 3),
    ]);
  }

  test_inInterface_method_method() async {
    await assertErrorsInCode(r'''
class A {
  void foo() {}
}
abstract class B implements A {
  static void foo() {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 74, 3),
    ]);
  }

  test_inInterface_method_setter() async {
    await assertErrorsInCode(r'''
class A {
  set foo(_) {}
}
abstract class B implements A {
  static void foo() {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 74, 3),
    ]);
  }

  test_inInterface_setter_method() async {
    await assertErrorsInCode(r'''
class A {
  void foo() {}
}
abstract class B implements A {
  static set foo(_) {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 73, 3),
    ]);
  }

  test_inInterface_setter_setter() async {
    await assertErrorsInCode(r'''
class A {
  set foo(_) {}
}
abstract class B implements A {
  static set foo(_) {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 73, 3),
    ]);
  }

  test_inMixin_getter_getter() async {
    await assertErrorsInCode(r'''
class A {
  int get foo => 0;
}
class B extends Object with A {
  static int get foo => 0;
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 81, 3),
    ]);
  }

  test_inMixin_getter_method() async {
    await assertErrorsInCode(r'''
class A {
  int get foo => 0;
}
class B extends Object with A {
  static void foo() {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 78, 3),
    ]);
  }

  test_inMixin_getter_setter() async {
    await assertErrorsInCode(r'''
class A {
  set foo(_) {}
}
class B extends Object with A {
  static int get foo => 0;
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 77, 3),
    ]);
  }

  test_inMixin_method_getter() async {
    await assertErrorsInCode(r'''
class A {
  int get foo => 0;
}
class B extends Object with A {
  static void foo() {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 78, 3),
    ]);
  }

  test_inMixin_method_method() async {
    await assertErrorsInCode(r'''
class A {
  void foo() {}
}
class B extends Object with A {
  static void foo() {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 74, 3),
    ]);
  }

  test_inMixin_method_setter() async {
    await assertErrorsInCode(r'''
class A {
  set foo(_) {}
}
class B extends Object with A {
  static void foo() {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 74, 3),
    ]);
  }

  test_inMixin_setter_method() async {
    await assertErrorsInCode(r'''
class A {
  void foo() {}
}
class B extends Object with A {
  static set foo(_) {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 73, 3),
    ]);
  }

  test_inMixin_setter_setter() async {
    await assertErrorsInCode(r'''
class A {
  set foo(_) {}
}
class B extends Object with A {
  static set foo(_) {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 73, 3),
    ]);
  }

  test_inSuper_getter_getter() async {
    await assertErrorsInCode(r'''
class A {
  int get foo => 0;
}
class B extends A {
  static int get foo => 0;
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 69, 3),
    ]);
  }

  test_inSuper_getter_method() async {
    await assertErrorsInCode(r'''
class A {
  int get foo => 0;
}
class B extends A {
  static void foo() {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 66, 3),
    ]);
  }

  test_inSuper_getter_setter() async {
    await assertErrorsInCode(r'''
class A {
  set foo(_) {}
}
class B extends A {
  static int get foo => 0;
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 65, 3),
    ]);
  }

  test_inSuper_implicitObject_method_getter() async {
    await assertErrorsInCode(r'''
class A {
  static String runtimeType() => 'x';
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 26, 11),
    ]);
  }

  test_inSuper_implicitObject_method_method() async {
    await assertErrorsInCode(r'''
class A {
  static String toString() => 'x';
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 26, 8),
    ]);
  }

  test_inSuper_method_getter() async {
    await assertErrorsInCode(r'''
class A {
  int get foo => 0;
}
class B extends A {
  static void foo() {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 66, 3),
    ]);
  }

  test_inSuper_method_method() async {
    await assertErrorsInCode(r'''
class A {
  void foo() {}
}
class B extends A {
  static void foo() {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 62, 3),
    ]);
  }

  test_inSuper_method_setter() async {
    await assertErrorsInCode(r'''
class A {
  set foo(_) {}
}
class B extends A {
  static void foo() {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 62, 3),
    ]);
  }

  test_inSuper_setter_method() async {
    await assertErrorsInCode(r'''
class A {
  void foo() {}
}
class B extends A {
  static set foo(_) {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 61, 3),
    ]);
  }

  test_inSuper_setter_setter() async {
    await assertErrorsInCode(r'''
class A {
  set foo(_) {}
}
class B extends A {
  static set foo(_) {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 61, 3),
    ]);
  }
}

@reflectiveTest
class ConflictingStaticAndInstanceEnumTest extends DriverResolutionTest {
  test_hashCode() async {
    await assertErrorsInCode(r'''
enum E {
  a, hashCode, b
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 14, 8),
    ]);
  }

  test_index() async {
    await assertErrorsInCode(r'''
enum E {
  a, index, b
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 14, 5),
    ]);
  }

  test_noSuchMethod() async {
    await assertErrorsInCode(r'''
enum E {
  a, noSuchMethod, b
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 14, 12),
    ]);
  }

  test_runtimeType() async {
    await assertErrorsInCode(r'''
enum E {
  a, runtimeType, b
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 14, 11),
    ]);
  }

  test_toString() async {
    await assertErrorsInCode(r'''
enum E {
  a, toString, b
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 14, 8),
    ]);
  }
}

@reflectiveTest
class ConflictingStaticAndInstanceMixinTest extends DriverResolutionTest {
  test_inConstraint_getter_getter() async {
    await assertErrorsInCode(r'''
class A {
  int get foo => 0;
}
mixin M on A {
  static int get foo => 0;
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 64, 3),
    ]);
  }

  test_inConstraint_getter_method() async {
    await assertErrorsInCode(r'''
class A {
  int get foo => 0;
}
mixin M on A {
  static void foo() {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 61, 3),
    ]);
  }

  test_inConstraint_getter_setter() async {
    await assertErrorsInCode(r'''
class A {
  set foo(_) {}
}
mixin M on A {
  static int get foo => 0;
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 60, 3),
    ]);
  }

  test_inConstraint_implicitObject_method_getter() async {
    await assertErrorsInCode(r'''
mixin M {
  static String runtimeType() => 'x';
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 26, 11),
    ]);
  }

  test_inConstraint_implicitObject_method_method() async {
    await assertErrorsInCode(r'''
mixin M {
  static String toString() => 'x';
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 26, 8),
    ]);
  }

  test_inConstraint_method_getter() async {
    await assertErrorsInCode(r'''
class A {
  int get foo => 0;
}
mixin M on A {
  static void foo() {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 61, 3),
    ]);
  }

  test_inConstraint_method_method() async {
    await assertErrorsInCode(r'''
class A {
  void foo() {}
}
mixin M on A {
  static void foo() {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 57, 3),
    ]);
  }

  test_inConstraint_method_setter() async {
    await assertErrorsInCode(r'''
class A {
  set foo(_) {}
}
mixin M on A {
  static void foo() {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 57, 3),
    ]);
  }

  test_inConstraint_setter_method() async {
    await assertErrorsInCode(r'''
class A {
  void foo() {}
}
mixin M on A {
  static set foo(_) {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 56, 3),
    ]);
  }

  test_inConstraint_setter_setter() async {
    await assertErrorsInCode(r'''
class A {
  set foo(_) {}
}
mixin M on A {
  static set foo(_) {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 56, 3),
    ]);
  }

  test_inInterface_getter_getter() async {
    await assertErrorsInCode(r'''
class A {
  int get foo => 0;
}
mixin M implements A {
  static int get foo => 0;
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 72, 3),
    ]);
  }

  test_inInterface_getter_method() async {
    await assertErrorsInCode(r'''
class A {
  int get foo => 0;
}
mixin M implements A {
  static void foo() {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 69, 3),
    ]);
  }

  test_inInterface_getter_setter() async {
    await assertErrorsInCode(r'''
class A {
  set foo(_) {}
}
mixin M implements A {
  static int get foo => 0;
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 68, 3),
    ]);
  }

  test_inInterface_method_getter() async {
    await assertErrorsInCode(r'''
class A {
  int get foo => 0;
}
mixin M implements A {
  static void foo() {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 69, 3),
    ]);
  }

  test_inInterface_method_method() async {
    await assertErrorsInCode(r'''
class A {
  void foo() {}
}
mixin M implements A {
  static void foo() {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 65, 3),
    ]);
  }

  test_inInterface_method_setter() async {
    await assertErrorsInCode(r'''
class A {
  set foo(_) {}
}
mixin M implements A {
  static void foo() {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 65, 3),
    ]);
  }

  test_inInterface_setter_method() async {
    await assertErrorsInCode(r'''
class A {
  void foo() {}
}
mixin M implements A {
  static set foo(_) {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 64, 3),
    ]);
  }

  test_inInterface_setter_setter() async {
    await assertErrorsInCode(r'''
class A {
  set foo(_) {}
}
mixin M implements A {
  static set foo(_) {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 64, 3),
    ]);
  }

  test_inMixin_getter_getter() async {
    await assertErrorsInCode(r'''
mixin M {
  static int get foo => 0;
  int get foo => 0;
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 27, 3),
    ]);
  }

  test_inMixin_getter_method() async {
    await assertErrorsInCode(r'''
mixin M {
  static int get foo => 0;
  void foo() {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 27, 3),
    ]);
  }

  test_inMixin_getter_setter() async {
    await assertErrorsInCode(r'''
mixin M {
  static int get foo => 0;
  set foo(_) {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 27, 3),
    ]);
  }

  test_inMixin_method_getter() async {
    await assertErrorsInCode(r'''
mixin M {
  static void foo() {}
  int get foo => 0;
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 24, 3),
    ]);
  }

  test_inMixin_method_method() async {
    await assertErrorsInCode(r'''
mixin M {
  static void foo() {}
  void foo() {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 24, 3),
    ]);
  }

  test_inMixin_method_setter() async {
    await assertErrorsInCode(r'''
mixin M {
  static void foo() {}
  set foo(_) {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 24, 3),
    ]);
  }

  test_inMixin_setter_getter() async {
    await assertErrorsInCode(r'''
mixin M {
  static set foo(_) {}
  int get foo => 0;
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 23, 3),
    ]);
  }

  test_inMixin_setter_method() async {
    await assertErrorsInCode(r'''
mixin M {
  static set foo(_) {}
  void foo() {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 23, 3),
    ]);
  }

  test_inMixin_setter_setter() async {
    await assertErrorsInCode(r'''
mixin M {
  static set foo(_) {}
  set foo(_) {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE, 23, 3),
    ]);
  }
}
