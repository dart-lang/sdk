// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(WrongNumberOfParametersForOperatorTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class WrongNumberOfParametersForOperatorTest extends PubPackageResolutionTest {
  test_ampersand_none() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator &() {}
//         ^
// [diag.wrongNumberOfParametersForOperator] Operator '&' should declare exactly 1 parameters, but 0 found.
}
''');
  }

  test_ampersand_rP() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator &(a) {}
}
''');
  }

  test_ampersand_rP_rn() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator &(a, {b}) {}
//         ^
// [diag.wrongNumberOfParametersForOperator] Operator '&' should declare exactly 1 parameters, but 2 found.
}
''');
  }

  test_ampersand_rP_rP() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator &(a, b) {}
//         ^
// [diag.wrongNumberOfParametersForOperator] Operator '&' should declare exactly 1 parameters, but 2 found.
}
''');
  }

  test_ampersand_rP_rp() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator &(a, [b]) {}
//         ^
// [diag.wrongNumberOfParametersForOperator] Operator '&' should declare exactly 1 parameters, but 2 found.
}
''');
  }

  test_caret_none() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator ^() {}
//         ^
// [diag.wrongNumberOfParametersForOperator] Operator '^' should declare exactly 1 parameters, but 0 found.
}
''');
  }

  test_caret_rP() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator ^(a) {}
}
''');
  }

  test_caret_rP_rn() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator ^(a, {b}) {}
//         ^
// [diag.wrongNumberOfParametersForOperator] Operator '^' should declare exactly 1 parameters, but 2 found.
}
''');
  }

  test_caret_rP_rP() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator ^(a, b) {}
//         ^
// [diag.wrongNumberOfParametersForOperator] Operator '^' should declare exactly 1 parameters, but 2 found.
}
''');
  }

  test_caret_rP_rp() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator ^(a, [b]) {}
//         ^
// [diag.wrongNumberOfParametersForOperator] Operator '^' should declare exactly 1 parameters, but 2 found.
}
''');
  }

  test_greater_none() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator >() {}
//         ^
// [diag.wrongNumberOfParametersForOperator] Operator '>' should declare exactly 1 parameters, but 0 found.
}
''');
  }

  test_greater_rP() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator >(a) {}
}
''');
  }

  test_greater_rP_rn() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator >(a, {b}) {}
//         ^
// [diag.wrongNumberOfParametersForOperator] Operator '>' should declare exactly 1 parameters, but 2 found.
}
''');
  }

  test_greater_rP_rP() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator >(a, b) {}
//         ^
// [diag.wrongNumberOfParametersForOperator] Operator '>' should declare exactly 1 parameters, but 2 found.
}
''');
  }

  test_greater_rP_rp() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator >(a, [b]) {}
//         ^
// [diag.wrongNumberOfParametersForOperator] Operator '>' should declare exactly 1 parameters, but 2 found.
}
''');
  }

  test_greaterEqual_none() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator >=() {}
//         ^^
// [diag.wrongNumberOfParametersForOperator] Operator '>=' should declare exactly 1 parameters, but 0 found.
}
''');
  }

  test_greaterEqual_rP() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator >=(a) {}
}
''');
  }

  test_greaterEqual_rP_rn() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator >=(a, {b}) {}
//         ^^
// [diag.wrongNumberOfParametersForOperator] Operator '>=' should declare exactly 1 parameters, but 2 found.
}
''');
  }

  test_greaterEqual_rP_rP() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator >=(a, b) {}
//         ^^
// [diag.wrongNumberOfParametersForOperator] Operator '>=' should declare exactly 1 parameters, but 2 found.
}
''');
  }

  test_greaterEqual_rP_rp() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator >=(a, [b]) {}
//         ^^
// [diag.wrongNumberOfParametersForOperator] Operator '>=' should declare exactly 1 parameters, but 2 found.
}
''');
  }

  test_index_none() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator []() {}
//         ^^
// [diag.wrongNumberOfParametersForOperator] Operator '[]' should declare exactly 1 parameters, but 0 found.
}
''');
  }

  test_index_rP() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator [](a) {}
}
''');
  }

  test_index_rP_rn() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator [](a, {b}) {}
