// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/test_support.dart';
import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DuplicateDefinitionTest);
    defineReflectiveTests(DuplicateDefinitionClassTest);
    defineReflectiveTests(DuplicateDefinitionEnumTest);
    defineReflectiveTests(DuplicateDefinitionExtensionTest);
    defineReflectiveTests(DuplicateDefinitionExtensionTypeTest);
    defineReflectiveTests(DuplicateDefinitionMixinTest);
    defineReflectiveTests(DuplicateDefinitionUnitTest);
  });
}

@reflectiveTest
class DuplicateDefinitionClassTest extends PubPackageResolutionTest {
  test_instance_field_field() async {
    await assertErrorsInCode(r'''
class C {
  int foo = 0;
  int foo = 0;
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 31, 3,
          contextMessages: [message(testFile, 16, 3)]),
    ]);
  }

  test_instance_field_field_augment() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';

augment class A {
  augment int foo = 42;
}
''');

    newFile(testFile.path, r'''
import augment 'a.dart';

class A {
  int foo = 0;
}
''');

    await resolveTestFile();
    assertNoErrorsInResult();

    await resolveFile2(a);
    assertNoErrorsInResult();
  }

  test_instance_field_field_field() async {
    await assertErrorsInCode(r'''
class C {
  int foo = 0;
  int foo = 0;
  int foo = 0;
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 31, 3,
          contextMessages: [message(testFile, 16, 3)]),
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 46, 3,
          contextMessages: [message(testFile, 16, 3)]),
    ]);
  }

  test_instance_field_field_inAugmentation() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';

augment class A {
  int foo = 42;
}
''');

    newFile(testFile.path, r'''
import augment 'a.dart';

class A {
  int foo = 0;
}
''');

    await resolveTestFile();
    assertNoErrorsInResult();

    await resolveFile2(a);
    assertErrorsInResult([
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 54, 3,
          contextMessages: [message(testFile, 42, 3)]),
    ]);
  }

  test_instance_field_getter() async {
    await assertErrorsInCode(r'''
class C {
  int foo = 0;
  int get foo => 0;
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 35, 3,
          contextMessages: [message(testFile, 16, 3)]),
    ]);
  }

  test_instance_field_method() async {
    await assertErrorsInCode(r'''
class C {
  int foo = 0;
  void foo() {}
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 32, 3,
          contextMessages: [message(testFile, 16, 3)]),
    ]);
  }

  test_instance_fieldFinal_getter() async {
    await assertErrorsInCode(r'''
class C {
  final int foo = 0;
  int get foo => 0;
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 41, 3,
          contextMessages: [message(testFile, 22, 3)]),
    ]);
  }

  test_instance_fieldFinal_setter() async {
    await assertNoErrorsInCode(r'''
class C {
  final int foo = 0;
  set foo(int x) {}
}
''');
  }

  test_instance_getter_getter() async {
    await assertErrorsInCode(r'''
class C {
  int get foo => 0;
  int get foo => 0;
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 40, 3,
          contextMessages: [message(testFile, 20, 3)]),
    ]);
  }

  test_instance_getter_method() async {
    await assertErrorsInCode(r'''
class C {
  int get foo => 0;
  void foo() {}
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 37, 3,
          contextMessages: [message(testFile, 20, 3)]),
    ]);
  }

  test_instance_getter_setter() async {
    await assertNoErrorsInCode(r'''
class C {
  int get foo => 0;
  set foo(_) {}
}
''');
  }

  test_instance_method_getter() async {
    await assertErrorsInCode(r'''
class C {
  void foo() {}
  int get foo => 0;
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 36, 3,
          contextMessages: [message(testFile, 17, 3)]),
    ]);
  }

  test_instance_method_method() async {
    await assertErrorsInCode(r'''
class C {
  void foo() {}
  void foo() {}
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 33, 3,
          contextMessages: [message(testFile, 17, 3)]),
    ]);
  }

  test_instance_method_method_augment() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';

augment class A {
  augment void foo() {}
}
''');

    newFile(testFile.path, r'''
import augment 'a.dart';

class A {
  void foo() {}
}
''');

    await resolveTestFile();
    assertNoErrorsInResult();

    await resolveFile2(a);
    assertNoErrorsInResult();
  }

  test_instance_method_method_inAugmentation() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';

augment class A {
  void foo() {}
}
''');

    newFile(testFile.path, r'''
import augment 'a.dart';

class A {
  void foo() {}
}
''');

    await resolveTestFile();
    assertNoErrorsInResult();

    await resolveFile2(a);
    assertErrorsInResult([
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 55, 3,
          contextMessages: [message(testFile, 43, 3)]),
    ]);
  }

  test_instance_method_setter() async {
    await assertErrorsInCode(r'''
