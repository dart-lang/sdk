// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstEvalPropertyAccessTest);
  });
}

@reflectiveTest
class ConstEvalPropertyAccessTest extends PubPackageResolutionTest {
  test_constructorArgument_rhsOfLogicalOperation() async {
    // Note: prior to the fix for https://github.com/dart-lang/sdk/issues/61761,
    // this caused an exception to be thrown during constant evaluation.
    await assertErrorsInCode(
      r'''
class C {
  final bool x;
  const C(this.x);
}
const C a = C(true);
const C b = C(false || a.x);
''',
      [
        // TODO(paulberry): this error range covers the whole subexpression
        // `false || a.x`. Probably it's better to just cover `a.x`.
        error(diag.constEvalPropertyAccess, 82, 12),
      ],
    );
  }

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
          diag.constEvalPropertyAccess,
          29,
          9,
          contextMessages: [
            contextMessage(
              lib,
              46,
              5,
              textContains: [
                "The error is in the field initializer of 'A', and occurs here.",
              ],
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
      [error(diag.constEvalPropertyAccess, 39, 8)],
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
          diag.constEvalPropertyAccess,
          16,
          31,
          contextMessages: [
            contextMessage(
              testFile,
              138,
              14,
              textContains: [
                "The error is in the assert initializer of 'RequiresNonEmptyList', and occurs here.",
              ],
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
      [error(diag.constEvalPropertyAccess, 59, 11)],
    );
  }

  test_nullAware_isEven_null() async {
    await assertErrorsInCode(
      r'''
const int? s = null;
const bool? c = s?.isEven;''',
      [error(diag.constEvalPropertyAccess, 37, 9)],
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
      [error(diag.constEvalPropertyAccess, 35, 9)],
    );
  }

  test_nullAware_length_string_notNull() async {
    await assertNoErrorsInCode(r'''
const String? s = '';
const int? c = s?.length;''');
  }
}
