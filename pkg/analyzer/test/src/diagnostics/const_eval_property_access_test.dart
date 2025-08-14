// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/test_support.dart';
import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstEvalPropertyAccessTest);
  });
}

@reflectiveTest
class ConstEvalPropertyAccessTest extends PubPackageResolutionTest {
  test_constructorFieldInitializer_fromSeparateLibrary() async {
    var lib = newFile('$testPackageLibPath/lib.dart', r'''
class A<T> {
  final int f;
  const A() : f = T.foo;
}
''');
    await assertErrorsInCode(
      r'''
import 'lib.dart';
const a = const A();
''',
      [
        error(
          CompileTimeErrorCode.constEvalPropertyAccess,
          29,
          9,
          contextMessages: [
            ExpectedContextMessage(
              lib,
              46,
              5,
              text:
                  "The error is in the field initializer of 'A', and occurs here.",
            ),
          ],
        ),
      ],
    );
  }

  test_length_dynamic_notNull() async {
    await assertNoErrorsInCode(r'''
const dynamic d = 'foo';
const int? c = d.length;''');
  }

  test_length_dynamic_null() async {
    await assertErrorsInCode(
      r'''
const dynamic d = null;
const int? c = d.length;''',
      [error(CompileTimeErrorCode.constEvalPropertyAccess, 39, 8)],
    );
  }

  test_length_invalidTarget() async {
    await assertErrorsInCode(
      '''
void main() {
  const RequiresNonEmptyList([1]);
}

class RequiresNonEmptyList {
  const RequiresNonEmptyList(List<int> numbers) : assert(numbers.length > 0);
}
''',
      [
        error(
          CompileTimeErrorCode.constEvalPropertyAccess,
          16,
          31,
          contextMessages: [
            ExpectedContextMessage(
              testFile,
              138,
              14,
              text:
                  "The error is in the assert initializer of 'RequiresNonEmptyList', and occurs here.",
            ),
          ],
        ),
      ],
    );
  }

  test_nonStaticField_inGenericClass() async {
    await assertErrorsInCode(
      '''
class C<T> {
  const C();
  T? get t => null;
}

const x = const C().t;
''',
      [error(CompileTimeErrorCode.constEvalPropertyAccess, 59, 11)],
    );
  }

  test_nullAware_isEven_null() async {
    await assertErrorsInCode(
      r'''
const int? s = null;
const bool? c = s?.isEven;''',
      [error(CompileTimeErrorCode.constEvalPropertyAccess, 37, 9)],
    );
  }

  test_nullAware_length_dynamic_null() async {
    await assertNoErrorsInCode(r'''
const dynamic d = 'foo';
const int? c = d?.length;''');
  }

  test_nullAware_length_list_notNull() async {
    await assertErrorsInCode(
      r'''
const List? l = [];
const int? c = l?.length;''',
      [error(CompileTimeErrorCode.constEvalPropertyAccess, 35, 9)],
    );
  }

  test_nullAware_length_string_notNull() async {
    await assertNoErrorsInCode(r'''
const String? s = '';
const int? c = s?.length;''');
  }
}
