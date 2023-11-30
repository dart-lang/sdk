// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidInitToNullTest);
    defineReflectiveTests(AvoidInitToNullSuperFormalsTest);
  });
}

@reflectiveTest
class AvoidInitToNullSuperFormalsTest extends LintRuleTest {
  @override
  String get lintRule => 'avoid_init_to_null';

  test_nullableStringInit() async {
    await assertDiagnostics(r'''
class A {
  String? a;
  A({this.a = null});
}
''', [
      lint(28, 13),
    ]);
  }

  test_superInit_2() async {
    await assertDiagnostics(r'''
class A {
  String? a;
  A({this.a = null});
}
class B extends A {
  B({super.a = null});
}
''', [
      lint(28, 13),
      lint(72, 14),
    ]);
  }

  /// https://github.com/dart-lang/linter/issues/3349
  test_superInit_nolint() async {
    await assertNoDiagnostics(r'''
class A {
  String? a;
  A({this.a = ''});
}

class B extends A {
  B({super.a = null});
}
''');
  }
}

@reflectiveTest
class AvoidInitToNullTest extends LintRuleTest {
  // TODO(pq): mock and add FutureOr examples

  @override
  String get lintRule => 'avoid_init_to_null';

  test_fieldFormalParameter_inferredType() async {
    await assertDiagnostics(r'''
class C {
  int? i;
  C({this.i = null});
}
''', [
      lint(25, 13),
    ]);
  }

  test_instanceField_inferredType_final() async {
    await assertNoDiagnostics(r'''
class C {
  final i = null;
}
''');
  }

  test_instanceField_intType_noInitializer() async {
    await assertNoDiagnostics(r'''
class C {
  int i;
  C(): i = 1;
}
''');
  }

  test_instanceField_nullableIntType() async {
    await assertDiagnostics(r'''
class C {
  int? i = null;
  C(): i = 1;
}
''', [
      lint(17, 8),
    ]);
  }

  test_invalidAssignment_field() async {
    await assertDiagnostics(r'''
class X {
  int x = null;
}
''', [
      // No lint
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 20, 4),
    ]);
  }

  test_invalidAssignment_namedParameter() async {
    await assertDiagnostics(r'''
class X {
  X({int a = null});
}
''', [
      // No lint
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 23, 4),
    ]);
  }

  test_invalidAssignment_namedParameter_fieldFormal() async {
    await assertDiagnostics(r'''
class X {
  int x;
  X({this.x = null});
}
''', [
      // No lint
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 33, 4),
    ]);
  }

  test_invalidAssignment_topLevelVariable() async {
    await assertDiagnostics(r'''
int i = null;
''', [
      // No lint
      error(CompileTimeErrorCode.INVALID_ASSIGNMENT, 8, 4),
    ]);
  }

  test_namedParameter_inferredType() async {
    await assertDiagnostics(r'''
foo({p = null}) {}
''', [
      lint(5, 8),
    ]);
  }

  test_namedParameter_inferredType_defaultValueIsInt() async {
    await assertNoDiagnostics(r'''
foo({p = 1}) {}
''');
  }

  test_namedParameter_inferredType_noDefaultValue() async {
    await assertNoDiagnostics(r'''
foo({p}) {}
''');
  }

  test_namedParameter_inferredType_var() async {
    await assertDiagnostics(r'''
foo({var p = null}) {}
''', [
      lint(5, 12),
    ]);
  }

  test_optionalParameter_inferredType() async {
    await assertDiagnostics(r'''
foo([p = null]) {}
''', [
      lint(5, 8),
    ]);
  }

  test_optionalParameter_inferredType_defaultValueIsInt() async {
    await assertNoDiagnostics(r'''
foo([p = 1]) {}
''');
  }

  test_optionalParameter_inferredType_noDefaultValue() async {
    await assertNoDiagnostics(r'''
foo([p]) {}
''');
  }

  test_optionalParameter_inferredType_var() async {
    await assertDiagnostics(r'''
foo([var p = null]) {}
''', [
      lint(5, 12),
    ]);
  }

  test_staticConstField_inferredType_final() async {
    await assertNoDiagnostics(r'''
class C {
  static const i = null;
}
''');
  }

  test_topLevelVariable_dynamic() async {
    await assertDiagnostics(r'''
dynamic i = null;
''', [
      lint(8, 8),
    ]);
  }

  test_topLevelVariable_inferredType() async {
    await assertDiagnostics(r'''
var i = null;
''', [
      lint(4, 8),
    ]);
  }

  test_topLevelVariable_inferredType_const() async {
    await assertNoDiagnostics(r'''
const i = null;
''');
  }

  test_topLevelVariable_inferredType_final() async {
    await assertNoDiagnostics(r'''
final i = null;
''');
  }

  test_topLevelVariable_inferredType_initializeToInt() async {
    await assertNoDiagnostics(r'''
var i = 1;
''');
  }

  test_topLevelVariable_inferredType_noInitialization() async {
    await assertNoDiagnostics(r'''
var i;
''');
  }

  test_topLevelVariable_nullableType() async {
    await assertDiagnostics(r'''
int? ii = null;
''', [
      lint(5, 9),
    ]);
  }
}
