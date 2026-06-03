// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
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
  test_binaryOperators() async {
    await _checkTooFewAndTooMany('<');
    await _checkTooFewAndTooMany('>');
    await _checkTooFewAndTooMany('<=');
    await _checkTooFewAndTooMany('>=');
    await _checkTooFewAndTooMany('+');
    await _checkTooFewAndTooMany('/');
    await _checkTooFewAndTooMany('~/');
    await _checkTooFewAndTooMany('*');
    await _checkTooFewAndTooMany('%');
    await _checkTooFewAndTooMany('|');
    await _checkTooFewAndTooMany('^');
    await _checkTooFewAndTooMany('&');
    await _checkTooFewAndTooMany('<<');
    await _checkTooFewAndTooMany('>>');
    await _checkTooFewAndTooMany('>>>');
    await _checkTooFewAndTooMany('[]');
  }

  test_correct_number_of_parameters_binary() async {
    await _checkCorrectSingle("<");
    await _checkCorrectSingle(">");
    await _checkCorrectSingle("<=");
    await _checkCorrectSingle(">=");
    await _checkCorrectSingle("+");
    await _checkCorrectSingle("/");
    await _checkCorrectSingle("~/");
    await _checkCorrectSingle("*");
    await _checkCorrectSingle("%");
    await _checkCorrectSingle("|");
    await _checkCorrectSingle("^");
    await _checkCorrectSingle("&");
    await _checkCorrectSingle("<<");
    await _checkCorrectSingle(">>");
    await _checkCorrectSingle(">>>");
    await _checkCorrectSingle("[]");
  }

  test_correct_number_of_parameters_index_assignment() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator []=(a, b) {}
}
''');
  }

  test_correct_number_of_parameters_minus() async {
    await _checkCorrect("-", "");
    await _checkCorrect("-", "a");
  }

  test_unaryMinus() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  operator -(a, b) {}
//         ^
// [diag.wrongNumberOfParametersForOperatorMinus] Operator '-' should declare 0 or 1 parameter, but 2 found.
}
''');
  }

  test_unaryTilde() async {
    await _check('~', 'a');
    await _check('~', 'a, b');
    await _check('~', 'a, [b]');
    await _check('~', 'a, {b}');
  }

  Future<void> _check(String name, String parameters) async {
    await assertErrorsInCode(
      '''
class A {
  operator $name($parameters) {}
}
''',
      [error(diag.wrongNumberOfParametersForOperator, 21, 1)],
    );
  }

  Future<void> _checkCorrect(String name, String parameters) async {
    await resolveTestCodeWithDiagnostics('''
class A {
  operator $name($parameters) {}
}
''');
  }

  Future<void> _checkCorrectSingle(String name) async {
    await _checkCorrect(name, 'a');
  }

  Future<void> _checkTooFewAndTooMany(String name) async {
    await _check(name, '');
    await _check(name, 'a, b');
    await _check(name, 'a, [b]');
    await _check(name, 'a, {b}');
  }
}
