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
    await assertErrorsInCode(
      r'''
class C {
  int foo = 0;
  int foo = 0;
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          31,
          3,
          contextMessages: [message(testFile, 16, 3)],
        ),
      ],
    );
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_instance_field_field_augment() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';

augment class A {
  augment int foo = 42;
}
''');

    newFile(testFile.path, r'''
part 'a.dart';

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
    await assertErrorsInCode(
      r'''
class C {
  int foo = 0;
  int foo = 0;
  int foo = 0;
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          31,
          3,
          contextMessages: [message(testFile, 16, 3)],
        ),
        error(
          CompileTimeErrorCode.duplicateDefinition,
          46,
          3,
          contextMessages: [message(testFile, 16, 3)],
        ),
      ],
    );
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_instance_field_field_inAugmentation() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';

augment class A {
  int foo = 42;
}
''');

    newFile(testFile.path, r'''
part 'a.dart';

class A {
  int foo = 0;
}
''');

    await resolveTestFile();
    assertNoErrorsInResult();

    await resolveFile2(a);
    assertErrorsInResult([
      error(
        CompileTimeErrorCode.duplicateDefinition,
        46,
        3,
        contextMessages: [message(testFile, 32, 3)],
      ),
    ]);
  }

  test_instance_field_getter() async {
    await assertErrorsInCode(
      r'''
