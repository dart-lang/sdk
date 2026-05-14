// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RecordLiteralOnePositionalNoTrailingCommaTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class RecordLiteralOnePositionalNoTrailingCommaTest
    extends PubPackageResolutionTest {
  test_argument_invalid() async {
    await resolveTestCodeWithDiagnostics(r'''
void f((int,) i) {
  f((''));
//   ^^
// [diag.argumentTypeNotAssignable] The argument type 'String' can't be assigned to the parameter type '(int,)'.
}
''');
  }

  test_argument_notParenthesized() async {
    await resolveTestCodeWithDiagnostics(r'''
void f((int,) i) {
  f(1);
//  ^
// [diag.argumentTypeNotAssignable] The argument type 'int' can't be assigned to the parameter type '(int,)'.
}
''');
  }

  test_argument_parenthesized() async {
    await resolveTestCodeWithDiagnostics(r'''
void f((int,) i) {
  f((1));
//  ^^^
// [diag.recordLiteralOnePositionalNoTrailingCommaByType] A record literal with exactly one positional field requires a trailing comma.
}
''');
  }

  test_argument_valid() async {
    await resolveTestCodeWithDiagnostics(r'''
void f((int,) i) {
  f((1,));
}
''');
  }

  test_assignment_invalid() async {
    await resolveTestCodeWithDiagnostics(r'''
void f((int,) r) {
  r = ('');
//    ^^^^
// [diag.invalidAssignment] A value of type 'String' can't be assigned to a variable of type '(int,)'.
}
''');
  }

  test_assignment_notParenthesized() async {
    await resolveTestCodeWithDiagnostics(r'''
void f((int,) r) {
  r = 1;
//    ^
// [diag.invalidAssignment] A value of type 'int' can't be assigned to a variable of type '(int,)'.
}
''');
  }

  test_assignment_parenthesized() async {
    await resolveTestCodeWithDiagnostics(r'''
void f((int,) r) {
  r = (1);
//    ^^^
// [diag.recordLiteralOnePositionalNoTrailingCommaByType] A record literal with exactly one positional field requires a trailing comma.
}
''');
  }

  test_assignment_valid() async {
    await resolveTestCodeWithDiagnostics(r'''
void f((int,) r) {
  r = (1,);
}
''');
  }

  test_declaration() async {
    await resolveTestCodeWithDiagnostics(r'''
(int,) r = (1);
//         ^^^
// [diag.recordLiteralOnePositionalNoTrailingCommaByType] A record literal with exactly one positional field requires a trailing comma.
''');
  }

  test_declaration_invalid() async {
    await resolveTestCodeWithDiagnostics(r'''
(int,) r = ('');
//          ^^
// [diag.invalidAssignment] A value of type 'String' can't be assigned to a variable of type '(int,)'.
''');
  }

  test_declaration_valid() async {
    await resolveTestCodeWithDiagnostics(r'''
(int,) r = (1,);
''');
  }

  test_return_blockBody_notParenthesized() async {
    await resolveTestCodeWithDiagnostics(r'''
(int,) f() {
  return 1;
//       ^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'int' can't be returned from the function 'f' because it has a return type of '(int,)'.
}
''');
  }

  test_return_blockBody_parenthesized() async {
    await resolveTestCodeWithDiagnostics(r'''
(int,) f() {
  return (1);
//       ^^^
// [diag.recordLiteralOnePositionalNoTrailingCommaByType] A record literal with exactly one positional field requires a trailing comma.
}
''');
  }

  test_return_expressionBody_invalid() async {
    await resolveTestCodeWithDiagnostics(r'''
(int,) f() => ('');
//            ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'String' can't be returned from the function 'f' because it has a return type of '(int,)'.
''');
  }

  test_return_expressionBody_notParenthesized() async {
    await resolveTestCodeWithDiagnostics(r'''
(int,) f() => 1;
//            ^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'int' can't be returned from the function 'f' because it has a return type of '(int,)'.
''');
  }

  test_return_expressionBody_parenthesized() async {
    await resolveTestCodeWithDiagnostics(r'''
(int,) f() => (1);
//            ^^^
// [diag.recordLiteralOnePositionalNoTrailingCommaByType] A record literal with exactly one positional field requires a trailing comma.
''');
  }

  test_return_invalid() async {
    await resolveTestCodeWithDiagnostics(r'''
(int,) f() { return (''); }
//                  ^^^^
// [diag.returnOfInvalidTypeFromFunction] A value of type 'String' can't be returned from the function 'f' because it has a return type of '(int,)'.
''');
  }

  test_return_valid() async {
    await resolveTestCodeWithDiagnostics(r'''
(int,) f() { return (1,); }
''');
  }
}
