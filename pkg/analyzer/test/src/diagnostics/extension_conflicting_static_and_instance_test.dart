// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtensionConflictingStaticAndInstanceTest);
  });
}

@reflectiveTest
class ExtensionConflictingStaticAndInstanceTest
    extends PubPackageResolutionTest {
  CompileTimeErrorCode get _errorCode =>
      CompileTimeErrorCode.extensionConflictingStaticAndInstance;

  test_extendedType_staticField() async {
    await assertNoErrorsInCode('''
class A {
  static int foo = 0;
  int bar = 0;
}

extension E on A {
  int get foo => 0;
  static int get bar => 0;
}
''');
  }

  test_extendedType_staticGetter() async {
    await assertNoErrorsInCode('''
class A {
  static int get foo => 0;
  int get bar => 0;
}

extension E on A {
  int get foo => 0;
  static int get bar => 0;
}
''');
  }

  test_extendedType_staticMethod() async {
    await assertNoErrorsInCode('''
class A {
  static void foo() {}
  void bar() {}
}

extension E on A {
  void foo() {}
  static void bar() {}
}
''');
  }

  test_extendedType_staticSetter() async {
    await assertNoErrorsInCode('''
class A {
  static set foo(_) {}
  set bar(_) {}
}

extension E on A {
  set foo(_) {}
  static set bar(_) {}
}
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_instanceMethod_staticMethodInAugmentation() async {
    await assertErrorsInCode(
      '''
extension A on int {
  void foo() {}
}

augment extension A {
  static void foo() {}
}
''',
      [error(_errorCode, 76, 3)],
    );
  }

  test_staticField_instanceGetter() async {
    await assertErrorsInCode(
      '''
extension E on String {
  static int foo = 0;
  int get foo => 0;
}
''',
      [error(_errorCode, 37, 3)],
    );
  }

  test_staticField_instanceGetter_unnamed() async {
    await assertErrorsInCode(
      '''
extension E on String {
  static int foo = 0;
  int get foo => 0;
}
''',
      [error(_errorCode, 37, 3)],
    );
  }

  test_staticField_instanceMethod() async {
    await assertErrorsInCode(
      '''
extension E on String {
  static int foo = 0;
  void foo() {}
}
''',
      [error(_errorCode, 37, 3)],
    );
  }

  test_staticField_instanceSetter() async {
    await assertErrorsInCode(
      '''
extension E on String {
  static int foo = 0;
  set foo(_) {}
}
''',
      [error(_errorCode, 37, 3)],
    );
  }

  test_staticGetter_instanceGetter() async {
    await assertErrorsInCode(
      '''
extension E on String {
  static int get foo => 0;
  int get foo => 0;
}
''',
      [error(_errorCode, 41, 3)],
    );
  }

  test_staticGetter_instanceGetter_unnamed() async {
    await assertErrorsInCode(
      '''
extension E on String {
  static int get foo => 0;
  int get foo => 0;
}
''',
      [error(_errorCode, 41, 3)],
    );
  }

  test_staticGetter_instanceMethod() async {
    await assertErrorsInCode(
      '''
extension E on String {
  static int get foo => 0;
  void foo() {}
}
''',
      [error(_errorCode, 41, 3)],
    );
  }

  test_staticGetter_instanceSetter() async {
    await assertErrorsInCode(
      '''
extension E on String {
  static int get foo => 0;
  set foo(_) {}
}
''',
      [error(_errorCode, 41, 3)],
    );
  }

  test_staticMethod_instanceGetter() async {
    await assertErrorsInCode(
      '''
extension E on String {
  static void foo() {}
  int get foo => 0;
}
''',
      [error(_errorCode, 38, 3)],
    );
  }

  test_staticMethod_instanceMethod() async {
    await assertErrorsInCode(
      '''
extension E on String {
  static void foo() {}
  void foo() {}
}
''',
      [error(_errorCode, 38, 3)],
    );
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_staticMethod_instanceMethodInAugmentation() async {
    await assertErrorsInCode(
      '''
extension A on int {
  static void foo() {}
}

augment extension A {
  void foo() {}
}
''',
      [error(_errorCode, 35, 3)],
    );
  }

  test_staticMethod_instanceSetter() async {
    await assertErrorsInCode(
      '''
extension E on String {
  static void foo() {}
  set foo(_) {}
}
''',
      [error(_errorCode, 38, 3)],
    );
  }

  test_staticSetter_instanceGetter() async {
    await assertErrorsInCode(
      '''
extension E on String {
  static set foo(_) {}
  int get foo => 0;
}
''',
      [error(_errorCode, 37, 3)],
    );
  }

  test_staticSetter_instanceMethod() async {
    await assertErrorsInCode(
      '''
extension E on String {
  static set foo(_) {}
  void foo() {}
}
''',
      [error(_errorCode, 37, 3)],
    );
  }

  test_staticSetter_instanceSetter() async {
    await assertErrorsInCode(
      '''
extension E on String {
  static set foo(_) {}
  set foo(_) {}
}
''',
      [error(_errorCode, 37, 3)],
    );
  }
}