class C {
  int foo = 0;
  int get foo => 0;
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          35,
          3,
          contextMessages: [message(testFile, 16, 3)],
        ),
      ],
    );
  }

  test_instance_field_method() async {
    await assertErrorsInCode(
      r'''
class C {
  int foo = 0;
  void foo() {}
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          32,
          3,
          contextMessages: [message(testFile, 16, 3)],
        ),
      ],
    );
  }

  test_instance_fieldFinal_getter() async {
    await assertErrorsInCode(
      r'''
class C {
  final int foo = 0;
  int get foo => 0;
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          41,
          3,
          contextMessages: [message(testFile, 22, 3)],
        ),
      ],
    );
  }

  test_instance_fieldFinal_setter() async {
    await assertNoErrorsInCode(r'''
class C {
  final int foo = 0;
  set foo(int x) {}
}
''');
  }

  test_instance_fieldLateFinalInitializer_setter() async {
    await assertNoErrorsInCode(r'''
class C {
  late final int foo = 1;
  set foo(_) {}
}
''');
  }

  test_instance_fieldLateFinalNoInitializer_setter() async {
    await assertErrorsInCode(
      r'''
class C {
  late final int foo;
  set foo(_) {}
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          38,
          3,
          contextMessages: [message(testFile, 27, 3)],
        ),
      ],
    );
  }

  test_instance_getter_getter() async {
    await assertErrorsInCode(
      r'''
class C {
  int get foo => 0;
  int get foo => 0;
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          40,
          3,
          contextMessages: [message(testFile, 20, 3)],
        ),
      ],
    );
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_instance_getter_getter_augment() async {
    await assertNoErrorsInCode(r'''
class C {
  int get foo => 0;
}

augment class C {
  augment int get foo => 0;
}
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_instance_getter_getter_inAugmentation() async {
    await assertErrorsInCode(
      r'''
class C {
  int get foo => 0;
}

augment class C {
  int get foo => 0;
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          61,
          3,
          contextMessages: [message(testFile, 20, 3)],
        ),
      ],
    );
  }

  test_instance_getter_getter_setter() async {
    await assertErrorsInCode(
      r'''
class A {
  int? get b => null;
  int? get b => 0;
  void set b(int? value) {}
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          43,
          1,
          contextMessages: [message(testFile, 21, 1)],
        ),
      ],
    );
  }

  test_instance_getter_method() async {
    await assertErrorsInCode(
      r'''
class C {
  int get foo => 0;
  void foo() {}
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          37,
          3,
          contextMessages: [message(testFile, 20, 3)],
        ),
      ],
    );
  }

  test_instance_getter_setter() async {
    await assertNoErrorsInCode(r'''
class C {
  int get foo => 0;
  set foo(_) {}
}
''');
  }

  test_instance_getter_setter_getter() async {
    await assertErrorsInCode(
      r'''
class A {
  int? get b => null;
  void set b(int? value) {}
  int? get b => 0;
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          71,
          1,
          contextMessages: [message(testFile, 21, 1)],
        ),
      ],
    );
  }

  test_instance_getter_setter_setter() async {
    await assertErrorsInCode(
      r'''
class A {
  int? get b => null;
  void set b(int? value) {}
  void set b(int? value) {}
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          71,
          1,
          contextMessages: [message(testFile, 43, 1)],
        ),
      ],
    );
  }

  test_instance_method_getter() async {
    await assertErrorsInCode(
      r'''
class C {
  void foo() {}
  int get foo => 0;
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          36,
          3,
          contextMessages: [message(testFile, 17, 3)],
        ),
      ],
    );
  }

  test_instance_method_method() async {
    await assertErrorsInCode(
      r'''
class C {
  void foo() {}
  void foo() {}
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          33,
          3,
          contextMessages: [message(testFile, 17, 3)],
        ),
      ],
    );
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_instance_method_method_augment() async {
    await assertNoErrorsInCode(r'''
class A {
  void foo() {}
}

augment class A {
  augment void foo() {}
}
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_instance_method_method_inAugmentation() async {
    await assertErrorsInCode(
      r'''
class A {
  void foo() {}
}

augment class A {
  void foo() {}
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          54,
          3,
          contextMessages: [message(testFile, 17, 3)],
        ),
      ],
    );
  }

  test_instance_method_setter() async {
    await assertErrorsInCode(
      r'''
class C {
  void foo() {}
  set foo(_) {}
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          32,
          3,
          contextMessages: [message(testFile, 17, 3)],
        ),
      ],
    );
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_instance_method_setter_inAugmentation() async {
    await assertErrorsInCode(
      r'''
class A {
  void foo() {}
}

augment class A {
  set foo(_) {}
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          53,
          3,
          contextMessages: [message(testFile, 17, 3)],
        ),
      ],
    );
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_instance_operator_operator_augment() async {
    await assertNoErrorsInCode(r'''
class A {
  int operator +(int _) => 0;
}

augment class A {
  augment int operator +(int _) => 0;
}
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_instance_operator_operator_inAugmentation() async {
    await assertErrorsInCode(
      r'''
class A {
  int operator +(int _) => 0;
}

augment class A {
  int operator +(int _) => 0;
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          76,
          1,
          contextMessages: [message(testFile, 25, 1)],
        ),
      ],
    );
  }

  test_instance_setter_getter() async {
    await assertNoErrorsInCode(r'''
class C {
  set foo(_) {}
  int get foo => 0;
}
''');
  }

  test_instance_setter_getter_getter() async {
    await assertErrorsInCode(
      r'''
class A {
  void set b(int? value) {}
  int? get b => null;
  int? get b => 0;
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          71,
          1,
          contextMessages: [message(testFile, 49, 1)],
        ),
      ],
    );
  }

  test_instance_setter_getter_setter() async {
    await assertErrorsInCode(
      r'''
class A {
  void set b(int? value) {}
  int? get b => null;
  void set b(int? value) {}
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          71,
          1,
          contextMessages: [message(testFile, 21, 1)],
        ),
      ],
    );
  }

  test_instance_setter_method() async {
    await assertErrorsInCode(
      r'''
class C {
  set foo(_) {}
  void foo() {}
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          33,
          3,
          contextMessages: [message(testFile, 16, 3)],
        ),
      ],
    );
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_instance_setter_method_inAugmentation() async {
    await assertErrorsInCode(
      r'''
class A {
  set foo(_) {}
}

augment class A {
  void foo() {}
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          54,
          3,
          contextMessages: [message(testFile, 16, 3)],
        ),
      ],
    );
  }

  test_instance_setter_setter() async {
    await assertErrorsInCode(
      r'''
class C {
  void set foo(_) {}
  void set foo(_) {}
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          42,
          3,
          contextMessages: [message(testFile, 21, 3)],
        ),
      ],
    );
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_instance_setter_setter_augment() async {
    await assertNoErrorsInCode(r'''
class C {
  void set foo(_) {}
}

augment class C {
  augment void set foo(_) {}
}
''');
  }

  test_instance_setter_setter_getter() async {
    await assertErrorsInCode(
      r'''
class A {
  void set b(int? value) {}
  void set b(int? value) {}
  int? get b => null;
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          49,
          1,
          contextMessages: [message(testFile, 21, 1)],
        ),
      ],
    );
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_instance_setter_setter_inAugmentation() async {
    await assertErrorsInCode(
      r'''
class C {
  void set foo(_) {}
}

augment class C {
  void set foo(_) {}
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          63,
          3,
          contextMessages: [message(testFile, 21, 3)],
        ),
      ],
    );
  }

  test_static_field_field() async {
    await assertErrorsInCode(
      r'''
class C {
  static int foo = 0;
  static int foo = 0;
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          45,
          3,
          contextMessages: [message(testFile, 23, 3)],
        ),
      ],
    );
  }

  test_static_field_getter() async {
    await assertErrorsInCode(
      r'''
class C {
  static int foo = 0;
  static int get foo => 0;
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          49,
          3,
          contextMessages: [message(testFile, 23, 3)],
        ),
      ],
    );
  }

  test_static_field_method() async {
    await assertErrorsInCode(
      r'''
class C {
  static int foo = 0;
  static void foo() {}
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          46,
          3,
          contextMessages: [message(testFile, 23, 3)],
        ),
      ],
    );
  }

  test_static_fieldFinal_getter() async {
    await assertErrorsInCode(
      r'''
class C {
  static final int foo = 0;
  static int get foo => 0;
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          55,
          3,
          contextMessages: [message(testFile, 29, 3)],
        ),
      ],
    );
  }

  test_static_fieldFinal_setter() async {
    await assertNoErrorsInCode(r'''
class C {
  static final int foo = 0;
  static set foo(int x) {}
}
''');
  }

  test_static_fieldLateFinalInitializer_setter() async {
    await assertNoErrorsInCode(r'''
class C {
  static late final int foo = 0;
  static set foo(int x) {}
}
''');
  }

  test_static_fieldLateFinalNoInitializer_setter() async {
    await assertErrorsInCode(
      r'''
class C {
  static late final int foo;
  static set foo(int x) {}
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          52,
          3,
          contextMessages: [message(testFile, 34, 3)],
        ),
      ],
    );
  }

  test_static_getter_getter() async {
    await assertErrorsInCode(
      r'''
class C {
  static int get foo => 0;
  static int get foo => 0;
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          54,
          3,
          contextMessages: [message(testFile, 27, 3)],
        ),
      ],
    );
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_static_getter_getter_augment() async {
    await assertNoErrorsInCode(r'''
class A {
  static int get foo => 0;
}

augment class A {
  augment static int get foo => 0;
}
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_static_getter_getter_inAugmentation() async {
    await assertErrorsInCode(
      r'''
class A {
  static int get foo => 0;
}

augment class A {
  static int get foo => 0;
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          75,
          3,
          contextMessages: [message(testFile, 27, 3)],
        ),
      ],
    );
  }

  test_static_getter_method() async {
    await assertErrorsInCode(
      r'''
class C {
  static int get foo => 0;
  static void foo() {}
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          51,
          3,
          contextMessages: [message(testFile, 27, 3)],
        ),
      ],
    );
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
    await assertErrorsInCode(
      r'''
class C {
  static void foo() {}
  static int get foo => 0;
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          50,
          3,
          contextMessages: [message(testFile, 24, 3)],
        ),
      ],
    );
  }

  test_static_method_method() async {
    await assertErrorsInCode(
      r'''
class C {
  static void foo() {}
  static void foo() {}
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          47,
          3,
          contextMessages: [message(testFile, 24, 3)],
        ),
      ],
    );
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_static_method_method_augment() async {
    await assertNoErrorsInCode(r'''
class A {
  static void foo() {}
}

augment class A {
  augment static void foo() {}
}
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_static_method_method_inAugmentation() async {
    await assertErrorsInCode(
      r'''
class A {
  static void foo() {}
}

augment class A {
  static void foo() {}
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          68,
          3,
          contextMessages: [message(testFile, 24, 3)],
        ),
      ],
    );
  }

  test_static_method_setter() async {
    await assertErrorsInCode(
      r'''
class C {
  static void foo() {}
  static set foo(_) {}
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          46,
          3,
          contextMessages: [message(testFile, 24, 3)],
        ),
      ],
    );
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
    await assertErrorsInCode(
      r'''
class C {
  static set foo(_) {}
  static void foo() {}
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          47,
          3,
          contextMessages: [message(testFile, 23, 3)],
        ),
      ],
    );
  }

  test_static_setter_setter() async {
    await assertErrorsInCode(
      r'''
class C {
  static void set foo(_) {}
  static void set foo(_) {}
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          56,
          3,
          contextMessages: [message(testFile, 28, 3)],
        ),
      ],
    );
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_static_setter_setter_augment() async {
    await assertNoErrorsInCode(r'''
class A {
  static void set foo(_) {}
}

augment class A {
  augment static void set foo(_) {}
}
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_static_setter_setter_inAugmentation() async {
    await assertErrorsInCode(
      r'''
class A {
  static void set foo(_) {}
}

augment class A {
  static void set foo(_) {}
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          77,
          3,
          contextMessages: [message(testFile, 28, 3)],
        ),
      ],
    );
  }
}

@reflectiveTest
class DuplicateDefinitionEnumTest extends PubPackageResolutionTest {
  test_constant() async {
    await assertErrorsInCode(
      r'''
enum E {
  foo, foo
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          16,
          3,
          contextMessages: [message(testFile, 11, 3)],
        ),
      ],
    );
  }

  test_instance_field_field() async {
    await assertErrorsInCode(
      r'''
enum E {
  v;
  final int foo = 0;
  final int foo = 0;
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          47,
          3,
          contextMessages: [message(testFile, 26, 3)],
        ),
      ],
    );
  }

  test_instance_field_getter() async {
    await assertErrorsInCode(
      r'''
enum E {
  v;
  final int foo = 0;
  int get foo => 0;
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          45,
          3,
          contextMessages: [message(testFile, 26, 3)],
        ),
      ],
    );
  }

  test_instance_field_method() async {
    await assertErrorsInCode(
      r'''
enum E {
  v;
  final int foo = 0;
  void foo() {}
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          42,
          3,
          contextMessages: [message(testFile, 26, 3)],
        ),
      ],
    );
  }

  test_instance_fieldFinal_getter() async {
    await assertErrorsInCode(
      r'''
enum E {
  v;
  final int foo = 0;
  int get foo => 0;
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          45,
          3,
          contextMessages: [message(testFile, 26, 3)],
        ),
      ],
    );
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
    await assertErrorsInCode(
      r'''
enum E {
  v;
  int get foo => 0;
  int get foo => 0;
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          44,
          3,
          contextMessages: [message(testFile, 24, 3)],
        ),
      ],
    );
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_instance_getter_getter_augment() async {
    await assertNoErrorsInCode(r'''
enum E {
  v;
  int get foo => 0;
}

augment enum E {;
  augment int get foo => 0;
}
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_instance_getter_getter_inAugmentation() async {
    await assertErrorsInCode(
      r'''
enum E {
  v;
  int get foo => 0;
}

augment enum E {;
  int get foo => 0;
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          65,
          3,
          contextMessages: [message(testFile, 24, 3)],
        ),
      ],
    );
  }

  test_instance_getter_method() async {
    await assertErrorsInCode(
      r'''
enum E {
  v;
  int get foo => 0;
  void foo() {}
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          41,
          3,
          contextMessages: [message(testFile, 24, 3)],
        ),
      ],
    );
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
    await assertErrorsInCode(
      r'''
enum E {
  v;
  void foo() {}
  int get foo => 0;
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          40,
          3,
          contextMessages: [message(testFile, 21, 3)],
        ),
      ],
    );
  }

  test_instance_method_method() async {
    await assertErrorsInCode(
      r'''
enum E {
  v;
  void foo() {}
  void foo() {}
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          37,
          3,
          contextMessages: [message(testFile, 21, 3)],
        ),
      ],
    );
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_instance_method_method_augment() async {
    await assertNoErrorsInCode(r'''
enum E {
  v;
  void foo() {}
}

augment enum E {;
  augment void foo() {}
}
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_instance_method_method_inAugmentation() async {
    await assertErrorsInCode(
      r'''
enum E {
  v;
  void foo() {}
}

augment enum E {;
  void foo() {}
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          58,
          3,
          contextMessages: [message(testFile, 21, 3)],
        ),
      ],
    );
  }

  test_instance_method_setter() async {
    await assertErrorsInCode(
      r'''
enum E {
  v;
  void foo() {}
  set foo(_) {}
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          36,
          3,
          contextMessages: [message(testFile, 21, 3)],
        ),
      ],
    );
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
    await assertErrorsInCode(
      r'''
enum E {
  v;
  set foo(_) {}
  void foo() {}
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          37,
          3,
          contextMessages: [message(testFile, 20, 3)],
        ),
      ],
    );
  }

  test_instance_setter_setter() async {
    await assertErrorsInCode(
      r'''
enum E {
  v;
  void set foo(_) {}
  void set foo(_) {}
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          46,
          3,
          contextMessages: [message(testFile, 25, 3)],
        ),
      ],
    );
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_instance_setter_setter_augment() async {
    await assertNoErrorsInCode(r'''
enum E {
  v;
  void set foo(_) {}
}

augment enum E {;
  augment void set foo(_) {}
}
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_instance_setter_setter_inAugmentation() async {
    await assertErrorsInCode(
      r'''
enum E {
  v;
  void set foo(_) {}
}

augment enum E {;
  void set foo(_) {}
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          67,
          3,
          contextMessages: [message(testFile, 25, 3)],
        ),
      ],
    );
  }

  test_static_constant_field() async {
    await assertErrorsInCode(
      r'''
enum E {
  foo;
  static int foo = 0;
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          29,
          3,
          contextMessages: [message(testFile, 11, 3)],
        ),
      ],
    );
  }

  test_static_constant_getter() async {
    await assertErrorsInCode(
      r'''
enum E {
  foo;
  static int get foo => 0;
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          33,
          3,
          contextMessages: [message(testFile, 11, 3)],
        ),
      ],
    );
  }

  test_static_constant_method() async {
    await assertErrorsInCode(
      r'''
enum E {
  foo;
  static void foo() {}
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          30,
          3,
          contextMessages: [message(testFile, 11, 3)],
        ),
      ],
    );
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
    await assertErrorsInCode(
      r'''
enum E {
  v;
  static int foo = 0;
  static int foo = 0;
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          49,
          3,
          contextMessages: [message(testFile, 27, 3)],
        ),
      ],
    );
  }

  test_static_field_getter() async {
    await assertErrorsInCode(
      r'''
enum E {
  v;
  static int foo = 0;
  static int get foo => 0;
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          53,
          3,
          contextMessages: [message(testFile, 27, 3)],
        ),
      ],
    );
  }

  test_static_field_method() async {
    await assertErrorsInCode(
      r'''
enum E {
  v;
  static int foo = 0;
  static void foo() {}
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          50,
          3,
          contextMessages: [message(testFile, 27, 3)],
        ),
      ],
    );
  }

  test_static_fieldFinal_getter() async {
    await assertErrorsInCode(
      r'''
enum E {
  v;
  static final int foo = 0;
  static int get foo => 0;
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          59,
          3,
          contextMessages: [message(testFile, 33, 3)],
        ),
      ],
    );
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
    await assertErrorsInCode(
      r'''
enum E {
  v;
  static int get foo => 0;
  static int get foo => 0;
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          58,
          3,
          contextMessages: [message(testFile, 31, 3)],
        ),
      ],
    );
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_static_getter_getter_augment() async {
    await assertNoErrorsInCode(r'''
enum E {
  v;
  static int get foo => 0;
}

augment enum E {;
  augment static int get foo => 0;
}
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_static_getter_getter_inAugmentation() async {
    await assertErrorsInCode(
      r'''
enum E {
  v;
  static int get foo => 0;
}

augment enum E {;
  static int get foo => 0;
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          79,
          3,
          contextMessages: [message(testFile, 31, 3)],
        ),
      ],
    );
  }

  test_static_getter_method() async {
    await assertErrorsInCode(
      r'''
enum E {
  v;
  static int get foo => 0;
  static void foo() {}
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          55,
          3,
          contextMessages: [message(testFile, 31, 3)],
        ),
      ],
    );
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
    await assertErrorsInCode(
      r'''
enum E {
  v;
  static void foo() {}
  static int get foo => 0;
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          54,
          3,
          contextMessages: [message(testFile, 28, 3)],
        ),
      ],
    );
  }

  test_static_method_method() async {
    await assertErrorsInCode(
      r'''
enum E {
  v;
  static void foo() {}
  static void foo() {}
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          51,
          3,
          contextMessages: [message(testFile, 28, 3)],
        ),
      ],
    );
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_static_method_method_augment() async {
    await assertNoErrorsInCode(r'''
enum E {
  v;
  static void foo() {}
}

augment enum E {;
  augment static void foo() {}
}
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_static_method_method_inAugmentation() async {
    await assertErrorsInCode(
      r'''
enum E {
  v;
  static void foo() {}
}

augment enum E {;
  static void foo() {}
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          72,
          3,
          contextMessages: [message(testFile, 28, 3)],
        ),
      ],
    );
  }

  test_static_method_setter() async {
    await assertErrorsInCode(
      r'''
enum E {
  v;
  static void foo() {}
  static set foo(_) {}
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          50,
          3,
          contextMessages: [message(testFile, 28, 3)],
        ),
      ],
    );
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
    await assertErrorsInCode(
      r'''
enum E {
  v;
  static set foo(_) {}
  static void foo() {}
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          51,
          3,
          contextMessages: [message(testFile, 27, 3)],
        ),
      ],
    );
  }

  test_static_setter_setter() async {
    await assertErrorsInCode(
      r'''
enum E {
  v;
  static void set foo(_) {}
  static void set foo(_) {}
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          60,
          3,
          contextMessages: [message(testFile, 32, 3)],
        ),
      ],
    );
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_static_setter_setter_augment() async {
    await assertNoErrorsInCode(r'''
enum E {
  v;
  static void set foo(_) {}
}

augment enum E {;
  augment static void set foo(_) {}
}
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_static_setter_setter_inAugmentation() async {
    await assertErrorsInCode(
      r'''
enum E {
  v;
  static void set foo(_) {}
}

augment enum E {;
  static void set foo(_) {}
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          81,
          3,
          contextMessages: [message(testFile, 32, 3)],
        ),
      ],
    );
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
    await assertErrorsInCode(
      r'''
class A {}
extension E on A {
  int get foo => 0;
  int get foo => 0;
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          60,
          3,
          contextMessages: [message(testFile, 40, 3)],
        ),
      ],
    );
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_instance_getter_getter_augment() async {
    await assertNoErrorsInCode(r'''
extension E on int {
  int get foo => 0;
}

augment extension E {
  augment int get foo => 0;
}
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_instance_getter_getter_inAugmentation() async {
    await assertErrorsInCode(
      r'''
extension E on int {
  int get foo => 0;
}

augment extension E {
  int get foo => 0;
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          76,
          3,
          contextMessages: [message(testFile, 31, 3)],
        ),
      ],
    );
  }

  test_instance_getter_method() async {
    await assertErrorsInCode(
      r'''
class A {}
extension E on A {
  int get foo => 0;
  void foo() {}
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          57,
          3,
          contextMessages: [message(testFile, 40, 3)],
        ),
      ],
    );
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
    await assertErrorsInCode(
      r'''
class A {}
extension E on A {
  void foo() {}
  int get foo => 0;
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          56,
          3,
          contextMessages: [message(testFile, 37, 3)],
        ),
      ],
    );
  }

  test_instance_method_method() async {
    await assertErrorsInCode(
      r'''
class A {}
extension E on A {
  void foo() {}
  void foo() {}
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          53,
          3,
          contextMessages: [message(testFile, 37, 3)],
        ),
      ],
    );
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_instance_method_method_augment() async {
    await assertNoErrorsInCode(r'''
extension E on int {
  void foo() {}
}

augment extension E {
  augment void foo() {}
}
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_instance_method_method_inAugmentation() async {
    await assertErrorsInCode(
      r'''
extension E on int {
  void foo() {}
}

augment extension E {
  void foo() {}
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          69,
          3,
          contextMessages: [message(testFile, 28, 3)],
        ),
      ],
    );
  }

  test_instance_method_setter() async {
    await assertErrorsInCode(
      r'''
class A {}
extension E on A {
  void foo() {}
  set foo(_) {}
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          52,
          3,
          contextMessages: [message(testFile, 37, 3)],
        ),
      ],
    );
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
    await assertErrorsInCode(
      r'''
class A {}
extension E on A {
  set foo(_) {}
  void foo() {}
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          53,
          3,
          contextMessages: [message(testFile, 36, 3)],
        ),
      ],
    );
  }

  test_instance_setter_setter() async {
    await assertErrorsInCode(
      r'''
class A {}
extension E on A {
  void set foo(_) {}
  void set foo(_) {}
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          62,
          3,
          contextMessages: [message(testFile, 41, 3)],
        ),
      ],
    );
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_instance_setter_setter_augment() async {
    await assertNoErrorsInCode(r'''
extension E on int {
  void set foo(_) {}
}

augment extension E {
  augment void set foo(_) {}
}
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_instance_setter_setter_inAugmentation() async {
    await assertErrorsInCode(
      r'''
extension E on int {
  void set foo(_) {}
}

augment extension E {
  void set foo(_) {}
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          78,
          3,
          contextMessages: [message(testFile, 32, 3)],
        ),
      ],
    );
  }

  test_static_field_field() async {
    await assertErrorsInCode(
      r'''
class A {}
extension E on A {
  static int foo = 0;
  static int foo = 0;
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          65,
          3,
          contextMessages: [message(testFile, 43, 3)],
        ),
      ],
    );
  }

  test_static_field_getter() async {
    await assertErrorsInCode(
      r'''
class A {}
extension E on A {
  static int foo = 0;
  static int get foo => 0;
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          69,
          3,
          contextMessages: [message(testFile, 43, 3)],
        ),
      ],
    );
  }

  test_static_field_method() async {
    await assertErrorsInCode(
      r'''
class A {}
extension E on A {
  static int foo = 0;
  static void foo() {}
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          66,
          3,
          contextMessages: [message(testFile, 43, 3)],
        ),
      ],
    );
  }

  test_static_fieldFinal_getter() async {
    await assertErrorsInCode(
      r'''
class A {}
extension E on A {
  static final int foo = 0;
  static int get foo => 0;
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          75,
          3,
          contextMessages: [message(testFile, 49, 3)],
        ),
      ],
    );
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
    await assertErrorsInCode(
      r'''
class A {}
extension E on A {
  static int get foo => 0;
  static int get foo => 0;
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          74,
          3,
          contextMessages: [message(testFile, 47, 3)],
        ),
      ],
    );
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_static_getter_getter_augment() async {
    await assertNoErrorsInCode(r'''
extension E on int {
  static int get foo => 0;
}

augment extension E {
  augment static int get foo => 0;
}
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_static_getter_getter_inAugmentation() async {
    await assertErrorsInCode(
      r'''
extension E on int {
  static int get foo => 0;
}

augment extension E {
  static int get foo => 0;
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          90,
          3,
          contextMessages: [message(testFile, 38, 3)],
        ),
      ],
    );
  }

  test_static_getter_method() async {
    await assertErrorsInCode(
      r'''
class A {}
extension E on A {
  static int get foo => 0;
  static void foo() {}
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          71,
          3,
          contextMessages: [message(testFile, 47, 3)],
        ),
      ],
    );
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
    await assertErrorsInCode(
      r'''
class A {}
extension E on A {
  static void foo() {}
  static int get foo => 0;
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          70,
          3,
          contextMessages: [message(testFile, 44, 3)],
        ),
      ],
    );
  }

  test_static_method_method() async {
    await assertErrorsInCode(
      r'''
class A {}
extension E on A {
  static void foo() {}
  static void foo() {}
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          67,
          3,
          contextMessages: [message(testFile, 44, 3)],
        ),
      ],
    );
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_static_method_method_augment() async {
    await assertNoErrorsInCode(r'''
extension E on int {
  static void foo() {}
}

augment extension E {
  augment static void foo() {}
}
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_static_method_method_inAugmentation() async {
    await assertErrorsInCode(
      r'''
extension E on int {
  static void foo() {}
}

augment extension E {
  static void foo() {}
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          83,
          3,
          contextMessages: [message(testFile, 35, 3)],
        ),
      ],
    );
  }

  test_static_method_setter() async {
    await assertErrorsInCode(
      r'''
class A {}
extension E on A {
  static void foo() {}
  static set foo(_) {}
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          66,
          3,
          contextMessages: [message(testFile, 44, 3)],
        ),
      ],
    );
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
    await assertErrorsInCode(
      r'''
class A {}
extension E on A {
  static set foo(_) {}
  static void foo() {}
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          67,
          3,
          contextMessages: [message(testFile, 43, 3)],
        ),
      ],
    );
  }

  test_static_setter_setter() async {
    await assertErrorsInCode(
      r'''
class A {}
extension E on A {
  static void set foo(_) {}
  static void set foo(_) {}
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          76,
          3,
          contextMessages: [message(testFile, 48, 3)],
        ),
      ],
    );
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_static_setter_setter_augment() async {
    await assertNoErrorsInCode(r'''
extension E on int {
  static void set foo(_) {}
}

augment extension E {
  augment static void set foo(_) {}
}
''');
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_static_setter_setter_inAugmentation() async {
    await assertErrorsInCode(
      r'''
extension E on int {
  static void set foo(_) {}
}

augment extension E {
  static void set foo(_) {}
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          92,
          3,
          contextMessages: [message(testFile, 39, 3)],
        ),
      ],
    );
  }

  test_unitMembers_extension() async {
    await assertErrorsInCode(
      '''
class A {}
extension E on A {}
extension E on A {}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          41,
          1,
          contextMessages: [message(testFile, 21, 1)],
        ),
      ],
    );
  }
}

@reflectiveTest
class DuplicateDefinitionExtensionTypeTest extends PubPackageResolutionTest {
  test_instance_getter_getter() async {
    await assertErrorsInCode(
      r'''
extension type E(int it) {
  int get foo => 0;
  int get foo => 0;
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          57,
          3,
          contextMessages: [message(testFile, 37, 3)],
        ),
      ],
    );
  }

  test_instance_getter_method() async {
    await assertErrorsInCode(
      r'''
extension type E(int it) {
  int get foo => 0;
  void foo() {}
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          54,
          3,
          contextMessages: [message(testFile, 37, 3)],
        ),
      ],
    );
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
    await assertErrorsInCode(
      r'''
extension type E(int it) {
  void foo() {}
  int get foo => 0;
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          53,
          3,
          contextMessages: [message(testFile, 34, 3)],
        ),
      ],
    );
  }

  test_instance_method_method() async {
    await assertErrorsInCode(
      r'''
extension type E(int it) {
  void foo() {}
  void foo() {}
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          50,
          3,
          contextMessages: [message(testFile, 34, 3)],
        ),
      ],
    );
  }

  test_instance_method_setter() async {
    await assertErrorsInCode(
      r'''
extension type E(int it) {
  void foo() {}
  set foo(_) {}
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          49,
          3,
          contextMessages: [message(testFile, 34, 3)],
        ),
      ],
    );
  }

  test_instance_representation_getter() async {
    await assertErrorsInCode(
      r'''
extension type E(int it) {
  int get it => 0;
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          37,
          2,
          contextMessages: [message(testFile, 21, 2)],
        ),
      ],
    );
  }

  test_instance_representation_method() async {
    await assertErrorsInCode(
      r'''
extension type E(int it) {
  void it() {}
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          34,
          2,
          contextMessages: [message(testFile, 21, 2)],
        ),
      ],
    );
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
    await assertErrorsInCode(
      r'''
extension type E(int it) {
  set foo(_) {}
  void foo() {}
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          50,
          3,
          contextMessages: [message(testFile, 33, 3)],
        ),
      ],
    );
  }

  test_instance_setter_setter() async {
    await assertErrorsInCode(
      r'''
extension type E(int it) {
  void set foo(_) {}
  void set foo(_) {}
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          59,
          3,
          contextMessages: [message(testFile, 38, 3)],
        ),
      ],
    );
  }

  test_static_field_field() async {
    await assertErrorsInCode(
      r'''
extension type E(int it) {
  static int foo = 0;
  static int foo = 0;
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          62,
          3,
          contextMessages: [message(testFile, 40, 3)],
        ),
      ],
    );
  }

  test_static_field_getter() async {
    await assertErrorsInCode(
      r'''
extension type E(int it) {
  static int foo = 0;
  static int get foo => 0;
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          66,
          3,
          contextMessages: [message(testFile, 40, 3)],
        ),
      ],
    );
  }

  test_static_field_method() async {
    await assertErrorsInCode(
      r'''
extension type E(int it) {
  static int foo = 0;
  static void foo() {}
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          63,
          3,
          contextMessages: [message(testFile, 40, 3)],
        ),
      ],
    );
  }

  test_static_fieldFinal_getter() async {
    await assertErrorsInCode(
      r'''
extension type E(int it) {
  static final int foo = 0;
  static int get foo => 0;
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          72,
          3,
          contextMessages: [message(testFile, 46, 3)],
        ),
      ],
    );
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
    await assertErrorsInCode(
      r'''
extension type E(int it) {
  static int get foo => 0;
  static int get foo => 0;
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          71,
          3,
          contextMessages: [message(testFile, 44, 3)],
        ),
      ],
    );
  }

  test_static_getter_method() async {
    await assertErrorsInCode(
      r'''
extension type E(int it) {
  static int get foo => 0;
  static void foo() {}
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          68,
          3,
          contextMessages: [message(testFile, 44, 3)],
        ),
      ],
    );
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
    await assertErrorsInCode(
      r'''
extension type E(int it) {
  static void foo() {}
  static int get foo => 0;
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          67,
          3,
          contextMessages: [message(testFile, 41, 3)],
        ),
      ],
    );
  }

  test_static_method_method() async {
    await assertErrorsInCode(
      r'''
extension type E(int it) {
  static void foo() {}
  static void foo() {}
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          64,
          3,
          contextMessages: [message(testFile, 41, 3)],
        ),
      ],
    );
  }

  test_static_method_setter() async {
    await assertErrorsInCode(
      r'''
extension type E(int it) {
  static void foo() {}
  static set foo(_) {}
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          63,
          3,
          contextMessages: [message(testFile, 41, 3)],
        ),
      ],
    );
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
    await assertErrorsInCode(
      r'''
extension type E(int it) {
  static set foo(_) {}
  static void foo() {}
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          64,
          3,
          contextMessages: [message(testFile, 40, 3)],
        ),
      ],
    );
  }

  test_static_setter_setter() async {
    await assertErrorsInCode(
      r'''
extension type E(int it) {
  static void set foo(_) {}
  static void set foo(_) {}
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          73,
          3,
          contextMessages: [message(testFile, 45, 3)],
        ),
      ],
    );
  }

  test_unitMembers_extensionType() async {
    await assertErrorsInCode(
      '''
extension type E(int it) {}
extension type E(int it) {}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          43,
          1,
          contextMessages: [message(testFile, 15, 1)],
        ),
      ],
    );
  }
}

