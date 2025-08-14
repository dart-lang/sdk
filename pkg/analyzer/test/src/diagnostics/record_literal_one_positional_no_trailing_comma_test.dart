// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RecordLiteralOnePositionalNoTrailingCommaTest);
  });
}

@reflectiveTest
class RecordLiteralOnePositionalNoTrailingCommaTest
    extends PubPackageResolutionTest {
  test_argument_invalid() async {
    await assertErrorsInCode(
      '''
void f((int,) i) {
  f((''));
}
''',
      [error(CompileTimeErrorCode.argumentTypeNotAssignable, 24, 2)],
    );
  }

  test_argument_notParenthesized() async {
    await assertErrorsInCode(
      '''
void f((int,) i) {
  f(1);
}
''',
      [error(CompileTimeErrorCode.argumentTypeNotAssignable, 23, 1)],
    );
  }

  test_argument_parenthesized() async {
    await assertErrorsInCode(
      '''
void f((int,) i) {
  f((1));
}
''',
      [
        error(
          CompileTimeErrorCode.recordLiteralOnePositionalNoTrailingComma,
          23,
          3,
        ),
      ],
    );
  }

  test_argument_valid() async {
    await assertNoErrorsInCode('''
void f((int,) i) {
  f((1,));
}
''');
  }

  test_assignment_invalid() async {
    await assertErrorsInCode(
      '''
void f((int,) r) {
  r = ('');
}
''',
      [error(CompileTimeErrorCode.invalidAssignment, 25, 4)],
    );
  }

  test_assignment_notParenthesized() async {
    await assertErrorsInCode(
      '''
void f((int,) r) {
  r = 1;
}
''',
      [error(CompileTimeErrorCode.invalidAssignment, 25, 1)],
    );
  }

  test_assignment_parenthesized() async {
    await assertErrorsInCode(
      '''
void f((int,) r) {
  r = (1);
}
''',
      [
        error(
          CompileTimeErrorCode.recordLiteralOnePositionalNoTrailingComma,
          25,
          3,
        ),
      ],
    );
  }

  test_assignment_valid() async {
    await assertNoErrorsInCode('''
void f((int,) r) {
  r = (1,);
}
''');
  }

  test_declaration() async {
    await assertErrorsInCode(
      '''
(int,) r = (1);
''',
      [
        error(
          CompileTimeErrorCode.recordLiteralOnePositionalNoTrailingComma,
          11,
          3,
        ),
      ],
    );
  }

  test_declaration_invalid() async {
    await assertErrorsInCode(
      '''
(int,) r = ('');
''',
      [error(CompileTimeErrorCode.invalidAssignment, 12, 2)],
    );
  }

  test_declaration_valid() async {
    await assertNoErrorsInCode('''
(int,) r = (1,);
''');
  }

  test_return_blockBody_notParenthesized() async {
    await assertErrorsInCode(
      '''
(int,) f() {
  return 1;
}
''',
      [error(CompileTimeErrorCode.returnOfInvalidTypeFromFunction, 22, 1)],
    );
  }

  test_return_blockBody_parenthesized() async {
    await assertErrorsInCode(
      '''
(int,) f() {
  return (1);
}
''',
      [
        error(
          CompileTimeErrorCode.recordLiteralOnePositionalNoTrailingComma,
          22,
          3,
        ),
      ],
    );
  }

  test_return_expressionBody_invalid() async {
    await assertErrorsInCode(
      '''
(int,) f() => ('');
''',
      [error(CompileTimeErrorCode.returnOfInvalidTypeFromFunction, 14, 4)],
    );
  }

  test_return_expressionBody_notParenthesized() async {
    await assertErrorsInCode(
      '''
(int,) f() => 1;
''',
      [error(CompileTimeErrorCode.returnOfInvalidTypeFromFunction, 14, 1)],
    );
  }

  test_return_expressionBody_parenthesized() async {
    await assertErrorsInCode(
      '''
(int,) f() => (1);
''',
      [
        error(
          CompileTimeErrorCode.recordLiteralOnePositionalNoTrailingComma,
          14,
          3,
        ),
      ],
    );
  }

  test_return_invalid() async {
    await assertErrorsInCode(
      '''
(int,) f() { return (''); }
''',
      [error(CompileTimeErrorCode.returnOfInvalidTypeFromFunction, 20, 4)],
    );
  }

  test_return_valid() async {
    await assertNoErrorsInCode('''
(int,) f() { return (1,); }
''');
  }
}