class C {
  void foo() {}
  set foo(_) {}
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 32, 3,
          contextMessages: [message(testFile, 17, 3)]),
    ]);
  }

  test_instance_setter_getter() async {
    await assertNoErrorsInCode(r'''
class C {
  set foo(_) {}
  int get foo => 0;
}
''');
  }

  test_instance_setter_method() async {
    await assertErrorsInCode(r'''
class C {
  set foo(_) {}
  void foo() {}
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 33, 3,
          contextMessages: [message(testFile, 16, 3)]),
    ]);
  }

  test_instance_setter_setter() async {
    await assertErrorsInCode(r'''
class C {
  void set foo(_) {}
  void set foo(_) {}
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 42, 3,
          contextMessages: [message(testFile, 21, 3)]),
    ]);
  }

  test_static_field_field() async {
    await assertErrorsInCode(r'''
class C {
  static int foo = 0;
  static int foo = 0;
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 45, 3,
          contextMessages: [message(testFile, 23, 3)]),
    ]);
  }

  test_static_field_getter() async {
    await assertErrorsInCode(r'''
class C {
  static int foo = 0;
  static int get foo => 0;
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 49, 3,
          contextMessages: [message(testFile, 23, 3)]),
    ]);
  }

  test_static_field_method() async {
    await assertErrorsInCode(r'''
class C {
  static int foo = 0;
  static void foo() {}
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 46, 3,
          contextMessages: [message(testFile, 23, 3)]),
    ]);
  }

  test_static_fieldFinal_getter() async {
    await assertErrorsInCode(r'''
class C {
  static final int foo = 0;
  static int get foo => 0;
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 55, 3,
          contextMessages: [message(testFile, 29, 3)]),
    ]);
  }

  test_static_fieldFinal_setter() async {
    await assertNoErrorsInCode(r'''
class C {
  static final int foo = 0;
  static set foo(int x) {}
}
''');
  }

  test_static_getter_getter() async {
    await assertErrorsInCode(r'''
class C {
  static int get foo => 0;
  static int get foo => 0;
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 54, 3,
          contextMessages: [message(testFile, 27, 3)]),
    ]);
  }

  test_static_getter_method() async {
    await assertErrorsInCode(r'''
class C {
  static int get foo => 0;
  static void foo() {}
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 51, 3,
          contextMessages: [message(testFile, 27, 3)]),
    ]);
  }

  test_static_getter_setter() async {
    await assertNoErrorsInCode(r'''
class C {
  static int get foo => 0;
  static set foo(_) {}
}
''');
  }

  test_static_method_getter() async {
    await assertErrorsInCode(r'''
class C {
  static void foo() {}
  static int get foo => 0;
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 50, 3,
          contextMessages: [message(testFile, 24, 3)]),
    ]);
  }

  test_static_method_method() async {
    await assertErrorsInCode(r'''
class C {
  static void foo() {}
  static void foo() {}
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 47, 3,
          contextMessages: [message(testFile, 24, 3)]),
    ]);
  }

  test_static_method_setter() async {
    await assertErrorsInCode(r'''
class C {
  static void foo() {}
  static set foo(_) {}
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 46, 3,
          contextMessages: [message(testFile, 24, 3)]),
    ]);
  }

  test_static_setter_getter() async {
    await assertNoErrorsInCode(r'''
class C {
  static set foo(_) {}
  static int get foo => 0;
}
''');
  }

  test_static_setter_method() async {
    await assertErrorsInCode(r'''
class C {
  static set foo(_) {}
  static void foo() {}
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 47, 3,
          contextMessages: [message(testFile, 23, 3)]),
    ]);
  }

  test_static_setter_setter() async {
    await assertErrorsInCode(r'''
class C {
  static void set foo(_) {}
  static void set foo(_) {}
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 56, 3,
          contextMessages: [message(testFile, 28, 3)]),
    ]);
  }

  test_topLevel_syntheticParameters() async {
    await assertErrorsInCode(r'''
f(,[]) {}
''', [
      error(ParserErrorCode.MISSING_IDENTIFIER, 2, 1),
      error(ParserErrorCode.MISSING_IDENTIFIER, 4, 1),
    ]);
  }
}

@reflectiveTest
class DuplicateDefinitionEnumTest extends PubPackageResolutionTest {
  test_constant() async {
    await assertErrorsInCode(r'''
enum E {
  foo, foo
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 16, 3,
          contextMessages: [message(testFile, 11, 3)]),
    ]);
  }

  test_instance_field_field() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  final int foo = 0;
  final int foo = 0;
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 47, 3,
          contextMessages: [message(testFile, 26, 3)]),
    ]);
  }

  test_instance_field_getter() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  final int foo = 0;
  int get foo => 0;
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 45, 3,
          contextMessages: [message(testFile, 26, 3)]),
    ]);
  }

  test_instance_field_method() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  final int foo = 0;
  void foo() {}
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 42, 3,
          contextMessages: [message(testFile, 26, 3)]),
    ]);
  }

  test_instance_fieldFinal_getter() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  final int foo = 0;
  int get foo => 0;
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 45, 3,
          contextMessages: [message(testFile, 26, 3)]),
    ]);
  }

  test_instance_fieldFinal_setter() async {
    await assertNoErrorsInCode(r'''
enum E {
  v;
  final int foo = 0;
  set foo(int x) {}
}
''');
  }

  test_instance_getter_getter() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  int get foo => 0;
  int get foo => 0;
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 44, 3,
          contextMessages: [message(testFile, 24, 3)]),
    ]);
  }

  test_instance_getter_method() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  int get foo => 0;
  void foo() {}
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 41, 3,
          contextMessages: [message(testFile, 24, 3)]),
    ]);
  }

  test_instance_getter_setter() async {
    await assertNoErrorsInCode(r'''
enum E {
  v;
  int get foo => 0;
  set foo(_) {}
}
''');
  }

  test_instance_method_getter() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  void foo() {}
  int get foo => 0;
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 40, 3,
          contextMessages: [message(testFile, 21, 3)]),
    ]);
  }

  test_instance_method_method() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  void foo() {}
  void foo() {}
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 37, 3,
          contextMessages: [message(testFile, 21, 3)]),
    ]);
  }

  test_instance_method_setter() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  void foo() {}
  set foo(_) {}
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 36, 3,
          contextMessages: [message(testFile, 21, 3)]),
    ]);
  }

  test_instance_setter_getter() async {
    await assertNoErrorsInCode(r'''
enum E {
  v;
  set foo(_) {}
  int get foo => 0;
}
''');
  }

  test_instance_setter_method() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  set foo(_) {}
  void foo() {}
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 37, 3,
          contextMessages: [message(testFile, 20, 3)]),
    ]);
  }

  test_instance_setter_setter() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  void set foo(_) {}
  void set foo(_) {}
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 46, 3,
          contextMessages: [message(testFile, 25, 3)]),
    ]);
  }

  test_static_constant_field() async {
    await assertErrorsInCode(r'''
enum E {
  foo;
  static int foo = 0;
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 29, 3,
          contextMessages: [message(testFile, 11, 3)]),
    ]);
  }

  test_static_constant_getter() async {
    await assertErrorsInCode(r'''
enum E {
  foo;
  static int get foo => 0;
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 33, 3,
          contextMessages: [message(testFile, 11, 3)]),
    ]);
  }

  test_static_constant_method() async {
    await assertErrorsInCode(r'''
enum E {
  foo;
  static void foo() {}
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 30, 3,
          contextMessages: [message(testFile, 11, 3)]),
    ]);
  }

  test_static_constant_setter() async {
    await assertNoErrorsInCode(r'''
enum E {
  foo;
  static set foo(_) {}
}
''');
  }

  test_static_field_field() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  static int foo = 0;
  static int foo = 0;
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 49, 3,
          contextMessages: [message(testFile, 27, 3)]),
    ]);
  }

  test_static_field_getter() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  static int foo = 0;
  static int get foo => 0;
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 53, 3,
          contextMessages: [message(testFile, 27, 3)]),
    ]);
  }

  test_static_field_method() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  static int foo = 0;
  static void foo() {}
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 50, 3,
          contextMessages: [message(testFile, 27, 3)]),
    ]);
  }

  test_static_fieldFinal_getter() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  static final int foo = 0;
  static int get foo => 0;
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 59, 3,
          contextMessages: [message(testFile, 33, 3)]),
    ]);
  }

  test_static_fieldFinal_setter() async {
    await assertNoErrorsInCode(r'''
enum E {
  v;
  static final int foo = 0;
  static set foo(int x) {}
}
''');
  }

  test_static_getter_getter() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  static int get foo => 0;
  static int get foo => 0;
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 58, 3,
          contextMessages: [message(testFile, 31, 3)]),
    ]);
  }

  test_static_getter_method() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  static int get foo => 0;
  static void foo() {}
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 55, 3,
          contextMessages: [message(testFile, 31, 3)]),
    ]);
  }

  test_static_getter_setter() async {
    await assertNoErrorsInCode(r'''
enum E {
  v;
  static int get foo => 0;
  static set foo(_) {}
}
''');
  }

  test_static_method_getter() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  static void foo() {}
  static int get foo => 0;
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 54, 3,
          contextMessages: [message(testFile, 28, 3)]),
    ]);
  }

  test_static_method_method() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  static void foo() {}
  static void foo() {}
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 51, 3,
          contextMessages: [message(testFile, 28, 3)]),
    ]);
  }

  test_static_method_setter() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  static void foo() {}
  static set foo(_) {}
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 50, 3,
          contextMessages: [message(testFile, 28, 3)]),
    ]);
  }

  test_static_setter_getter() async {
    await assertNoErrorsInCode(r'''
enum E {
  v;
  static set foo(_) {}
  static int get foo => 0;
}
''');
  }

  test_static_setter_method() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  static set foo(_) {}
  static void foo() {}
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 51, 3,
          contextMessages: [message(testFile, 27, 3)]),
    ]);
  }

  test_static_setter_setter() async {
    await assertErrorsInCode(r'''
enum E {
  v;
  static void set foo(_) {}
  static void set foo(_) {}
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 60, 3,
          contextMessages: [message(testFile, 32, 3)]),
    ]);
  }
}