@reflectiveTest
class DuplicateDefinitionMixinTest extends PubPackageResolutionTest {
  test_instance_field_field() async {
    await assertErrorsInCode(
      r'''
mixin M {
  int foo = 0;
  int foo = 0;
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          31,
          3,
          contextMessages: [message(testFile, 16, 3)],
        ),
      ],
    );
  }

  test_instance_field_getter() async {
    await assertErrorsInCode(
      r'''
mixin M {
  int foo = 0;
  int get foo => 0;
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          35,
          3,
          contextMessages: [message(testFile, 16, 3)],
        ),
      ],
    );
  }

  test_instance_field_method() async {
    await assertErrorsInCode(
      r'''
mixin M {
  int foo = 0;
  void foo() {}
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          32,
          3,
          contextMessages: [message(testFile, 16, 3)],
        ),
      ],
    );
  }

  test_instance_fieldFinal_getter() async {
    await assertErrorsInCode(
      r'''
mixin M {
  final int foo = 0;
  int get foo => 0;
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          41,
          3,
          contextMessages: [message(testFile, 22, 3)],
        ),
      ],
    );
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
    await assertErrorsInCode(
      r'''
mixin M {
  int get foo => 0;
  int get foo => 0;
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          40,
          3,
          contextMessages: [message(testFile, 20, 3)],
        ),
      ],
    );
  }

  test_instance_getter_method() async {
    await assertErrorsInCode(
      r'''
mixin M {
  int get foo => 0;
  void foo() {}
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          37,
          3,
          contextMessages: [message(testFile, 20, 3)],
        ),
      ],
    );
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
    await assertErrorsInCode(
      r'''
mixin M {
  void foo() {}
  int get foo => 0;
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          36,
          3,
          contextMessages: [message(testFile, 17, 3)],
        ),
      ],
    );
  }

  test_instance_method_method() async {
    await assertErrorsInCode(
      r'''
mixin M {
  void foo() {}
  void foo() {}
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          33,
          3,
          contextMessages: [message(testFile, 17, 3)],
        ),
      ],
    );
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_instance_method_method_augment() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';