//         ^^
// [diag.wrongNumberOfParametersForOperator] Operator '[]' should declare exactly 1 parameters, but 2 found.
}
''');
  }

  test_index_rP_rP() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator [](a, b) {}
//         ^^
// [diag.wrongNumberOfParametersForOperator] Operator '[]' should declare exactly 1 parameters, but 2 found.
}
''');
  }

  test_index_rP_rp() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator [](a, [b]) {}
//         ^^
// [diag.wrongNumberOfParametersForOperator] Operator '[]' should declare exactly 1 parameters, but 2 found.
}
''');
  }

  test_indexEq_none() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator []=() {}
//         ^^^
// [diag.wrongNumberOfParametersForOperator] Operator '[]=' should declare exactly 2 parameters, but 0 found.
}
''');
  }

  test_indexEq_rP() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator []=(a) {}
//         ^^^
// [diag.wrongNumberOfParametersForOperator] Operator '[]=' should declare exactly 2 parameters, but 1 found.
}
''');
  }

  test_indexEq_rP_rP() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator []=(a, b) {}
}
''');
  }

  test_indexEq_rP_rP_rn() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator []=(a, b, {c}) {}
//         ^^^
// [diag.wrongNumberOfParametersForOperator] Operator '[]=' should declare exactly 2 parameters, but 3 found.
}
''');
  }

  test_indexEq_rP_rP_rP() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator []=(a, b, c) {}
//         ^^^
// [diag.wrongNumberOfParametersForOperator] Operator '[]=' should declare exactly 2 parameters, but 3 found.
}
''');
  }

  test_indexEq_rP_rP_rp() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator []=(a, b, [c]) {}
//         ^^^
// [diag.wrongNumberOfParametersForOperator] Operator '[]=' should declare exactly 2 parameters, but 3 found.
}
''');
  }

  test_less_none() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator <() {}
//         ^
// [diag.wrongNumberOfParametersForOperator] Operator '<' should declare exactly 1 parameters, but 0 found.
}
''');
  }

  test_less_rP() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator <(a) {}
}
''');
  }

  test_less_rP_rn() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator <(a, {b}) {}
//         ^
// [diag.wrongNumberOfParametersForOperator] Operator '<' should declare exactly 1 parameters, but 2 found.
}
''');
  }

  test_less_rP_rP() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator <(a, b) {}
//         ^
// [diag.wrongNumberOfParametersForOperator] Operator '<' should declare exactly 1 parameters, but 2 found.
}
''');
  }

  test_less_rP_rp() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator <(a, [b]) {}
//         ^
// [diag.wrongNumberOfParametersForOperator] Operator '<' should declare exactly 1 parameters, but 2 found.
}
''');
  }

  test_lessEqual_none() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator <=() {}
//         ^^
// [diag.wrongNumberOfParametersForOperator] Operator '<=' should declare exactly 1 parameters, but 0 found.
}
''');
  }

  test_lessEqual_rP() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator <=(a) {}
}
''');
  }

  test_lessEqual_rP_rn() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator <=(a, {b}) {}
//         ^^
// [diag.wrongNumberOfParametersForOperator] Operator '<=' should declare exactly 1 parameters, but 2 found.
}
''');
  }

  test_lessEqual_rP_rP() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator <=(a, b) {}
//         ^^
// [diag.wrongNumberOfParametersForOperator] Operator '<=' should declare exactly 1 parameters, but 2 found.
}
''');
  }

  test_lessEqual_rP_rp() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator <=(a, [b]) {}
//         ^^
// [diag.wrongNumberOfParametersForOperator] Operator '<=' should declare exactly 1 parameters, but 2 found.
}
''');
  }

  test_minus_none() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator -() {}
}
''');
  }

  test_minus_rP() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator -(a) {}
}
''');
  }

  test_minus_rP_rP() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator -(a, b) {}
//         ^
// [diag.wrongNumberOfParametersForOperatorMinus] Operator '-' should declare 0 or 1 parameter, but 2 found.
}
''');
  }

  test_percent_none() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator %() {}
//         ^
// [diag.wrongNumberOfParametersForOperator] Operator '%' should declare exactly 1 parameters, but 0 found.
}
''');
  }

  test_percent_rP() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator %(a) {}
}
''');
  }

  test_percent_rP_rn() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator %(a, {b}) {}
//         ^
// [diag.wrongNumberOfParametersForOperator] Operator '%' should declare exactly 1 parameters, but 2 found.
}
''');
  }

  test_percent_rP_rP() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator %(a, b) {}
//         ^
// [diag.wrongNumberOfParametersForOperator] Operator '%' should declare exactly 1 parameters, but 2 found.
}
''');
  }

  test_percent_rP_rp() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator %(a, [b]) {}