@reflectiveTest
class DuplicateDefinitionExtensionTest extends PubPackageResolutionTest {
  test_extendedType_instance() async {
    await assertNoErrorsInCode('''
class A {
  int get foo => 0;
  set foo(_) {}
  void bar() {}
}

extension E on A {
  int get foo => 0;
  set foo(_) {}
  void bar() {}
}
''');
  }

  test_extendedType_static() async {
    await assertNoErrorsInCode('''
class A {
  static int get foo => 0;
  static set foo(_) {}
  static void bar() {}
}

extension E on A {
  static int get foo => 0;
  static set foo(_) {}
  static void bar() {}
}
''');
  }

  test_instance_getter_getter() async {
    await assertErrorsInCode(r'''
class A {}
extension E on A {
  int get foo => 0;
  int get foo => 0;
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 60, 3,
          contextMessages: [message(testFile, 40, 3)]),
    ]);
  }

  test_instance_getter_method() async {
    await assertErrorsInCode(r'''
class A {}
extension E on A {
  int get foo => 0;
  void foo() {}
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 57, 3,
          contextMessages: [message(testFile, 40, 3)]),
    ]);
  }

  test_instance_getter_setter() async {
    await assertNoErrorsInCode(r'''
class A {}
extension E on A {
  int get foo => 0;
  set foo(_) {}
}
''');
  }

  test_instance_method_getter() async {
    await assertErrorsInCode(r'''
class A {}
extension E on A {
  void foo() {}
  int get foo => 0;
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 56, 3,
          contextMessages: [message(testFile, 37, 3)]),
    ]);
  }

  test_instance_method_method() async {
    await assertErrorsInCode(r'''
class A {}
extension E on A {
  void foo() {}
  void foo() {}
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 53, 3,
          contextMessages: [message(testFile, 37, 3)]),
    ]);
  }

  test_instance_method_setter() async {
    await assertErrorsInCode(r'''
class A {}
extension E on A {
  void foo() {}
  set foo(_) {}
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 52, 3,
          contextMessages: [message(testFile, 37, 3)]),
    ]);
  }

  test_instance_setter_getter() async {
    await assertNoErrorsInCode(r'''
class A {}
extension E on A {
  set foo(_) {}
  int get foo => 0;
}
''');
  }

  test_instance_setter_method() async {
    await assertErrorsInCode(r'''
class A {}
extension E on A {
  set foo(_) {}
  void foo() {}
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 53, 3,
          contextMessages: [message(testFile, 36, 3)]),
    ]);
  }

  test_instance_setter_setter() async {
    await assertErrorsInCode(r'''
class A {}
extension E on A {
  void set foo(_) {}
  void set foo(_) {}
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 62, 3,
          contextMessages: [message(testFile, 41, 3)]),
    ]);
  }

  test_static_field_field() async {
    await assertErrorsInCode(r'''
class A {}
extension E on A {
  static int foo = 0;
  static int foo = 0;
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 65, 3,
          contextMessages: [message(testFile, 43, 3)]),
    ]);
  }

  test_static_field_getter() async {
    await assertErrorsInCode(r'''
class A {}
extension E on A {
  static int foo = 0;
  static int get foo => 0;
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 69, 3,
          contextMessages: [message(testFile, 43, 3)]),
    ]);
  }

  test_static_field_method() async {
    await assertErrorsInCode(r'''
class A {}
extension E on A {
  static int foo = 0;
  static void foo() {}
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 66, 3,
          contextMessages: [message(testFile, 43, 3)]),
    ]);
  }

  test_static_fieldFinal_getter() async {
    await assertErrorsInCode(r'''
class A {}
extension E on A {
  static final int foo = 0;
  static int get foo => 0;
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 75, 3,
          contextMessages: [message(testFile, 49, 3)]),
    ]);
  }

  test_static_fieldFinal_setter() async {
    await assertNoErrorsInCode(r'''
class A {}
extension E on A {
  static final int foo = 0;
  static set foo(int x) {}
}
''');
  }

  test_static_getter_getter() async {
    await assertErrorsInCode(r'''
class A {}
extension E on A {
  static int get foo => 0;
  static int get foo => 0;
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 74, 3,
          contextMessages: [message(testFile, 47, 3)]),
    ]);
  }

  test_static_getter_method() async {
    await assertErrorsInCode(r'''
class A {}
extension E on A {
  static int get foo => 0;
  static void foo() {}
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 71, 3,
          contextMessages: [message(testFile, 47, 3)]),
    ]);
  }

  test_static_getter_setter() async {
    await assertNoErrorsInCode(r'''
class A {}
extension E on A {
  static int get foo => 0;
  static set foo(_) {}
}
''');
  }

  test_static_method_getter() async {
    await assertErrorsInCode(r'''
class A {}
extension E on A {
  static void foo() {}
  static int get foo => 0;
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 70, 3,
          contextMessages: [message(testFile, 44, 3)]),
    ]);
  }

  test_static_method_method() async {
    await assertErrorsInCode(r'''
class A {}
extension E on A {
  static void foo() {}
  static void foo() {}
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 67, 3,
          contextMessages: [message(testFile, 44, 3)]),
    ]);
  }

  test_static_method_setter() async {
    await assertErrorsInCode(r'''
class A {}
extension E on A {
  static void foo() {}
  static set foo(_) {}
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 66, 3,
          contextMessages: [message(testFile, 44, 3)]),
    ]);
  }

  test_static_setter_getter() async {
    await assertNoErrorsInCode(r'''
mixin M {
  static set foo(_) {}
  static int get foo => 0;
}
''');
  }

  test_static_setter_method() async {
    await assertErrorsInCode(r'''
class A {}
extension E on A {
  static set foo(_) {}
  static void foo() {}
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 67, 3,
          contextMessages: [message(testFile, 43, 3)]),
    ]);
  }

  test_static_setter_setter() async {
    await assertErrorsInCode(r'''
class A {}
extension E on A {
  static void set foo(_) {}
  static void set foo(_) {}
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 76, 3,
          contextMessages: [message(testFile, 48, 3)]),
    ]);
  }

  test_unitMembers_extension() async {
    await assertErrorsInCode('''
class A {}
extension E on A {}
extension E on A {}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 41, 1,
          contextMessages: [message(testFile, 21, 1)]),
    ]);
  }
}

@reflectiveTest
class DuplicateDefinitionExtensionTypeTest extends PubPackageResolutionTest {
  test_instance_getter_getter() async {
    await assertErrorsInCode(r'''
extension type E(int it) {
  int get foo => 0;
  int get foo => 0;
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 57, 3,
          contextMessages: [message(testFile, 37, 3)]),
    ]);
  }

  test_instance_getter_method() async {
    await assertErrorsInCode(r'''
extension type E(int it) {
  int get foo => 0;
  void foo() {}
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 54, 3,
          contextMessages: [message(testFile, 37, 3)]),
    ]);
  }

  test_instance_getter_setter() async {
    await assertNoErrorsInCode(r'''
extension type E(int it) {
  int get foo => 0;
  set foo(_) {}
}
''');
  }

  test_instance_method_getter() async {
    await assertErrorsInCode(r'''
extension type E(int it) {
  void foo() {}
  int get foo => 0;
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 53, 3,
          contextMessages: [message(testFile, 34, 3)]),
    ]);
  }

  test_instance_method_method() async {
    await assertErrorsInCode(r'''
extension type E(int it) {
  void foo() {}
  void foo() {}
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 50, 3,
          contextMessages: [message(testFile, 34, 3)]),
    ]);
  }

  test_instance_method_setter() async {
    await assertErrorsInCode(r'''
extension type E(int it) {
  void foo() {}
  set foo(_) {}
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 49, 3,
          contextMessages: [message(testFile, 34, 3)]),
    ]);
  }

  test_instance_representation_getter() async {
    await assertErrorsInCode(r'''
extension type E(int it) {
  int get it => 0;
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 37, 2,
          contextMessages: [message(testFile, 21, 2)]),
    ]);
  }

  test_instance_representation_method() async {
    await assertErrorsInCode(r'''
extension type E(int it) {
  void it() {}
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 34, 2,
          contextMessages: [message(testFile, 21, 2)]),
    ]);
  }

  test_instance_representation_setter() async {
    await assertNoErrorsInCode(r'''
extension type E(int it) {
  set it(int _) {}
}
''');
  }

  test_instance_setter_getter() async {
    await assertNoErrorsInCode(r'''
extension type E(int it) {
  set foo(_) {}
  int get foo => 0;
}
''');
  }

  test_instance_setter_method() async {
    await assertErrorsInCode(r'''
extension type E(int it) {
  set foo(_) {}
  void foo() {}
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 50, 3,
          contextMessages: [message(testFile, 33, 3)]),
    ]);
  }

  test_instance_setter_setter() async {
    await assertErrorsInCode(r'''
extension type E(int it) {
  void set foo(_) {}
  void set foo(_) {}
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 59, 3,
          contextMessages: [message(testFile, 38, 3)]),
    ]);
  }

  test_static_field_field() async {
    await assertErrorsInCode(r'''
extension type E(int it) {
  static int foo = 0;
  static int foo = 0;
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 62, 3,
          contextMessages: [message(testFile, 40, 3)]),
    ]);
  }

  test_static_field_getter() async {
    await assertErrorsInCode(r'''
extension type E(int it) {
  static int foo = 0;
  static int get foo => 0;
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 66, 3,
          contextMessages: [message(testFile, 40, 3)]),
    ]);
  }

  test_static_field_method() async {
    await assertErrorsInCode(r'''
extension type E(int it) {
  static int foo = 0;
  static void foo() {}
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 63, 3,
          contextMessages: [message(testFile, 40, 3)]),
    ]);
  }

  test_static_fieldFinal_getter() async {
    await assertErrorsInCode(r'''
extension type E(int it) {
  static final int foo = 0;
  static int get foo => 0;
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 72, 3,
          contextMessages: [message(testFile, 46, 3)]),
    ]);
  }

  test_static_fieldFinal_setter() async {
    await assertNoErrorsInCode(r'''
extension type E(int it) {
  static final int foo = 0;
  static set foo(int x) {}
}
''');
  }

  test_static_getter_getter() async {
    await assertErrorsInCode(r'''
extension type E(int it) {
  static int get foo => 0;
  static int get foo => 0;
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 71, 3,
          contextMessages: [message(testFile, 44, 3)]),
    ]);
  }

  test_static_getter_method() async {
    await assertErrorsInCode(r'''
extension type E(int it) {
  static int get foo => 0;
  static void foo() {}
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 68, 3,
          contextMessages: [message(testFile, 44, 3)]),
    ]);
  }

  test_static_getter_setter() async {
    await assertNoErrorsInCode(r'''
extension type E(int it) {
  static int get foo => 0;
  static set foo(_) {}
}
''');
  }

  test_static_method_getter() async {
    await assertErrorsInCode(r'''
extension type E(int it) {
  static void foo() {}
  static int get foo => 0;
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 67, 3,
          contextMessages: [message(testFile, 41, 3)]),
    ]);
  }

  test_static_method_method() async {
    await assertErrorsInCode(r'''
extension type E(int it) {
  static void foo() {}
  static void foo() {}
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 64, 3,
          contextMessages: [message(testFile, 41, 3)]),
    ]);
  }

  test_static_method_setter() async {
    await assertErrorsInCode(r'''
extension type E(int it) {
  static void foo() {}
  static set foo(_) {}
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 63, 3,
          contextMessages: [message(testFile, 41, 3)]),
    ]);
  }

  test_static_setter_getter() async {
    await assertNoErrorsInCode(r'''
extension type E(int it) {
  static set foo(_) {}
  static int get foo => 0;
}
''');
  }

  test_static_setter_method() async {
    await assertErrorsInCode(r'''
extension type E(int it) {
  static set foo(_) {}
  static void foo() {}
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 64, 3,
          contextMessages: [message(testFile, 40, 3)]),
    ]);
  }

  test_static_setter_setter() async {
    await assertErrorsInCode(r'''
extension type E(int it) {
  static void set foo(_) {}
  static void set foo(_) {}
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 73, 3,
          contextMessages: [message(testFile, 45, 3)]),
    ]);
  }

  test_unitMembers_extensionType() async {
    await assertErrorsInCode('''
extension type E(int it) {}
extension type E(int it) {}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 43, 1,
          contextMessages: [message(testFile, 15, 1)]),
    ]);
  }
}

