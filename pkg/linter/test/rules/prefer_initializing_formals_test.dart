// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferInitializingFormalsTest);
    defineReflectiveTests(
      PreferInitializingFormalsWithoutPrivateNamedParametersTest,
    );
  });
}

@reflectiveTest
class PreferInitializingFormalsTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.prefer_initializing_formals;

  test_assignedInBody() async {
    await assertDiagnostics(
      r'''
class C {
  num x = 0;
  C(num x) {
    this.x = x;
  }
}
''',
      [lint(40, 10)],
    );
  }

  test_assignedInBody_alreadyInitializingFormal() async {
    await assertNoDiagnostics(r'''
class C {
  int? x;
  C(this.x) {
    this.x = x;
  }
}
''');
  }

  test_assignedInBody_andHasSuperInitializer() async {
    await assertDiagnostics(
      r'''
class A {
  int a, b;
  A(this.a, this.b);
}
class C extends A {
  int? c, d;
  C(int c, int d) : super(1, 2) {
    this.c = c;
    this.d = d;
  }
}
''',
      [lint(116, 10), lint(132, 10)],
    );
  }

  test_assignedInBody_justSetters() async {
    await assertNoDiagnostics(r'''
class C {
  C(num x, num y) {
    this.x = x;
    this.y = y;
  }
  set x(num value) {}
  set y(num value) {}
}
''');
  }

  test_assignedInBody_multipleReference_body() async {
    await assertNoDiagnostics(r'''
class C {
  num x = 0;
  C(num x) {
    print(x);
    this.x = x;
  }
}
''');
  }

  test_assignedInBody_multipleReference_closure() async {
    await assertNoDiagnostics(r'''
class C {
  int? x;
  Function()? closure;
  C(int? x) {
    closure = () {
      print(x);
    };
    this.x = x;
  }
}
''');
  }

  test_assignedInBody_multipleReference_docComment() async {
    await assertDiagnostics(
      r'''
class C {
  num x = 0;

  /// References to [x] in this doc comment like [x] and [x] are ignored.
  C(num x) {
    this.x = x;
  }
}
''',
      [lint(115, 10)],
    );
  }

  test_assignedInBody_multipleReference_initializer() async {
    await assertNoDiagnostics(r'''
class C {
  num x = 0;
  num y = 0;
  C(num x) : y = x {
    this.x = x;
  }
}
''');
  }

  test_assignedInBody_namedParameters() async {
    await assertDiagnostics(
      r'''
class C {
  num? x, y;
  C({num? x, num y = 1}) {
    this.x = x;
    this.y = y;
  }
}
''',
      [lint(54, 10), lint(70, 10)],
    );
  }

  test_assignedInBody_namedParameters_renamed() async {
    await assertNoDiagnostics(r'''
class C {
  num? x, y;
  C({num? a, num b = 1}) {
    this.x = a;
    this.y = b;
  }
}
''');
  }

  test_assignedInBody_privateToPrivate() async {
    // This code has an error because it's using a private named parameter that
    // doesn't refer to a field. But we still want the lint to fire because the
    // lint can help the user fix that error by turning the parameter into an
    // initializing formal.
    await assertDiagnostics(
      r'''
class C {
  num? _x, _y;
  C(num? _x, {num? _y}) {
    this._x = _x;
    this._y = _y;
  }
}
''',
      [
        error(diag.privateNamedNonFieldParameter, 44, 2),
        // Only the named parameter is linted.
        lint(73, 12),
      ],
    );
  }

  test_assignedInBody_publicToPrivate_positional() async {
    await assertDiagnostics(
      r'''
class C {
  num? _x, _y;
  C(num? x, {num? y}) {
    this._x = x;
    this._y = y;
  }
}
''',
      [
        // Only the named parameter is linted.
        lint(70, 11),
      ],
    );
  }

  test_assignedInBody_publicToPrivateRenamed() async {
    await assertNoDiagnostics(r'''
class C {
  num? _a, _b;
  C(num? x, {num? y}) {
    this._a = x;
    this._b = y;
  }
}
''');
  }

  test_assignedInBody_subsequent() async {
    await assertDiagnostics(
      r'''
class C {
  num x = 0, y = 0;
  C(num x, num y) {
    this.x = x;
    this.y = y;
  }
}
''',
      [lint(54, 10), lint(70, 10)],
    );
  }

  test_assignedInInitializer_alreadyInitializingFormal() async {
    await assertDiagnostics(
      r'''
class C {
  int? x;
  C(this.x)
      : x = x;
}
''',
      [error(diag.fieldInitializedInParameterAndInitializer, 40, 1)],
    );
  }

  test_assignedInInitializer_andHasSuperInitializer() async {
    await assertDiagnostics(
      r'''
class A {
  int a, b;
  A(this.a, this.b);
}
class C extends A {
  int c, d;
  C(int c, int d)
      : this.c = c,
        this.d = d,
        super(1, 2);
}
''',
      [lint(103, 10), lint(123, 10)],
    );
  }

  test_assignedInInitializer_assignmentWithCalculation() async {
    // https://github.com/dart-lang/linter/issues/2605
    await assertNoDiagnostics(r'''
class C {
  final int f;
  C(bool p) : f = p ? 1 : 0;
}
''');
  }

  test_assignedInInitializer_namedParameters() async {
    await assertDiagnostics(
      r'''
class C {
  num? x, y;
  C({num? x, num y = 1})
      : this.x = x,
        this.y = y;
}
''',
      [lint(56, 10), lint(76, 10)],
    );
  }

  test_assignedInInitializer_privateToPrivate() async {
    // This code has an error because it's using a private named parameter that
    // doesn't refer to a field. But we still want the lint to fire because the
    // lint can help the user fix that error by turning the parameter into an
    // initializing formal.
    await assertDiagnostics(
      r'''
class C {
  num? _x, _y;
  C(num? _x, {num? _y}) : _x = _x, _y = _y;
}
''',
      [
        error(diag.privateNamedNonFieldParameter, 44, 2),
        // Only the named parameter is linted.
        lint(60, 7),
      ],
    );
  }

  test_assignedInInitializer_publicToPrivate() async {
    await assertDiagnostics(
      r'''
class C {
  num? _x, _y;
  C(num? x, {num? y}) : _x = x, _y = y;
}
''',
      [
        // Only the named parameter is linted.
        lint(57, 6),
      ],
    );
  }

  test_assignedInInitializer_publicToPrivateRenamed() async {
    await assertNoDiagnostics(r'''
class C {
  num? _a, _b;
  C(num? x, {num? y}) : _a = x, _b = y;
}
''');
  }

  test_assignedInInitializer_renamedParameter() async {
    await assertNoDiagnostics(r'''
class C {
  final int a, b;

  C(this.b) : a = b;
}
''');
  }

  test_assignedInInitializer_renamedToBePrivate() async {
    await assertNoDiagnostics(r'''
class C {
  final num _x, _y;
  C(num x, num y)
      : _x = x,
        _y = y;
}
''');
  }

  test_assignedInInitializer_renamedToBePrivate_explicitThis() async {
    await assertNoDiagnostics(r'''
class C {
  final num _x, _y;
  C(num x, num y)
      : this._x = x,
        this._y = y;
}
''');
  }

  test_assignFieldFromOtherObject() async {
    await assertNoDiagnostics(r'''
class C {
  int? x;
  C(int? x) {
    var other = C(1);
    other.x = x;
  }
}
''');
  }

  test_assignToInheritedField() async {
    await assertNoDiagnostics(r'''
class A {
  int? x;
}
class B extends A {
  B(int? x) {
    this.x = x;
  }
}
''');
  }

  test_assignToStaticField() async {
    await assertNoDiagnostics(r'''
class C {
  static int? x;
  C(int x) {
    C.x = x;
  }
}
''');
  }

  test_dynamicParameterType_dynamicField() async {
    await assertDiagnostics(
      r'''
class C {
  dynamic _x;

  C({dynamic x}) : _x = x;
}
''',
      [lint(44, 6)],
    );
  }

  test_dynamicParameterType_nonTopTypeField() async {
    await assertNoDiagnostics(r'''
class C {
  String? _x;

  C({dynamic x}) : _x = x;
}
''');
  }

  test_dynamicParameterType_objectQuestionField() async {
    await assertDiagnostics(
      r'''
class C {
  Object? _x;

  C({dynamic x}) : _x = x;
}
''',
      [lint(44, 6)],
    );
  }

  test_factoryConstructor() async {
    // https://github.com/dart-lang/linter/issues/2441
    await assertNoDiagnostics(r'''
class C {
  String? x;
  factory C.withX(String? x) {
    var c = C._();
    c.x = x;
    return c;
  }
  C._();
}
''');
  }

  test_fieldFormal() async {
    await assertNoDiagnostics(r'''
class C {
  int x;
  C(this.x);
}
''');
  }

  test_fieldFormal_multiple() async {
    await assertNoDiagnostics(r'''
class C {
  num x, y;
  C(this.x, this.y);
}
''');
  }

  test_implicitParameterType_dynamicField() async {
    await assertDiagnostics(
      r'''
class C {
  dynamic _x;

  C({x}) : _x = x;
}
''',
      [lint(36, 6)],
    );
  }

  test_implicitParameterType_nonTopTypeField() async {
    await assertNoDiagnostics(r'''
class C {
  String? _x;

  C({x}) : _x = x;
}
''');
  }

  test_implicitParameterType_objectQuestionField() async {
    await assertDiagnostics(
      r'''
class C {
  Object? _x;

  C({x}) : _x = x;
}
''',
      [lint(36, 6)],
    );
  }

  test_initializeFromOtherParameter() async {
    await assertNoDiagnostics(r'''
class C {
  int? x;
  C() {
    localFunction(int? x) {
      this.x = x;
    }
  }
}
''');
  }

  test_noLintIfMultiple_initializerAndAssignment() async {
    await assertNoDiagnostics(r'''
class C {
  int? x;
  C({int? x}) : this.x = x {
    this.x = x;
  }
}
''');
  }

  test_noLintIfMultiple_twoAssignments() async {
    await assertNoDiagnostics(r'''
class C {
  int? x;
  C({int? x}) {
    this.x = x;
    this.x = x;
  }
}
''');
  }

  test_noLintIfMultiple_twoInitializers() async {
    await assertDiagnostics(
      r'''
class C {
  int? x;
  C({int? x}) : this.x = x, this.x = x;
}
''',
      [error(diag.fieldInitializedByMultipleInitializers, 53, 1)],
    );
  }

  test_parameter() async {
    await assertNoDiagnostics(r'''
void f(int p) {}
''');
  }

  test_renamedParameter() async {
    // https://github.com/dart-lang/linter/issues/2664
    await assertNoDiagnostics(r'''
class C {
  int? x;
  C(int initialX) : x = initialX;
}
''');
  }
}