//         ^
// [diag.wrongNumberOfParametersForOperator] Operator '%' should declare exactly 1 parameters, but 2 found.
}
''');
  }

  test_pipe_none() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator |() {}
//         ^
// [diag.wrongNumberOfParametersForOperator] Operator '|' should declare exactly 1 parameters, but 0 found.
}
''');
  }

  test_pipe_rP() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator |(a) {}
}
''');
  }

  test_pipe_rP_rn() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator |(a, {b}) {}
//         ^
// [diag.wrongNumberOfParametersForOperator] Operator '|' should declare exactly 1 parameters, but 2 found.
}
''');
  }

  test_pipe_rP_rP() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator |(a, b) {}
//         ^
// [diag.wrongNumberOfParametersForOperator] Operator '|' should declare exactly 1 parameters, but 2 found.
}
''');
  }

  test_pipe_rP_rp() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator |(a, [b]) {}
//         ^
// [diag.wrongNumberOfParametersForOperator] Operator '|' should declare exactly 1 parameters, but 2 found.
}
''');
  }

  test_plus_none() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator +() {}
//         ^
// [diag.wrongNumberOfParametersForOperator] Operator '+' should declare exactly 1 parameters, but 0 found.
}
''');
  }

  test_plus_rP() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator +(a) {}
}
''');
  }

  test_plus_rP_rn() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator +(a, {b}) {}
//         ^
// [diag.wrongNumberOfParametersForOperator] Operator '+' should declare exactly 1 parameters, but 2 found.
}
''');
  }

  test_plus_rP_rP() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator +(a, b) {}
//         ^
// [diag.wrongNumberOfParametersForOperator] Operator '+' should declare exactly 1 parameters, but 2 found.
}
''');
  }

  test_plus_rP_rp() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator +(a, [b]) {}
//         ^
// [diag.wrongNumberOfParametersForOperator] Operator '+' should declare exactly 1 parameters, but 2 found.
}
''');
  }

  test_shiftLeft_none() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator <<() {}
//         ^^
// [diag.wrongNumberOfParametersForOperator] Operator '<<' should declare exactly 1 parameters, but 0 found.
}
''');
  }

  test_shiftLeft_rP() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator <<(a) {}
}
''');
  }

  test_shiftLeft_rP_rn() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator <<(a, {b}) {}
//         ^^
// [diag.wrongNumberOfParametersForOperator] Operator '<<' should declare exactly 1 parameters, but 2 found.
}
''');
  }

  test_shiftLeft_rP_rP() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator <<(a, b) {}
//         ^^
// [diag.wrongNumberOfParametersForOperator] Operator '<<' should declare exactly 1 parameters, but 2 found.
}
''');
  }

  test_shiftLeft_rP_rp() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator <<(a, [b]) {}
//         ^^
// [diag.wrongNumberOfParametersForOperator] Operator '<<' should declare exactly 1 parameters, but 2 found.
}
''');
  }

  test_shiftRight_none() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator >>() {}
//         ^^
// [diag.wrongNumberOfParametersForOperator] Operator '>>' should declare exactly 1 parameters, but 0 found.
}
''');
  }

  test_shiftRight_rP() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator >>(a) {}
}
''');
  }

  test_shiftRight_rP_rn() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator >>(a, {b}) {}
//         ^^
// [diag.wrongNumberOfParametersForOperator] Operator '>>' should declare exactly 1 parameters, but 2 found.
}
''');
  }

  test_shiftRight_rP_rP() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator >>(a, b) {}
//         ^^
// [diag.wrongNumberOfParametersForOperator] Operator '>>' should declare exactly 1 parameters, but 2 found.
}
''');
  }

  test_shiftRight_rP_rp() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator >>(a, [b]) {}
//         ^^
// [diag.wrongNumberOfParametersForOperator] Operator '>>' should declare exactly 1 parameters, but 2 found.
}
''');
  }

  test_slash_none() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator /() {}
//         ^
// [diag.wrongNumberOfParametersForOperator] Operator '/' should declare exactly 1 parameters, but 0 found.
}
''');
  }

  test_slash_rP() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator /(a) {}
}
''');
  }

  test_slash_rP_rn() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator /(a, {b}) {}
//         ^
// [diag.wrongNumberOfParametersForOperator] Operator '/' should declare exactly 1 parameters, but 2 found.
}
''');
  }

  test_slash_rP_rP() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator /(a, b) {}