augment mixin A {
  augment void foo() {}
}
''');

    newFile(testFile.path, r'''
part 'a.dart';

mixin A {
  void foo() {}
}
''');

    await resolveTestFile();
    assertNoErrorsInResult();

    await resolveFile2(a);
    assertNoErrorsInResult();
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_instance_method_method_inAugmentation() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';

augment mixin A {
  void foo() {}
}
''');

    newFile(testFile.path, r'''
part 'a.dart';

mixin A {
  void foo() {}
}
''');

    await resolveTestFile();
    assertNoErrorsInResult();

    await resolveFile2(a);
    assertErrorsInResult([
      error(
        CompileTimeErrorCode.duplicateDefinition,
        47,
        3,
        contextMessages: [message(testFile, 33, 3)],
      ),
    ]);
  }

  test_instance_method_setter() async {
    await assertErrorsInCode(
      r'''
mixin M {
  void foo() {}
  set foo(_) {}
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          32,
          3,
          contextMessages: [message(testFile, 17, 3)],
        ),
      ],
    );
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
    await assertErrorsInCode(
      r'''
mixin M {
  set foo(_) {}
  void foo() {}
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          33,
          3,
          contextMessages: [message(testFile, 16, 3)],
        ),
      ],
    );
  }

  test_instance_setter_setter() async {
    await assertErrorsInCode(
      r'''
mixin M {
  void set foo(_) {}
  void set foo(_) {}
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          42,
          3,
          contextMessages: [message(testFile, 21, 3)],
        ),
      ],
    );
  }

  test_static_field_field() async {
    await assertErrorsInCode(
      r'''
mixin M {
  static int foo = 0;
  static int foo = 0;
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          45,
          3,
          contextMessages: [message(testFile, 23, 3)],
        ),
      ],
    );
  }

  test_static_field_getter() async {
    await assertErrorsInCode(
      r'''
mixin M {
  static int foo = 0;
  static int get foo => 0;
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          49,
          3,
          contextMessages: [message(testFile, 23, 3)],
        ),
      ],
    );
  }

  test_static_field_method() async {
    await assertErrorsInCode(
      r'''
mixin M {
  static int foo = 0;
  static void foo() {}
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          46,
          3,
          contextMessages: [message(testFile, 23, 3)],
        ),
      ],
    );
  }

  test_static_fieldFinal_getter() async {
    await assertErrorsInCode(
      r'''
mixin M {
  static final int foo = 0;
  static int get foo => 0;
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          55,
          3,
          contextMessages: [message(testFile, 29, 3)],
        ),
      ],
    );
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
    await assertErrorsInCode(
      r'''
mixin M {
  static int get foo => 0;
  static int get foo => 0;
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          54,
          3,
          contextMessages: [message(testFile, 27, 3)],
        ),
      ],
    );
  }

  test_static_getter_method() async {
    await assertErrorsInCode(
      r'''
mixin M {
  static int get foo => 0;
  static void foo() {}
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          51,
          3,
          contextMessages: [message(testFile, 27, 3)],
        ),
      ],
    );
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
    await assertErrorsInCode(
      r'''
mixin M {
  static void foo() {}
  static int get foo => 0;
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          50,
          3,
          contextMessages: [message(testFile, 24, 3)],
        ),
      ],
    );
  }

  test_static_method_method() async {
    await assertErrorsInCode(
      r'''
mixin M {
  static void foo() {}
  static void foo() {}
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          47,
          3,
          contextMessages: [message(testFile, 24, 3)],
        ),
      ],
    );
  }

  test_static_method_setter() async {
    await assertErrorsInCode(
      r'''
mixin M {
  static void foo() {}
  static set foo(_) {}
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          46,
          3,
          contextMessages: [message(testFile, 24, 3)],
        ),
      ],
    );
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
    await assertErrorsInCode(
      r'''
mixin M {
  static set foo(_) {}
  static void foo() {}
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          47,
          3,
          contextMessages: [message(testFile, 23, 3)],
        ),
      ],
    );
  }

  test_static_setter_setter() async {
    await assertErrorsInCode(
      r'''
mixin M {
  static void set foo(_) {}
  static void set foo(_) {}
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          56,
          3,
          contextMessages: [message(testFile, 28, 3)],
        ),
      ],
    );
  }
}