@reflectiveTest
class DuplicateDefinitionMixinTest extends PubPackageResolutionTest {
  test_instance_field_field() async {
    await assertErrorsInCode(r'''
mixin M {
  int foo = 0;
  int foo = 0;
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 31, 3,
          contextMessages: [message(testFile, 16, 3)]),
    ]);
  }

  test_instance_field_getter() async {
    await assertErrorsInCode(r'''
mixin M {
  int foo = 0;
  int get foo => 0;
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 35, 3,
          contextMessages: [message(testFile, 16, 3)]),
    ]);
  }

  test_instance_field_method() async {
    await assertErrorsInCode(r'''
mixin M {
  int foo = 0;
  void foo() {}
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 32, 3,
          contextMessages: [message(testFile, 16, 3)]),
    ]);
  }

  test_instance_fieldFinal_getter() async {
    await assertErrorsInCode(r'''
mixin M {
  final int foo = 0;
  int get foo => 0;
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 41, 3,
          contextMessages: [message(testFile, 22, 3)]),
    ]);
  }

  test_instance_fieldFinal_setter() async {
    await assertNoErrorsInCode(r'''
mixin M {
  final int foo = 0;
  set foo(int x) {}
}
''');
  }

  test_instance_getter_getter() async {
    await assertErrorsInCode(r'''
mixin M {
  int get foo => 0;
  int get foo => 0;
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 40, 3,
          contextMessages: [message(testFile, 20, 3)]),
    ]);
  }

  test_instance_getter_method() async {
    await assertErrorsInCode(r'''
mixin M {
  int get foo => 0;
  void foo() {}
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 37, 3,
          contextMessages: [message(testFile, 20, 3)]),
    ]);
  }

  test_instance_getter_setter() async {
    await assertNoErrorsInCode(r'''
mixin M {
  int get foo => 0;
  set foo(_) {}
}
''');
  }

  test_instance_method_getter() async {
    await assertErrorsInCode(r'''
mixin M {
  void foo() {}
  int get foo => 0;
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 36, 3,
          contextMessages: [message(testFile, 17, 3)]),
    ]);
  }

  test_instance_method_method() async {
    await assertErrorsInCode(r'''
mixin M {
  void foo() {}
  void foo() {}
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 33, 3,
          contextMessages: [message(testFile, 17, 3)]),
    ]);
  }

  test_instance_method_method_augment() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';

