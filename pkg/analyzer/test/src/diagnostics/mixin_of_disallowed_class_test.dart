// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MixinOfDisallowedClassTest);
  });
}

@reflectiveTest
class MixinOfDisallowedClassTest extends PubPackageResolutionTest {
  test_class_bool() async {
    await assertErrorsInCode(
      '''
class A extends Object with bool {}
''',
      [error(CompileTimeErrorCode.mixinOfDisallowedClass, 28, 4)],
    );
  }

  test_class_double() async {
    await assertErrorsInCode(
      '''
class A extends Object with double {}
''',
      [error(CompileTimeErrorCode.mixinOfDisallowedClass, 28, 6)],
    );
  }

  test_class_FutureOr() async {
    await assertErrorsInCode(
      '''
import 'dart:async';
class A extends Object with FutureOr {}
''',
      [error(CompileTimeErrorCode.mixinOfDisallowedClass, 49, 8)],
    );
  }

  test_class_FutureOr_typeArgument() async {
    await assertErrorsInCode(
      '''
import 'dart:async';
class A extends Object with FutureOr<int> {}
''',
      [error(CompileTimeErrorCode.mixinOfDisallowedClass, 49, 13)],
    );
  }

  test_class_FutureOr_typeVariable() async {
    await assertErrorsInCode(
      '''
import 'dart:async';
class A<T> extends Object with FutureOr<T> {}
''',
      [error(CompileTimeErrorCode.mixinOfDisallowedClass, 52, 11)],
    );
  }

  test_class_int() async {
    await assertErrorsInCode(
      '''
class A extends Object with int {}
''',
      [error(CompileTimeErrorCode.mixinOfDisallowedClass, 28, 3)],
    );
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_class_int_inAugmentation() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
class A {}
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
augment class A with int {}
''');

    await assertErrorsInFile2(a, []);
    await assertErrorsInFile2(b, [
      error(CompileTimeErrorCode.mixinOfDisallowedClass, 39, 3),
    ]);
  }

  test_class_Null() async {
    await assertErrorsInCode(
      '''
class A extends Object with Null {}
''',
      [error(CompileTimeErrorCode.mixinOfDisallowedClass, 28, 4)],
    );
  }

  test_class_num() async {
    await assertErrorsInCode(
      '''
class A extends Object with num {}
''',
      [error(CompileTimeErrorCode.mixinOfDisallowedClass, 28, 3)],
    );
  }

  test_class_Record() async {
    await assertErrorsInCode(
      '''
class A extends Object with Record {}
''',
      [error(CompileTimeErrorCode.mixinOfDisallowedClass, 28, 6)],
    );
  }

  test_class_String() async {
    await assertErrorsInCode(
      '''
class A extends Object with String {}
''',
      [error(CompileTimeErrorCode.mixinOfDisallowedClass, 28, 6)],
    );
  }

  test_classTypeAlias_bool() async {
    await assertErrorsInCode(
      r'''
class A {}
class C = A with bool;
''',
      [error(CompileTimeErrorCode.mixinOfDisallowedClass, 28, 4)],
    );
  }

  test_classTypeAlias_double() async {
    await assertErrorsInCode(
      r'''
class A {}
class C = A with double;
''',
      [error(CompileTimeErrorCode.mixinOfDisallowedClass, 28, 6)],
    );
  }

  test_classTypeAlias_FutureOr() async {
    await assertErrorsInCode(
      r'''
import 'dart:async';
class A {}
class C = A with FutureOr;
''',
      [error(CompileTimeErrorCode.mixinOfDisallowedClass, 49, 8)],
    );
  }

  test_classTypeAlias_int() async {
    await assertErrorsInCode(
      r'''
class A {}
class C = A with int;
''',
      [error(CompileTimeErrorCode.mixinOfDisallowedClass, 28, 3)],
    );
  }

  test_classTypeAlias_Null() async {
    await assertErrorsInCode(
      r'''
class A {}
class C = A with Null;
''',
      [error(CompileTimeErrorCode.mixinOfDisallowedClass, 28, 4)],
    );
  }

  test_classTypeAlias_num() async {
    await assertErrorsInCode(
      r'''
class A {}
class C = A with num;
''',
      [error(CompileTimeErrorCode.mixinOfDisallowedClass, 28, 3)],
    );
  }

  test_classTypeAlias_String() async {
    await assertErrorsInCode(
      r'''
class A {}
class C = A with String;
''',
      [error(CompileTimeErrorCode.mixinOfDisallowedClass, 28, 6)],
    );
  }

  test_classTypeAlias_String_num() async {
    await assertErrorsInCode(
      r'''
class A {}
class C = A with String, num;
''',
      [
        error(CompileTimeErrorCode.mixinOfDisallowedClass, 28, 6),
        error(CompileTimeErrorCode.mixinOfDisallowedClass, 36, 3),
      ],
    );
  }

  test_enum_int() async {
    await assertErrorsInCode(
      '''
enum E with int {
  v
}
''',
      [error(CompileTimeErrorCode.mixinOfDisallowedClass, 12, 3)],
    );
  }

  @SkippedTest() // TODO(scheglov): implement augmentation
  test_enum_int_inAugmentation() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
enum A {v}
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
augment enum A with int {}
''');

    await assertErrorsInFile2(a, []);
    await assertErrorsInFile2(b, [
      error(CompileTimeErrorCode.mixinOfDisallowedClass, 38, 3),
    ]);
  }
}
