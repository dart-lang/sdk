// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidCasePatternsTestLanguage219);
  });
}

@reflectiveTest
class InvalidCasePatternsTestLanguage219 extends LintRuleTest
    with LanguageVersion219Mixin {
  @override
  String get lintRule => LintNames.invalid_case_patterns;

  test_binaryExpression_logicalAnd() async {
    await assertDiagnosticsFromMarkup(r'''
f(bool b) {
  switch (b) {
    case [!true && false!]:
  }
}
''');
  }

  test_binaryExpression_plus() async {
    await assertDiagnosticsFromMarkup(r'''
void f(Object o) {
  switch (o) {
    case [!1 + 2!]:
  }
}
''');
  }

  test_conditionalExpression() async {
    await assertDiagnostics(
      r'''
void f(Object o) {
  switch (o) {
    case true ? 1 : 2:
  }
}
''',
      [lint(43, 12), error(diag.deadCode, 54, 1)],
    );
  }

  test_constConstructorCall() async {
    await assertDiagnosticsFromMarkup(r'''
class C {
  const C();
}

f(C c) {
  switch (c) {
    case [!C()!]:
  }
}
''');
  }

  test_constConstructorCall_explicitConst_ok() async {
    await assertNoDiagnostics(r'''
class C {
  const C();
}
f(C c) {
  switch (c) {
    case const C():
  }
}
''');
  }

  test_identicalCall() async {
    await assertDiagnosticsFromMarkup(r'''
void f(Object o) {
  switch (o) {
    case [!identical(1, 2)!]:
  }
}
''');
  }

  test_isExpression() async {
    await assertDiagnostics(
      r'''
void f(Object o) {
  switch (o) {
    case 1 is int:
  }
}
''',
      [error(diag.unnecessaryTypeCheckTrue, 43, 8), lint(43, 8)],
    );
  }

  test_isNotExpression() async {
    await assertDiagnostics(
      r'''
void f(Object o) {
  switch (o) {
    case 1 is! int:
  }
}
''',
      [error(diag.unnecessaryTypeCheckFalse, 43, 9), lint(43, 9)],
    );
  }

  test_lengthCall() async {
    await assertDiagnosticsFromMarkup(r'''
void f(Object o) {
  switch (o) {
    case [!''.length!]:
  }
}
''');
  }

  test_listLiteral() async {
    await assertDiagnosticsFromMarkup(r'''
void f(Object o) {
  switch (o) {
    case [![1, 2]!]:
  }
}
''');
  }

  test_listLiteral_ok() async {
    await assertNoDiagnostics(r'''
void f(Object o) {
  switch (o) {
    case const [1, 2]:
  }
}
''');
  }

  test_listLiteral_typeArgs() async {
    await assertDiagnosticsFromMarkup(r'''
void f(Object o) {
  switch (o) {
    case [!<int>[1, 2]!]:
  }
}
''');
  }

  test_mapLiteral() async {
    await assertDiagnosticsFromMarkup(r'''
void f(Object o) {
  switch (o) {
   case [!{'k': 'v'}!]:
  }
}
''');
  }

  test_mapLiteral_ok() async {
    await assertNoDiagnostics(r'''
void f(Object o) {
  switch (o) {
   case const {'k': 'v'}:
  }
}
''');
  }

  test_mapLiteral_parenthesized() async {
    await assertDiagnosticsFromMarkup(r'''
void f(Object o) {
  switch (o) {
   case ([!{'k': 'v'}!]):
  }
}
''');
  }

  test_mapLiteral_parenthesized_twice() async {
    await assertDiagnosticsFromMarkup(r'''
void f(Object o) {
  switch (o) {
   case (([!{'k': 'v'}!])):
  }
}
''');
  }

  test_mapLiteral_typeArgs() async {
    await assertDiagnosticsFromMarkup(r'''
void f(Object o) {
  switch (o) {
   case [!<String,String>{'k': 'v'}!]:
  }
}
''');
  }

  test_parenthesizedExpression_ok() async {
    await assertNoDiagnostics(r'''
void f(Object o) {
  switch (o) {
    case (1):
  }
}
''');
  }

  test_prefixedExpression_intLiteral_ok() async {
    await assertNoDiagnostics(r'''
void f(Object o) {
  switch (o) {
    case -1:
  }
}
''');
  }

  test_setLiteral() async {
    await assertDiagnosticsFromMarkup(r'''
void f(Object o) {
  switch (o) {
    case [!{1}!]:
  }
}
''');
  }

  test_setLiteral_ok() async {
    await assertNoDiagnostics(r'''
void f(Object o) {
  switch (o) {
    case const {1}:
  }
}
''');
  }

  test_setLiteral_typeArgs() async {
    await assertDiagnosticsFromMarkup(r'''
void f(Object o) {
  switch (o) {
    case [!<int>{1}!]:
  }
}
''');
  }

  test_unaryOperator_minus() async {
    await assertDiagnosticsFromMarkup(r'''
void f() {
  const o = 1;
  switch (1) {
    case [!-o!]:
  }
}
''');
  }

  test_unaryOperator_not() async {
    await assertDiagnosticsFromMarkup(r'''
  void f() {
    const b = false;
    switch (true) {
      case [!!b!]:
    }
  }
''');
  }

  test_wildcard() async {
    await assertDiagnosticsFromMarkup(r'''
f(int n) {
  const _ = 3;
  switch (n) {
    case [!_!]:
  }
}
''');
  }
}