@reflectiveTest
class DuplicateDefinitionTest extends PubPackageResolutionTest {
  test_block_localFunction_wildcard() async {
    await assertErrorsInCode(
      r'''
void f() {
  void _() {}
  int _(int _) => 42;
  String _(int _) => "42";
}
''',
      [
        error(WarningCode.deadCode, 13, 11),
        error(WarningCode.deadCode, 27, 19),
        error(WarningCode.deadCode, 49, 24),
      ],
    );
  }

  test_block_localFunction_wildcard_preWildcards() async {
    await assertErrorsInCode(
      r'''
// @dart = 3.4
// (pre wildcard-variables)

void f() {
  void _() {}
  int _(int _) => 42;
  String _(int _) => "42";
}
''',
      [
        error(WarningCode.unusedElement, 62, 1),
        error(
          CompileTimeErrorCode.duplicateDefinition,
          75,
          1,
          contextMessages: [message(testFile, 62, 1)],
        ),
        error(WarningCode.unusedElement, 75, 1),
        error(
          CompileTimeErrorCode.duplicateDefinition,
          100,
          1,
          contextMessages: [message(testFile, 62, 1)],
        ),
        error(WarningCode.unusedElement, 100, 1),
      ],
    );
  }

  test_block_localVariable_localVariable() async {
    await assertErrorsInCode(
      r'''
void f() {
  var a = 0;
  var a = 1;
}
''',
      [
        error(WarningCode.unusedLocalVariable, 17, 1),
        error(WarningCode.unusedLocalVariable, 30, 1),
        error(
          CompileTimeErrorCode.duplicateDefinition,
          30,
          1,
          contextMessages: [message(testFile, 17, 1)],
        ),
      ],
    );
  }

  test_block_localVariable_localVariable_wildcard() async {
    await assertNoErrorsInCode(r'''
void f() {
  var _ = 0;
  var _ = 1;
}
''');
  }