augment mixin A {
  augment void foo() {}
}
''');

    newFile(testFile.path, r'''
import augment 'a.dart';

mixin A {
  void foo() {}
}
''');

    await resolveTestFile();
    assertNoErrorsInResult();

    await resolveFile2(a);
    assertNoErrorsInResult();
  }

  test_instance_method_method_inAugmentation() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';

augment mixin A {
  void foo() {}
}
''');

    newFile(testFile.path, r'''
import augment 'a.dart';

mixin A {
  void foo() {}
}
''');

    await resolveTestFile();
    assertNoErrorsInResult();

    await resolveFile2(a);
    assertErrorsInResult([
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 55, 3,
          contextMessages: [message(testFile, 43, 3)]),
    ]);
  }

  test_instance_method_setter() async {
    await assertErrorsInCode(r'''
mixin M {
  void foo() {}
  set foo(_) {}
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 32, 3,
          contextMessages: [message(testFile, 17, 3)]),
    ]);
  }

  test_instance_setter_getter() async {
    await assertNoErrorsInCode(r'''
mixin M {
  set foo(_) {}
  int get foo => 0;
}
''');
  }

  test_instance_setter_method() async {
    await assertErrorsInCode(r'''
mixin M {
  set foo(_) {}
  void foo() {}
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 33, 3,
          contextMessages: [message(testFile, 16, 3)]),
    ]);
  }

  test_instance_setter_setter() async {
    await assertErrorsInCode(r'''
mixin M {
  void set foo(_) {}
  void set foo(_) {}
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 42, 3,
          contextMessages: [message(testFile, 21, 3)]),
    ]);
  }

  test_static_field_field() async {
    await assertErrorsInCode(r'''
mixin M {
  static int foo = 0;
  static int foo = 0;
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 45, 3,
          contextMessages: [message(testFile, 23, 3)]),
    ]);
  }

  test_static_field_getter() async {
    await assertErrorsInCode(r'''
mixin M {
  static int foo = 0;
  static int get foo => 0;
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 49, 3,
          contextMessages: [message(testFile, 23, 3)]),
    ]);
  }

  test_static_field_method() async {
    await assertErrorsInCode(r'''
mixin M {
  static int foo = 0;
  static void foo() {}
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 46, 3,
          contextMessages: [message(testFile, 23, 3)]),
    ]);
  }

  test_static_fieldFinal_getter() async {
    await assertErrorsInCode(r'''
mixin M {
  static final int foo = 0;
  static int get foo => 0;
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 55, 3,
          contextMessages: [message(testFile, 29, 3)]),
    ]);
  }

  test_static_fieldFinal_setter() async {
    await assertNoErrorsInCode(r'''
mixin M {
  static final int foo = 0;
  static set foo(int x) {}
}
''');
  }

  test_static_getter_getter() async {
    await assertErrorsInCode(r'''
mixin M {
  static int get foo => 0;
  static int get foo => 0;
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 54, 3,
          contextMessages: [message(testFile, 27, 3)]),
    ]);
  }

  test_static_getter_method() async {
    await assertErrorsInCode(r'''
mixin M {
  static int get foo => 0;
  static void foo() {}
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 51, 3,
          contextMessages: [message(testFile, 27, 3)]),
    ]);
  }

  test_static_getter_setter() async {
    await assertNoErrorsInCode(r'''
mixin M {
  static int get foo => 0;
  static set foo(_) {}
}
''');
  }

  test_static_method_getter() async {
    await assertErrorsInCode(r'''
mixin M {
  static void foo() {}
  static int get foo => 0;
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 50, 3,
          contextMessages: [message(testFile, 24, 3)]),
    ]);
  }

  test_static_method_method() async {
    await assertErrorsInCode(r'''
mixin M {
  static void foo() {}
  static void foo() {}
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 47, 3,
          contextMessages: [message(testFile, 24, 3)]),
    ]);
  }

  test_static_method_setter() async {
    await assertErrorsInCode(r'''
mixin M {
  static void foo() {}
  static set foo(_) {}
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 46, 3,
          contextMessages: [message(testFile, 24, 3)]),
    ]);
  }

  test_static_setter_getter() async {
    await assertNoErrorsInCode(r'''
mixin M {
  static set foo(_) {}
  static int get foo => 0;
}
''');
  }

  test_static_setter_method() async {
    await assertErrorsInCode(r'''
mixin M {
  static set foo(_) {}
  static void foo() {}
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 47, 3,
          contextMessages: [message(testFile, 23, 3)]),
    ]);
  }

  test_static_setter_setter() async {
    await assertErrorsInCode(r'''
mixin M {
  static void set foo(_) {}
  static void set foo(_) {}
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 56, 3,
          contextMessages: [message(testFile, 28, 3)]),
    ]);
  }
}