@reflectiveTest
class PreferInitializingFormalsWithoutPrivateNamedParametersTest
    extends LintRuleTest {
  @override
  String get lintRule => LintNames.prefer_initializing_formals;

  test_assignedInBody_privateToPrivate() async {
    // This code has an error because it's using a private named parameter that
    // doesn't refer to a field. It's also in a file that can't use a private
    // named parameter so there should be the error but no lint.
    await assertDiagnostics(
      r'''
// @dart=3.10
class C {
  num? _x, _y;
  C(num? _x, {num? _y}) {
    this._x = _x;
    this._y = _y;
  }
}
''',
      [error(diag.privateOptionalParameter, 58, 2)],
    );
  }

  test_assignedInBody_publicToPrivate() async {
    await assertNoDiagnostics(r'''
// @dart=3.10
class C {
  num? _x, _y;
  C(num? x, {num? y}) {
    this._x = x;
    this._y = y;
  }
}
''');
  }

  test_assignedInBody_publicToPrivateRenamed() async {
    await assertNoDiagnostics(r'''
// @dart=3.10
class C {
  num? _a, _b;
  C(num? x, {num? y}) {
    this._a = x;
    this._b = y;
  }
}
''');
  }

  test_assignedInInitializer_privateToPrivate() async {
    // This code has an error because it's using a private named parameter that
    // doesn't refer to a field. It's also in a file that can't use a private
    // named parameter so there should be the error but no lint.
    await assertDiagnostics(
      r'''
// @dart=3.10
class C {
  num? _x, _y;
  C(num? _x, {num? _y}) : _x = _x, _y = _y;
}
''',
      [error(diag.privateOptionalParameter, 58, 2)],
    );
  }

  test_assignedInInitializer_publicToPrivate() async {
    await assertNoDiagnostics(r'''
// @dart=3.10
class C {
  num? _x, _y;
  C(num? x, {num? y}) : _x = x, _y = y;
}
''');
  }

  test_assignedInInitializer_publicToPrivateRenamed() async {
    await assertNoDiagnostics(r'''
// @dart=3.10
class C {
  num? _a, _b;
  C(num? x, {num? y}) : _a = x, _b = y;
}
''');
  }

  test_assignedInInitializer_renamedToBePrivate() async {
    await assertNoDiagnostics(r'''
// @dart=3.10
class C {
  final num _x, _y;
  C(num x, num y)
      : _x = x,
        _y = y;
}
''');
  }

  test_assignedInInitializer_renamedToBePrivate_explicitThis() async {
    await assertNoDiagnostics(r'''
// @dart=3.10
class C {
  final num _x, _y;
  C(num x, num y)
      : this._x = x,
        this._y = y;
}
''');
  }
}