  test_block_localVariable_localVariable_wildcard_preWildcards() async {
    await assertErrorsInCode(
      r'''
// @dart = 3.4
// (pre wildcard-variables)

void f() {
  var _ = 0;
  var _ = 1;
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          74,
          1,
          contextMessages: [message(testFile, 61, 1)],
        ),
      ],
    );
  }

  test_block_localVariable_patternVariable() async {
    await assertErrorsInCode(
      r'''
void f() {
  var a = 0;
  var (a) = 1;
}
''',
      [
        error(WarningCode.unusedLocalVariable, 17, 1),
        error(
          CompileTimeErrorCode.duplicateDefinition,
          31,
          1,
          contextMessages: [message(testFile, 17, 1)],
        ),
        error(WarningCode.unusedLocalVariable, 31, 1),
      ],
    );
  }

  test_block_localVariable_patternVariable_wildcard() async {
    await assertNoErrorsInCode(r'''
void f() {
  var _ = 0;
  var (_) = 1;
}
''');
  }

  test_block_localVariable_patternVariable_wildcard_preWildcards() async {
    await assertNoErrorsInCode(r'''
// @dart = 3.4
// (pre wildcard-variables)

void f() {
  var _ = 0;
  var (_) = 1;
}
''');
  }

  test_block_patternVariable_localVariable() async {
    await assertErrorsInCode(
      r'''
void f() {
  var (a) = 1;
  var a = 0;
}
''',
      [
        error(WarningCode.unusedLocalVariable, 18, 1),
        error(
          CompileTimeErrorCode.duplicateDefinition,
          32,
          1,
          contextMessages: [message(testFile, 18, 1)],
        ),
        error(WarningCode.unusedLocalVariable, 32, 1),
      ],
    );
  }

  test_block_patternVariable_patternVariable() async {
    await assertErrorsInCode(
      r'''
void f() {
  var (a) = 0;
  var (a) = 1;
}
''',
      [
        error(WarningCode.unusedLocalVariable, 18, 1),
        error(
          CompileTimeErrorCode.duplicateDefinition,
          33,
          1,
          contextMessages: [message(testFile, 18, 1)],
        ),
        error(WarningCode.unusedLocalVariable, 33, 1),
      ],
    );
  }

  test_catch() async {
    await assertErrorsInCode(
      r'''
main() {
  try {} catch (e, e) {}
}''',
      [
        error(WarningCode.unusedCatchStack, 28, 1),
        error(
          CompileTimeErrorCode.duplicateDefinition,
          28,
          1,
          contextMessages: [message(testFile, 25, 1)],
        ),
      ],
    );
  }

  test_catch_wildcard() async {
    await assertNoErrorsInCode(r'''
f() {
  try {} catch (_, _) {}
}''');
  }

  test_catch_wildcard_preWildCards() async {
    await assertErrorsInCode(
      r'''
// @dart = 3.4
// (pre wildcard-variables)

f() {
  try {} catch (_, _) {}
}''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          69,
          1,
          contextMessages: [message(testFile, 66, 1)],
        ),
      ],
    );
  }

  test_emptyName() async {
    // Note: This code has two FunctionElements '() {}' with an empty name; this
    // tests that the empty string is not put into the scope (more than once).
    await assertErrorsInCode(
      r'''
Map _globalMap = {
  'a' : () {},
  'b' : () {}
};
''',
      [error(WarningCode.unusedElement, 4, 10)],
    );
  }

  test_for_initializers() async {
    await assertErrorsInCode(
      r'''
f() {
  for (int i = 0, i = 0; i < 5;) {}
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          24,
          1,
          contextMessages: [message(testFile, 17, 1)],
        ),
        error(WarningCode.unusedLocalVariable, 24, 1),
      ],
    );
  }

  test_for_initializers_wildcard() async {
    await assertNoErrorsInCode(r'''
f() {
  for (int _ = 0, _ = 0; ;) {}
}
''');
  }

  test_for_initializers_wildcard_preWildcards() async {
    await assertErrorsInCode(
      r'''
// @dart = 3.4
// (pre wildcard-variables)

f() {
  for (int _ = 0, _ = 0; ;) {}
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          68,
          1,
          contextMessages: [message(testFile, 61, 1)],
        ),
      ],
    );
  }

  test_getter_single() async {
    await assertNoErrorsInCode('''
bool get a => true;
''');
  }

  test_parameters_constructor_field_first() async {
    await assertErrorsInCode(
      r'''
class A {
  int? a;
  A(this.a, int a);
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          36,
          1,
          contextMessages: [message(testFile, 29, 1)],
        ),
      ],
    );
  }

  test_parameters_constructor_field_first_wildcard() async {
    await assertErrorsInCode(
      r'''
class A {
  int? _;
  A(this._, int _);
}
''',
      [error(WarningCode.unusedField, 17, 1)],
    );
  }

  test_parameters_constructor_field_first_wildcard_preWildcards() async {
    await assertErrorsInCode(
      r'''
// @dart = 3.4
// (pre wildcard-variables)

class A {
  int? _;
  A(this._, int _);
}
''',
      [
        error(WarningCode.unusedField, 61, 1),
        error(
          CompileTimeErrorCode.duplicateDefinition,
          80,
          1,
          contextMessages: [message(testFile, 73, 1)],
        ),
      ],
    );
  }

  test_parameters_constructor_field_second() async {
    await assertErrorsInCode(
      r'''
class A {
  int? a;
  A(int a, this.a);
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          36,
          1,
          contextMessages: [message(testFile, 28, 1)],
        ),
      ],
    );
  }

  test_parameters_constructor_field_second_wildcard() async {
    await assertErrorsInCode(
      r'''
class A {
  int? _;
  A(int _, this._);
}
''',
      [error(WarningCode.unusedField, 17, 1)],
    );
  }

  test_parameters_constructor_field_second_wildcard_preWildcards() async {
    await assertErrorsInCode(
      r'''
// @dart = 3.4
// (pre wildcard-variables)

class A {
  int? _;
  A(int _, this._);
}
''',
      [
        error(WarningCode.unusedField, 61, 1),
        error(
          CompileTimeErrorCode.duplicateDefinition,
          80,
          1,
          contextMessages: [message(testFile, 72, 1)],
        ),
      ],
    );
  }

  test_parameters_constructor_super_first_wildcard() async {
    await assertErrorsInCode(
      r'''
class A {
  int? _;
  A(this._);
}
class B extends A {
  B(super._, super._);
}
''',
      [
        error(WarningCode.unusedField, 17, 1),
        error(
          CompileTimeErrorCode.superFormalParameterWithoutAssociatedPositional,
          74,
          1,
        ),
      ],
    );
  }

  test_parameters_constructor_super_first_wildcard_preWildcards() async {
    await assertErrorsInCode(
      r'''
// @dart = 3.4
// (pre wildcard-variables)

class A {
  int? _;
  A(this._);
}
class B extends A {
  B(super._, super._);
}
''',
      [
        error(WarningCode.unusedField, 61, 1),
        error(
          CompileTimeErrorCode.duplicateDefinition,
          118,
          1,
          contextMessages: [message(testFile, 109, 1)],
        ),
        error(
          CompileTimeErrorCode.superFormalParameterWithoutAssociatedPositional,
          118,
          1,
        ),
      ],
    );
  }

  test_parameters_constructor_this_super_wildcard() async {
    await assertErrorsInCode(
      r'''
class A {
  final int x, y;
  A(this.x, [this.y = 0]);
}

class C extends A {
  final int _;

  C(this._, super._, [super._]);
}
''',
      [error(WarningCode.unusedField, 90, 1)],
    );
  }

  test_parameters_functionTypeAlias() async {
    await assertErrorsInCode(
      r'''
typedef void F(int a, double a);
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          29,
          1,
          contextMessages: [message(testFile, 19, 1)],
        ),
      ],
    );
  }

  test_parameters_functionTypeAlias_wildcard() async {
    await assertNoErrorsInCode(r'''
typedef void F(int _, double _);
''');
  }

  test_parameters_functionTypeAlias_wildcard_preWildcards() async {
    await assertErrorsInCode(
      r'''
// @dart = 3.4
// (pre wildcard-variables)

typedef void F(int _, double _);
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          73,
          1,
          contextMessages: [message(testFile, 63, 1)],
        ),
      ],
    );
  }

  test_parameters_genericFunction() async {
    await assertErrorsInCode(
      r'''
typedef F = void Function(int a, double a);
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          40,
          1,
          contextMessages: [message(testFile, 30, 1)],
        ),
      ],
    );
  }

  test_parameters_genericFunction_wildcard() async {
    await assertNoErrorsInCode(r'''
typedef F = void Function(int _, double _);
''');
  }

  test_parameters_genericFunction_wildcard_preWildcards() async {
    await assertErrorsInCode(
      r'''
// @dart = 3.4
// (pre wildcard-variables)

typedef F = void Function(int _, double _);
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          84,
          1,
          contextMessages: [message(testFile, 74, 1)],
        ),
      ],
    );
  }

  test_parameters_localFunction() async {
    await assertErrorsInCode(
      r'''
main() {
  f(int a, double a) {
  };
}
''',
      [
        error(WarningCode.unusedElement, 11, 1),
        error(
          CompileTimeErrorCode.duplicateDefinition,
          27,
          1,
          contextMessages: [message(testFile, 17, 1)],
        ),
      ],
    );
  }

  test_parameters_localFunction_wildcard() async {
    await assertErrorsInCode(
      r'''
f() {
  g(int _, double _) {};
}
''',
      [error(WarningCode.unusedElement, 8, 1)],
    );
  }

  test_parameters_localFunction_wildcard_preWildcards() async {
    await assertErrorsInCode(
      r'''
// @dart = 3.4
// (pre wildcard-variables)

f() {
  g(int _, double _) {};
}
''',
      [
        error(WarningCode.unusedElement, 52, 1),
        error(
          CompileTimeErrorCode.duplicateDefinition,
          68,
          1,
          contextMessages: [message(testFile, 58, 1)],
        ),
      ],
    );
  }

  test_parameters_method() async {
    await assertErrorsInCode(
      r'''
class A {
  m(int a, double a) {
  }
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          28,
          1,
          contextMessages: [message(testFile, 18, 1)],
        ),
      ],
    );
  }

  test_parameters_method_wildcard() async {
    await assertNoErrorsInCode(r'''
class A {
  m(int _, double _) {
  }
}
''');
  }

  test_parameters_method_wildcard_preWildcards() async {
    await assertErrorsInCode(
      r'''
// @dart = 3.4
// (pre wildcard-variables)

class A {
  m(int _, double _) {
  }
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          72,
          1,
          contextMessages: [message(testFile, 62, 1)],
        ),
      ],
    );
  }

  test_parameters_topLevelFunction() async {
    await assertErrorsInCode(
      r'''
f(int a, double a) {}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          16,
          1,
          contextMessages: [message(testFile, 6, 1)],
        ),
      ],
    );
  }

  test_parameters_topLevelFunction_synthetic() async {
    await assertErrorsInCode(
      r'''
f(,[]) {}
''',
      [
        error(ParserErrorCode.missingIdentifier, 2, 1),
        error(ParserErrorCode.missingIdentifier, 4, 1),
      ],
    );
  }

  test_parameters_topLevelFunction_wildcard() async {
    await assertNoErrorsInCode(r'''
f(int _, double _) {}
''');
  }

  test_parameters_topLevelFunction_wildcard_preWildcards() async {
    await assertErrorsInCode(
      r'''
// @dart = 3.4
// (pre wildcard-variables)

f(int _, double _) {}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          60,
          1,
          contextMessages: [message(testFile, 50, 1)],
        ),
      ],
    );
  }

  test_switchCase_localVariable_localVariable() async {
    await assertErrorsInCode(
      r'''
// @dart = 2.19
void f() {
  switch (0) {
    case 0:
      var a;
      var a;
  }
}
''',
      [
        error(WarningCode.unusedLocalVariable, 64, 1),
        error(
          CompileTimeErrorCode.duplicateDefinition,
          77,
          1,
          contextMessages: [message(testFile, 64, 1)],
        ),
        error(WarningCode.unusedLocalVariable, 77, 1),
      ],
    );
  }

  test_switchDefault_localVariable_localVariable() async {
    await assertErrorsInCode(
      r'''
void f() {
  switch (0) {
    default:
      var a;
      var a;
  }
}
''',
      [
        error(WarningCode.unusedLocalVariable, 49, 1),
        error(
          CompileTimeErrorCode.duplicateDefinition,
          62,
          1,
          contextMessages: [message(testFile, 49, 1)],
        ),
        error(WarningCode.unusedLocalVariable, 62, 1),
      ],
    );
  }

  test_switchDefault_localVariable_localVariable_preWildcards() async {
    await assertErrorsInCode(
      r'''
// @dart = 3.4
// (pre wildcard-variables)

void f() {
  switch (0) {
    default:
      var _;
      var _;
  }
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          106,
          1,
          contextMessages: [message(testFile, 93, 1)],
        ),
      ],
    );
  }

  test_switchDefault_localVariable_localVariable_wildcard() async {
    await assertNoErrorsInCode(r'''
void f() {
  switch (0) {
    default:
      var _;
      var _;
  }
}
''');
  }

  test_switchPatternCase_localVariable_localVariable() async {
    await assertErrorsInCode(
      r'''
void f() {
  switch (0) {
    case 0:
      var a;
      var a;
  }
}
''',
      [
        error(WarningCode.unusedLocalVariable, 48, 1),
        error(
          CompileTimeErrorCode.duplicateDefinition,
          61,
          1,
          contextMessages: [message(testFile, 48, 1)],
        ),
        error(WarningCode.unusedLocalVariable, 61, 1),
      ],
    );
  }

  test_switchPatternCase_localVariable_localVariable_wildcard() async {
    await assertNoErrorsInCode(r'''
void f() {
  switch (0) {
    case 0:
      var _;
      var _;
  }
}
''');
  }

  test_switchPatternCase_localVariable_localVariable_wildcard_preWildCards() async {
    await assertErrorsInCode(
      r'''
// @dart = 3.4
// (pre wildcard-variables)

void f() {
  switch (0) {
    case 0:
      var _;
      var _;
  }
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          105,
          1,
          contextMessages: [message(testFile, 92, 1)],
        ),
      ],
    );
  }

  test_topLevel_field_field() async {
    await assertErrorsInCode(
      r'''
var f = 1;
var f = 2;
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          15,
          1,
          contextMessages: [message(testFile, 4, 1)],
        ),
      ],
    );
  }

  test_topLevel_field_getter() async {
    await assertErrorsInCode(
      r'''
int f = 1;
int get f => 7;
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          19,
          1,
          contextMessages: [message(testFile, 4, 1)],
        ),
      ],
    );
  }

  test_topLevel_field_setter() async {
    await assertErrorsInCode(
      r'''
int f = 1;
set f(int value) {}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          15,
          1,
          contextMessages: [message(testFile, 4, 1)],
        ),
      ],
    );
  }

  test_topLevel_fieldConst_setter() async {
    await assertNoErrorsInCode(r'''
const f = 0;
set f(_) {}
''');
  }

  test_topLevel_fieldFinal_setter() async {
    await assertNoErrorsInCode(r'''
final f = 1;
set f(int value) {}
''');
  }

  test_topLevel_fieldLateFinalInitializer_setter() async {
    await assertNoErrorsInCode(r'''
late final f = 1;
set f(int value) {}
''');
  }

  test_topLevel_fieldLateFinalNoInitializer_setter() async {
    await assertErrorsInCode(
      r'''
late final f;
set f(int value) {}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          18,
          1,
          contextMessages: [message(testFile, 11, 1)],
        ),
      ],
    );
  }

  test_topLevel_setter_setter() async {
    await assertErrorsInCode(
      r'''
set f(int value) {}
set f(int value) {}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          24,
          1,
          contextMessages: [message(testFile, 4, 1)],
        ),
      ],
    );
  }

  test_topLevel_setter_setter_inPart() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
set f(int value) {}
''');

    await assertNoErrorsInCode(r'''
part 'a.dart';
set f(int value) {}
''');

    await assertErrorsInFile2(a, [
      error(
        CompileTimeErrorCode.duplicateDefinition,
        25,
        1,
        contextMessages: [message(testFile, 19, 1)],
      ),
    ]);
  }

  test_typeParameters_class() async {
    await assertErrorsInCode(
      r'''
class A<T, T> {}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          11,
          1,
          contextMessages: [message(testFile, 8, 1)],
        ),
      ],
    );
  }

  test_typeParameters_class_wildcard() async {
    await assertNoErrorsInCode(r'''
class A<_, _> {}
''');
  }

  test_typeParameters_class_wildcard_preWildcards() async {
    await assertErrorsInCode(
      r'''
// @dart = 3.4
// (pre wildcard-variables)

class A<_, _> {}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          55,
          1,
          contextMessages: [message(testFile, 52, 1)],
        ),
      ],
    );
  }

  test_typeParameters_functionTypeAlias() async {
    await assertErrorsInCode(
      r'''
typedef void F<T, T>();
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          18,
          1,
          contextMessages: [message(testFile, 15, 1)],
        ),
      ],
    );
  }

  test_typeParameters_functionTypeAlias_wildcard() async {
    await assertNoErrorsInCode(r'''
typedef void F<_, _>();
''');
  }

  test_typeParameters_functionTypeAlias_wildcard_preWildcards() async {
    await assertErrorsInCode(
      r'''
// @dart = 3.4
// (pre wildcard-variables)

typedef void F<_, _>();
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          62,
          1,
          contextMessages: [message(testFile, 59, 1)],
        ),
      ],
    );
  }

  test_typeParameters_genericFunction() async {
    await assertErrorsInCode(
      r'''
typedef F = void Function<T, T>();
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          29,
          1,
          contextMessages: [message(testFile, 26, 1)],
        ),
      ],
    );
  }

  test_typeParameters_genericFunction_wildcard() async {
    await assertNoErrorsInCode(r'''
typedef F = void Function<_, _>();
''');
  }

  test_typeParameters_genericFunction_wildcard_preWildcards() async {
    await assertErrorsInCode(
      r'''
// @dart = 3.4
// (pre wildcard-variables)

typedef F = void Function<_, _>();
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          73,
          1,
          contextMessages: [message(testFile, 70, 1)],
        ),
      ],
    );
  }

  test_typeParameters_genericTypedef_functionType() async {
    await assertErrorsInCode(
      r'''
typedef F<T, T> = void Function();
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          13,
          1,
          contextMessages: [message(testFile, 10, 1)],
        ),
      ],
    );
  }

  test_typeParameters_genericTypedef_functionType_wildcard() async {
    await assertNoErrorsInCode(r'''
typedef F<_, _> = void Function();
''');
  }

  test_typeParameters_genericTypedef_functionType_wildcard_preWildcards() async {
    await assertErrorsInCode(
      r'''
// @dart = 3.4
// (pre wildcard-variables)

typedef F<_, _> = void Function();
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          57,
          1,
          contextMessages: [message(testFile, 54, 1)],
        ),
      ],
    );
  }

  test_typeParameters_genericTypedef_interfaceType() async {
    await assertErrorsInCode(
      r'''
typedef F<T, T> = Map;
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          13,
          1,
          contextMessages: [message(testFile, 10, 1)],
        ),
      ],
    );
  }

  test_typeParameters_genericTypedef_interfaceType_wildcard() async {
    await assertNoErrorsInCode(r'''
typedef F<_, _> = Map;
''');
  }

  test_typeParameters_genericTypedef_interfaceType_wildcard_preWildcards() async {
    await assertErrorsInCode(
      r'''
// @dart = 3.4
// (pre wildcard-variables)

typedef F<_, _> = Map;
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          57,
          1,
          contextMessages: [message(testFile, 54, 1)],
        ),
      ],
    );
  }

  test_typeParameters_method() async {
    await assertErrorsInCode(
      r'''
class A {
  void m<T, T>() {}
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          22,
          1,
          contextMessages: [message(testFile, 19, 1)],
        ),
      ],
    );
  }

  test_typeParameters_method_wildcard() async {
    await assertNoErrorsInCode(r'''
class A {
  void m<_, _>() {}
}
''');
  }

  test_typeParameters_method_wildcard_preWildcards() async {
    await assertErrorsInCode(
      r'''
// @dart = 3.4
// (pre wildcard-variables)

class A {
  void m<_, _>() {}
}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          66,
          1,
          contextMessages: [message(testFile, 63, 1)],
        ),
      ],
    );
  }

  test_typeParameters_topLevelFunction() async {
    await assertErrorsInCode(
      r'''
void f<T, T>() {}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          10,
          1,
          contextMessages: [message(testFile, 7, 1)],
        ),
      ],
    );
  }

  test_typeParameters_topLevelFunction_wildcard() async {
    await assertNoErrorsInCode(r'''
void f<_, _>() {}
''');
  }

  test_typeParameters_topLevelFunction_wildcard_preWildcards() async {
    await assertErrorsInCode(
      r'''
// @dart = 3.4
// (pre wildcard-variables)

void f<_, _>() {}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          54,
          1,
          contextMessages: [message(testFile, 51, 1)],
        ),
      ],
    );
  }
}