//         ^
// [diag.wrongNumberOfParametersForOperator] Operator '/' should declare exactly 1 parameters, but 2 found.
}
''');
  }

  test_slash_rP_rp() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator /(a, [b]) {}
//         ^
// [diag.wrongNumberOfParametersForOperator] Operator '/' should declare exactly 1 parameters, but 2 found.
}
''');
  }

  test_star_none() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator *() {}
//         ^
// [diag.wrongNumberOfParametersForOperator] Operator '*' should declare exactly 1 parameters, but 0 found.
}
''');
  }

  test_star_rP() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator *(a) {}
}
''');
  }

  test_star_rP_rn() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator *(a, {b}) {}
//         ^
// [diag.wrongNumberOfParametersForOperator] Operator '*' should declare exactly 1 parameters, but 2 found.
}
''');
  }

  test_star_rP_rP() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator *(a, b) {}
//         ^
// [diag.wrongNumberOfParametersForOperator] Operator '*' should declare exactly 1 parameters, but 2 found.
}
''');
  }

  test_star_rP_rp() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator *(a, [b]) {}
//         ^
// [diag.wrongNumberOfParametersForOperator] Operator '*' should declare exactly 1 parameters, but 2 found.
}
''');
  }

  test_tilde_rP() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator ~(a) {}
//         ^
// [diag.wrongNumberOfParametersForOperator] Operator '~' should declare exactly 0 parameters, but 1 found.
}
''');
  }

  test_tilde_rP_rn() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator ~(a, {b}) {}
//         ^
// [diag.wrongNumberOfParametersForOperator] Operator '~' should declare exactly 0 parameters, but 2 found.
}
''');
  }

  test_tilde_rP_rP() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator ~(a, b) {}
//         ^
// [diag.wrongNumberOfParametersForOperator] Operator '~' should declare exactly 0 parameters, but 2 found.
}
''');
  }

  test_tilde_rP_rp() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator ~(a, [b]) {}
//         ^
// [diag.wrongNumberOfParametersForOperator] Operator '~' should declare exactly 0 parameters, but 2 found.
}
''');
  }

  test_tildeSlash_none() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator ~/() {}
//         ^^
// [diag.wrongNumberOfParametersForOperator] Operator '~/' should declare exactly 1 parameters, but 0 found.
}
''');
  }

  test_tildeSlash_rP() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator ~/(a) {}
}
''');
  }

  test_tildeSlash_rP_rn() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator ~/(a, {b}) {}
//         ^^
// [diag.wrongNumberOfParametersForOperator] Operator '~/' should declare exactly 1 parameters, but 2 found.
}
''');
  }

  test_tildeSlash_rP_rP() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator ~/(a, b) {}
//         ^^
// [diag.wrongNumberOfParametersForOperator] Operator '~/' should declare exactly 1 parameters, but 2 found.
}
''');
  }

  test_tildeSlash_rP_rp() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator ~/(a, [b]) {}
//         ^^
// [diag.wrongNumberOfParametersForOperator] Operator '~/' should declare exactly 1 parameters, but 2 found.
}
''');
  }

  test_tripleShiftRight_none() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator >>>() {}
//         ^^^
// [diag.wrongNumberOfParametersForOperator] Operator '>>>' should declare exactly 1 parameters, but 0 found.
}
''');
  }

  test_tripleShiftRight_rP() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator >>>(a) {}
}
''');
  }

  test_tripleShiftRight_rP_rn() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator >>>(a, {b}) {}
//         ^^^
// [diag.wrongNumberOfParametersForOperator] Operator '>>>' should declare exactly 1 parameters, but 2 found.
}
''');
  }

  test_tripleShiftRight_rP_rP() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator >>>(a, b) {}
//         ^^^
// [diag.wrongNumberOfParametersForOperator] Operator '>>>' should declare exactly 1 parameters, but 2 found.
}
''');
  }

  test_tripleShiftRight_rP_rp() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator >>>(a, [b]) {}
//         ^^^
// [diag.wrongNumberOfParametersForOperator] Operator '>>>' should declare exactly 1 parameters, but 2 found.
}
''');
  }
}
