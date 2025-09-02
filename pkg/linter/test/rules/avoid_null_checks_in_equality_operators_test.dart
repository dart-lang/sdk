// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidNullChecksInEqualityOperatorsTest);
  });
}

@reflectiveTest
class AvoidNullChecksInEqualityOperatorsTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.avoid_null_checks_in_equality_operators;

  test_dynamicParameter_neNull() async {
    // https://github.com/dart-lang/linter/issues/2864
    await assertDiagnostics(
      r'''
class C {
  String foo = '';
  @override
  operator ==(dynamic other) {
    return other != null && other is C && foo == other.foo;
  }
}
''',
      [error(WarningCode.nonNullableEqualsParameter, 52, 2)],
    );
  }

  test_dynamicParameter_propertyAccess() async {
    await assertDiagnostics(
      r'''
class C {
  String foo = '';
  @override
  operator ==(dynamic other) => other is C && foo == other.foo;
}
''',
      [error(WarningCode.nonNullableEqualsParameter, 52, 2)],
    );
  }

  test_nonNullableParameter_neNull() async {
    // https://github.com/dart-lang/linter/issues/2864
    await assertDiagnostics(
      r'''
class C {
  String foo = '';
  @override
  operator ==(Object other) {
    return other != null && other is C && foo == other.foo;
  }
}
''',
      [error(WarningCode.unnecessaryNullComparisonNeverNullTrue, 88, 7)],
    );
  }

  test_nullableParameter_eqeqNull_not() async {
    await assertDiagnostics(
      r'''
class C {
  String foo = '';
  @override
  operator ==(Object? other) =>
          !(other == null) && other is C && foo == other.foo;
}
''',
      [error(WarningCode.nonNullableEqualsParameter, 52, 2), lint(85, 13)],
    );
  }

  test_nullableParameter_eqeqNull_not_parens() async {
    await assertDiagnostics(
      r'''
class C {
  String foo = '';
  @override
  operator ==(Object? other) =>
          !((other) == null) && (other) is C && foo == (other.foo);
}
''',
      [error(WarningCode.nonNullableEqualsParameter, 52, 2), lint(85, 15)],
    );
  }

  test_nullableParameter_fieldComparisonOnLocal() async {
    await assertDiagnostics(
      r'''
class C {
  String foo;
  C(this.foo);
  @override
  operator ==(Object? other) {
    if (other is C) {
      var toCompare = other ?? C("");
      return toCompare.foo == foo;
    }
    return false;
  }

}
''',
      [
        error(WarningCode.nonNullableEqualsParameter, 62, 2),
        lint(126, 14),
        error(WarningCode.deadCode, 132, 8),
        error(StaticWarningCode.deadNullAwareExpression, 135, 5),
      ],
    );
  }

  test_nullableParameter_neNull() async {
    await assertDiagnostics(
      r'''
class C {
  String foo = '';
  @override
  operator ==(Object? other) =>
          other != null && other is C && foo == other.foo;
}
''',
      [error(WarningCode.nonNullableEqualsParameter, 52, 2), lint(83, 13)],
    );
  }

  test_nullableParameter_nullAwarePropertyAccess() async {
    await assertDiagnostics(
      r'''
class C {
  String foo = '';
  @override
  operator ==(Object? other) => other is C && foo == other?.foo;
}
''',
      [
        error(WarningCode.nonNullableEqualsParameter, 52, 2),
        lint(94, 10),
        error(StaticWarningCode.invalidNullAwareOperator, 99, 2),
      ],
    );
  }
}