@reflectiveTest
class DuplicateDefinitionUnitTest extends PubPackageResolutionTest {
  test_class() async {
    await assertErrorsInCode(
      '''
class A {}
class B {}
class A {}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          28,
          1,
          contextMessages: [message(testFile, 6, 1)],
        ),
      ],
    );
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_class_augmentation() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';

augment class A {}
''');

    newFile(testFile.path, r'''
part 'a.dart';

class A {}
''');

    await resolveTestFile();
    assertNoErrorsInResult();

    await resolveFile2(a);
    assertNoErrorsInResult();
  }

  test_class_library_part() async {
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
    GatheringDiagnosticListener()
      ..addAll(aResult.diagnostics)
      ..assertErrors([
        error(
          CompileTimeErrorCode.duplicateDefinition,
          27,
          1,
          contextMessages: [message(lib, 22, 1)],
        ),
      ]);
  }

  test_class_part_part() async {
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
    GatheringDiagnosticListener()
      ..addAll(aResult.diagnostics)
      ..assertNoErrors();

    var bResult = await resolveFile(b);
    GatheringDiagnosticListener()
      ..addAll(bResult.diagnostics)
      ..assertErrors([
        error(
          CompileTimeErrorCode.duplicateDefinition,
          27,
          1,
          contextMessages: [message(a, 27, 1)],
        ),
      ]);
  }

