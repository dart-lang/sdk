// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferFunctionDeclarationsOverVariablesTest);
  });
}

@reflectiveTest
class PreferFunctionDeclarationsOverVariablesTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.prefer_function_declarations_over_variables;

  test_finalField_assignedInConstructor() async {
    await assertNoDiagnostics(r'''
class C {
  final void Function() f;
  C() : f = (() {});
}
''');
  }

  test_finalField_onEnum() async {
    await assertDiagnostics(
      r'''
enum E {
  e;
  final f = () {};
}
''',
      [lint(22, 9)],
    );
  }

  test_finalField_onMixin() async {
    await assertDiagnostics(
      r'''
mixin M {
  final f = () {};
}
''',
      [lint(18, 9)],
    );
  }

  test_finalField_onPrivateClass() async {
    await assertDiagnostics(
      r'''
class _C {
  final f = () {};
}
''',
      [lint(19, 9)],
    );
  }

  test_instanceField_private_final() async {
    await assertDiagnostics(
      r'''
class C {
  final _f = () {};
}
''',
      [lint(18, 10)],
    );
  }

  test_instanceVariable_final() async {
    await assertDiagnostics(
      r'''
class C {
  final f = () {};
}
''',
      [lint(18, 9)],
    );
  }

  test_instanceVariable_public() async {
    await assertNoDiagnostics(r'''
class C {
  var f = () {};
}
''');
  }

  test_localFunction() async {
    await assertNoDiagnostics(r'''
void f() {
  // ignore: unused_element
  g() {}
}
''');
  }

  test_localVariable() async {
    await assertDiagnostics(
      r'''
void f() {
  var g = () {};
}
''',
      [lint(17, 9)],
    );
  }

  test_localVariable_nonFunctionLiteral() async {
    await assertNoDiagnostics(r'''
void f(Function fn) {
  var g = fn;
}
''');
  }

  test_localVariable_reassigned() async {
    await assertNoDiagnostics(r'''
void f() {
  var g = () {};
  g = () {};
}
''');
  }

  test_staticField_final() async {
    await assertDiagnostics(
      r'''
class C {
  static final f = () {};
}
''',
      [lint(25, 9)],
    );
  }

  test_staticField_nonFinal() async {
    await assertNoDiagnostics(r'''
class C {
  static var f = () {};
}
''');
  }

  test_topLevelVariable_final() async {
    await assertDiagnostics(
      r'''
final f = () {};
''',
      [lint(6, 9)],
    );
  }

  test_topLevelVariable_private_final() async {
    await assertDiagnostics(
      r'''
final _f = () {};
''',
      [lint(6, 10)],
    );
  }

  test_topLevelVariable_private_nonFinal() async {
    await assertNoDiagnostics(r'''
var _f = () {};
''');
  }

  test_topLevelVariable_public_nonFinal() async {
    await assertNoDiagnostics(r'''
var f = () {};
''');
  }
}