@reflectiveTest
class DuplicateDefinitionTest extends PubPackageResolutionTest {
  test_block_localVariable_localVariable() async {
    await assertErrorsInCode(r'''
void f() {
  var a = 0;
  var a = 1;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 17, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 30, 1),
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 30, 1,
          contextMessages: [message(testFile, 17, 1)]),
    ]);
  }

  test_block_localVariable_patternVariable() async {
    await assertErrorsInCode(r'''
void f() {
  var a = 0;
  var (a) = 1;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 17, 1),
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 31, 1,
          contextMessages: [message(testFile, 17, 1)]),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 31, 1),
    ]);
  }

  test_block_patternVariable_localVariable() async {
    await assertErrorsInCode(r'''
void f() {
  var (a) = 1;
  var a = 0;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 18, 1),
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 32, 1,
          contextMessages: [message(testFile, 18, 1)]),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 32, 1),
    ]);
  }

  test_block_patternVariable_patternVariable() async {
    await assertErrorsInCode(r'''
void f() {
  var (a) = 0;
  var (a) = 1;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 18, 1),
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 33, 1,
          contextMessages: [message(testFile, 18, 1)]),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 33, 1),
    ]);
  }

  test_catch() async {
    await assertErrorsInCode(r'''
main() {
  try {} catch (e, e) {}
}''', [
      error(WarningCode.UNUSED_CATCH_STACK, 28, 1),
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 28, 1,
          contextMessages: [message(testFile, 25, 1)]),
    ]);
  }

  test_emptyName() async {
    // Note: This code has two FunctionElements '() {}' with an empty name; this
    // tests that the empty string is not put into the scope (more than once).
    await assertErrorsInCode(r'''
Map _globalMap = {
  'a' : () {},
  'b' : () {}
};
''', [
      error(WarningCode.UNUSED_ELEMENT, 4, 10),
    ]);
  }

  test_for_initializers() async {
    await assertErrorsInCode(r'''
f() {
  for (int i = 0, i = 0; i < 5;) {}
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 24, 1,
          contextMessages: [message(testFile, 17, 1)]),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 24, 1),
    ]);
  }

  test_getter_single() async {
    await assertNoErrorsInCode('''
bool get a => true;
''');
  }

  test_parameters_constructor_field_first() async {
    await assertErrorsInCode(r'''
class A {
  int? a;
  A(this.a, int a);
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 36, 1,
          contextMessages: [message(testFile, 29, 1)]),
    ]);
  }

  test_parameters_constructor_field_second() async {
    await assertErrorsInCode(r'''
class A {
  int? a;
  A(int a, this.a);
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 36, 1,
          contextMessages: [message(testFile, 28, 1)]),
    ]);
  }

  test_parameters_functionTypeAlias() async {
    await assertErrorsInCode(r'''
typedef void F(int a, double a);
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 29, 1,
          contextMessages: [message(testFile, 19, 1)]),
    ]);
  }

  test_parameters_genericFunction() async {
    await assertErrorsInCode(r'''
typedef F = void Function(int a, double a);
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 40, 1,
          contextMessages: [message(testFile, 30, 1)]),
    ]);
  }

  test_parameters_localFunction() async {
    await assertErrorsInCode(r'''
main() {
  f(int a, double a) {
  };
}
''', [
      error(WarningCode.UNUSED_ELEMENT, 11, 1),
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 27, 1,
          contextMessages: [message(testFile, 17, 1)]),
    ]);
  }

  test_parameters_method() async {
    await assertErrorsInCode(r'''
class A {
  m(int a, double a) {
  }
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 28, 1,
          contextMessages: [message(testFile, 18, 1)]),
    ]);
  }

  test_parameters_topLevelFunction() async {
    await assertErrorsInCode(r'''
f(int a, double a) {}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 16, 1,
          contextMessages: [message(testFile, 6, 1)]),
    ]);
  }

  test_switchCase_localVariable_localVariable() async {
    await assertErrorsInCode(r'''
// @dart = 2.19
void f() {
  switch (0) {
    case 0:
      var a;
      var a;
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 64, 1),
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 77, 1,
          contextMessages: [message(testFile, 64, 1)]),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 77, 1),
    ]);
  }

  test_switchDefault_localVariable_localVariable() async {
    await assertErrorsInCode(r'''
void f() {
  switch (0) {
    default:
      var a;
      var a;
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 49, 1),
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 62, 1,
          contextMessages: [message(testFile, 49, 1)]),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 62, 1),
    ]);
  }

  test_switchPatternCase_localVariable_localVariable() async {
    await assertErrorsInCode(r'''
void f() {
  switch (0) {
    case 0:
      var a;
      var a;
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 48, 1),
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 61, 1,
          contextMessages: [message(testFile, 48, 1)]),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 61, 1),
    ]);
  }

  test_typeParameters_class() async {
    await assertErrorsInCode(r'''
class A<T, T> {}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 11, 1,
          contextMessages: [message(testFile, 8, 1)]),
    ]);
  }

  test_typeParameters_functionTypeAlias() async {
    await assertErrorsInCode(r'''
typedef void F<T, T>();
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 18, 1,
          contextMessages: [message(testFile, 15, 1)]),
    ]);
  }

  test_typeParameters_genericFunction() async {
    await assertErrorsInCode(r'''
typedef F = void Function<T, T>();
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 29, 1,
          contextMessages: [message(testFile, 26, 1)]),
    ]);
  }

  test_typeParameters_genericTypedef_functionType() async {
    await assertErrorsInCode(r'''
typedef F<T, T> = void Function();
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 13, 1,
          contextMessages: [message(testFile, 10, 1)]),
    ]);
  }

  test_typeParameters_genericTypedef_interfaceType() async {
    await assertErrorsInCode(r'''
typedef F<T, T> = Map;
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 13, 1,
          contextMessages: [message(testFile, 10, 1)]),
    ]);
  }

  test_typeParameters_method() async {
    await assertErrorsInCode(r'''
class A {
  void m<T, T>() {}
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 22, 1,
          contextMessages: [message(testFile, 19, 1)]),
    ]);
  }

  test_typeParameters_topLevelFunction() async {
    await assertErrorsInCode(r'''
void f<T, T>() {}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 10, 1,
          contextMessages: [message(testFile, 7, 1)]),
    ]);
  }
}

@reflectiveTest
class DuplicateDefinitionUnitTest extends PubPackageResolutionTest {
  test_class() async {
    await assertErrorsInCode('''
class A {}
class B {}
class A {}
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 28, 1,
          contextMessages: [message(testFile, 6, 1)])
    ]);
  }

  test_class_augmentation() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';