  test_extension() async {
    await assertErrorsInCode(
      '''
extension A on int {}
extension B on int {}
extension A on int {}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          54,
          1,
          contextMessages: [message(testFile, 10, 1)],
        ),
      ],
    );
  }

  test_extension_library_part() async {
    var lib = newFile('$testPackageLibPath/lib.dart', '''
part 'a.dart';

extension A on int {}
''');

    var a = newFile('$testPackageLibPath/a.dart', '''
part of 'lib.dart';

extension A on int {}
''');

    await resolveFile(lib);

    var aResult = await resolveFile(a);
    GatheringDiagnosticListener()
      ..addAll(aResult.diagnostics)
      ..assertErrors([
        error(
          CompileTimeErrorCode.duplicateDefinition,
          31,
          1,
          contextMessages: [message(lib, 26, 1)],
        ),
      ]);
  }

  test_extensionType() async {
    await assertErrorsInCode(
      '''
extension type A(int it) {}
extension type B(int it) {}
extension type A(int it) {}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          71,
          1,
          contextMessages: [message(testFile, 15, 1)],
        ),
      ],
    );
  }

  test_extensionType_library_part() async {
    var lib = newFile('$testPackageLibPath/lib.dart', '''
part 'a.dart';

extension type A(int it) {}
''');

    var a = newFile('$testPackageLibPath/a.dart', '''
part of 'lib.dart';

extension type A(int it) {}
''');

    await resolveFile(lib);

    var aResult = await resolveFile(a);
    GatheringDiagnosticListener()
      ..addAll(aResult.diagnostics)
      ..assertErrors([
        error(
          CompileTimeErrorCode.duplicateDefinition,
          36,
          1,
          contextMessages: [message(lib, 31, 1)],
        ),
      ]);
  }

  test_mixin() async {
    await assertErrorsInCode(
      '''
mixin A {}
mixin B {}
mixin A {}
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          28,
          1,
          contextMessages: [message(testFile, 6, 1)],
        ),
      ],
    );
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_mixin_augmentation() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';

augment mixin A {}
''');

    newFile(testFile.path, r'''
part 'a.dart';

mixin A {}
''');

    await resolveTestFile();
    assertNoErrorsInResult();

    await resolveFile2(a);
    assertNoErrorsInResult();
  }

  test_mixin_library_part() async {
    var lib = newFile('$testPackageLibPath/lib.dart', '''
part 'a.dart';

mixin A {}
''');

    var a = newFile('$testPackageLibPath/a.dart', '''
part of 'lib.dart';

mixin A {}
''');

    await resolveFile(lib);

    var aResult = await resolveFile(a);
    GatheringDiagnosticListener()
      ..addAll(aResult.diagnostics)
      ..assertErrors([
        error(
          CompileTimeErrorCode.duplicateDefinition,
          27,
          1,
          contextMessages: [message(lib, 22, 1)],
        ),
      ]);
  }

  test_typedef_interfaceType() async {
    await assertErrorsInCode(
      '''
typedef A = List<int>;
typedef A = List<int>;
''',
      [
        error(
          CompileTimeErrorCode.duplicateDefinition,
          31,
          1,
          contextMessages: [message(testFile, 8, 1)],
        ),
      ],
    );
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_variable_variable_augment() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';

augment int foo = 42;
''');

    newFile(testFile.path, r'''
part 'a.dart';

int foo = 0;
''');

    await resolveTestFile();
    assertNoErrorsInResult();

    await resolveFile2(a);
    assertNoErrorsInResult();
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_variable_variable_inAugmentation() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';

int foo = 42;
''');

    newFile(testFile.path, r'''
part 'a.dart';

int foo = 0;
''');

    await resolveTestFile();
    assertNoErrorsInResult();

    await resolveFile2(a);
    assertErrorsInResult([
      error(
        CompileTimeErrorCode.duplicateDefinition,
        26,
        3,
        contextMessages: [message(testFile, 20, 3)],
      ),
    ]);
  }
}
