// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CastNullableToNonNullableTest);
  });
}

@reflectiveTest
class CastNullableToNonNullableTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.cast_nullable_to_non_nullable;

  test_castDynamic_toNonNullable() async {
    await assertNoDiagnostics(r'''
void f(dynamic a) {
  a as String;
}
''');
  }

  test_castDynamic_toNullable() async {
    await assertNoDiagnostics(r'''
void f(dynamic a) {
  a as String?;
}
''');
  }

  test_castNullable_toNonNullable() async {
    await assertDiagnostics(r'''
String? s;
var a = s as String;
''', [
      lint(19, 11),
    ]);
  }

  test_castNullable_toNullable() async {
    await assertNoDiagnostics(r'''
class A {}
class B extends A {}

void f(A? a) {
  a as B?;
}
''');
  }

  test_castNullable_unresolvedType() async {
    await assertDiagnostics(r'''
Undefined? s;
var a = s! as String;
''', [
      // No lint.
      error(CompileTimeErrorCode.UNDEFINED_CLASS, 0, 9),
    ]);
  }
}