augment class A {}
''');

    newFile(testFile.path, r'''
import augment 'a.dart';

class A {}
''');

    await resolveTestFile();
    assertNoErrorsInResult();

    await resolveFile2(a);
    assertNoErrorsInResult();
  }

  test_mixin_augmentation() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';

augment mixin A {}
''');

    newFile(testFile.path, r'''
import augment 'a.dart';

mixin A {}
''');

    await resolveTestFile();
    assertNoErrorsInResult();

    await resolveFile2(a);
    assertNoErrorsInResult();
  }

  test_part_library() async {
    var lib = newFile('$testPackageLibPath/lib.dart', '''
part 'a.dart';

class A {}
''');

    var a = newFile('$testPackageLibPath/a.dart', '''
part of 'lib.dart';

class A {}
''');

    await resolveFile(lib);

    var aResult = await resolveFile(a);
    GatheringErrorListener()
      ..addAll(aResult.errors)
      ..assertErrors([
        error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 27, 1,
            contextMessages: [message(lib, 22, 1)]),
      ]);
  }

  test_part_part() async {
    var lib = newFile('$testPackageLibPath/lib.dart', '''
part 'a.dart';
part 'b.dart';
''');

    var a = newFile('$testPackageLibPath/a.dart', '''
part of 'lib.dart';

class A {}
''');

    var b = newFile('$testPackageLibPath/b.dart', '''
part of 'lib.dart';

class A {}
''');

    await resolveFile(lib);

    var aResult = await resolveFile(a);
    GatheringErrorListener()
      ..addAll(aResult.errors)
      ..assertNoErrors();

    var bResult = await resolveFile(b);
    GatheringErrorListener()
      ..addAll(bResult.errors)
      ..assertErrors([
        error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 27, 1,
            contextMessages: [message(a, 27, 1)]),
      ]);
  }

  test_typedef_interfaceType() async {
    await assertErrorsInCode('''
typedef A = List<int>;
typedef A = List<int>;
''', [
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 31, 1,
          contextMessages: [message(testFile, 8, 1)]),
    ]);
  }

  test_variable_variable_augment() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';

augment int foo = 42;
''');

    newFile(testFile.path, r'''
import augment 'a.dart';

int foo = 0;
''');

    await resolveTestFile();
    assertNoErrorsInResult();

    await resolveFile2(a);
    assertNoErrorsInResult();
  }

  test_variable_variable_inAugmentation() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
augment library 'test.dart';

int foo = 42;
''');

    newFile(testFile.path, r'''
import augment 'a.dart';

int foo = 0;
''');

    await resolveTestFile();
    assertNoErrorsInResult();

    await resolveFile2(a);
    assertErrorsInResult([
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 34, 3,
          contextMessages: [message(testFile, 30, 3)]),
    ]);
  }
}
