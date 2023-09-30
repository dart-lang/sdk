// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonExhaustiveSwitchExpressionTest);
    defineReflectiveTests(NonExhaustiveSwitchStatementTest);
  });
}

@reflectiveTest
class NonExhaustiveSwitchExpressionTest extends PubPackageResolutionTest {
  test_bool_true() async {
    await assertErrorsInCode(r'''
Object f(bool x) {
  return switch (x) {
    true => 0,
  };
}
''', [
      error(CompileTimeErrorCode.NON_EXHAUSTIVE_SWITCH_EXPRESSION, 28, 6),
    ]);
  }

  test_bool_true_false() async {
    await assertNoErrorsInCode(r'''
Object f(bool x) {
  return switch (x) {
    true => 1,
    false => 0,
  };
}
''');
  }

  test_class_int_wildcard() async {
    await assertNoErrorsInCode(r'''
Object f(int x) {
  return switch (x) {
    0 => 0,
    _ => 1,
  };
}
''');
  }

  test_class_withField_wildcard() async {
    await assertNoErrorsInCode(r'''
Object f(int x) {
  return switch (x) {
    int(isEven: true) => 0,
    _ => 1,
  };
}
''');
  }

  test_enum_2at2_hasWhen() async {
    await assertErrorsInCode(r'''
enum E {
  a, b
}

Object f(E x) {
  return switch (x) {
    E.a when 1 == 0 => 0,
    E.b => 1,
  };
}
''', [
      error(CompileTimeErrorCode.NON_EXHAUSTIVE_SWITCH_EXPRESSION, 44, 6,
          correctionContains: 'E.a'),
    ]);
  }

  test_invalidType_empty() async {
    await assertErrorsInCode(r'''
void f(Unresolved x) => switch (x) {};
''', [
      error(CompileTimeErrorCode.UNDEFINED_CLASS, 7, 10),
    ]);
  }
}

@reflectiveTest
class NonExhaustiveSwitchStatementTest extends PubPackageResolutionTest {
  test_alwaysExhaustive_bool_true() async {
    await assertErrorsInCode(r'''
void f(bool x) {
  switch (x) {
    case true:
      break;
  }
}
''', [
      error(CompileTimeErrorCode.NON_EXHAUSTIVE_SWITCH_STATEMENT, 19, 6),
    ]);
  }

  test_alwaysExhaustive_bool_true_false() async {
    await assertNoErrorsInCode(r'''
void f(bool x) {
  switch (x) {
    case true:
    case false:
      break;
  }
}
''');
  }

  test_alwaysExhaustive_bool_wildcard_typed_bool() async {
    await assertNoErrorsInCode(r'''
void f(bool x) {
  switch (x) {
    case bool _:
      break;
  }
}
''');
  }

  test_alwaysExhaustive_bool_wildcard_typed_int() async {
    await assertErrorsInCode(r'''
void f(bool x) {
  switch (x) {
    case int _:
      break;
  }
}
''', [
      error(CompileTimeErrorCode.NON_EXHAUSTIVE_SWITCH_STATEMENT, 19, 6),
      error(WarningCode.PATTERN_NEVER_MATCHES_VALUE_TYPE, 41, 3),
    ]);
  }

  test_alwaysExhaustive_bool_wildcard_untyped() async {
    await assertNoErrorsInCode(r'''
void f(bool x) {
  switch (x) {
    case _:
      break;
  }
}
''');
  }

  test_alwaysExhaustive_boolNullable_true_false() async {
    await assertErrorsInCode(r'''
void f(bool? x) {
  switch (x) {
    case true:
    case false:
      break;
  }
}
''', [
      error(CompileTimeErrorCode.NON_EXHAUSTIVE_SWITCH_STATEMENT, 20, 6),
    ]);
  }

  test_alwaysExhaustive_boolNullable_true_false_null() async {
    await assertNoErrorsInCode(r'''
void f(bool? x) {
  switch (x) {
    case true:
    case false:
    case null:
      break;
  }
}
''');
  }

  test_alwaysExhaustive_enum_2at1() async {
    await assertErrorsInCode(r'''
enum E {
  a, b
}

void f(E x) {
  switch (x) {
    case E.a:
      break;
  }
}
''', [
      error(CompileTimeErrorCode.NON_EXHAUSTIVE_SWITCH_STATEMENT, 35, 6),
    ]);
  }

  test_alwaysExhaustive_enum_2at2_cases() async {
    await assertNoErrorsInCode(r'''
enum E {
  a, b
}

void f(E x) {
  switch (x) {
    case E.a:
    case E.b:
      break;
  }
}
''');
  }

  test_alwaysExhaustive_enum_2at2_hasWhen() async {
    await assertErrorsInCode(r'''
enum E {
  a, b
}

void f(E x) {
  switch (x) {
    case E.a when 1 == 0:
    case E.b:
      break;
  }
}
''', [
      error(CompileTimeErrorCode.NON_EXHAUSTIVE_SWITCH_STATEMENT, 35, 6,
          correctionContains: 'E.a'),
    ]);
  }

  test_alwaysExhaustive_enum_2at2_logicalOr() async {
    await assertNoErrorsInCode(
      r'''
enum E {
  a, b
}

void f(E x) {
  switch (x) {
    case E.a || E.b:
      break;
  }
}
''',
    );
  }

  test_alwaysExhaustive_enum_cannotCompute() async {
    await assertErrorsInCode(r'''
enum E {
  v1(v2), v2(v1);
  const E(Object f);
}

void f(E x) {
  switch (x) {
    case E.v1:
    case E.v2:
      break;
  }
}
''', [
      error(CompileTimeErrorCode.RECURSIVE_COMPILE_TIME_CONSTANT, 11, 2),
      error(CompileTimeErrorCode.RECURSIVE_COMPILE_TIME_CONSTANT, 19, 2),
    ]);
  }

  test_alwaysExhaustive_Null_hasError() async {
    await assertErrorsInCode(r'''
void f(Null x) {
  switch (x) {}
}
''', [
      error(CompileTimeErrorCode.NON_EXHAUSTIVE_SWITCH_STATEMENT, 19, 6),
    ]);
  }

  test_alwaysExhaustive_Null_noError() async {
    await assertNoErrorsInCode(r'''
void f(Null x) {
  switch (x) {
    case null:
      break;
  }
}
''');
  }

  test_alwaysExhaustive_recordType_bool_bool_4at4() async {
    await assertNoErrorsInCode(r'''
void f((bool, bool) x) {
  switch (x) {
    case (false, false):
    case (false, true):
    case (true, false):
    case (true, true):
      break;
  }
}
''');
  }

  test_alwaysExhaustive_sealedClass_2at1() async {
    await assertErrorsInCode(r'''
sealed class A {}
class B extends A {}
class C extends A {}

void f(A x) {
  switch (x) {
    case B():
      break;
  }
}
''', [
      error(CompileTimeErrorCode.NON_EXHAUSTIVE_SWITCH_STATEMENT, 77, 6),
    ]);
  }

  test_alwaysExhaustive_sealedClass_2at2() async {
    await assertNoErrorsInCode(r'''
sealed class A {}
class B extends A {}
class C extends A {}

void f(A x) {
  switch (x) {
    case B():
      break;
    case C():
      break;
  }
}
''');
  }

  test_alwaysExhaustive_sealedClass_2at2_wildcard() async {
    await assertNoErrorsInCode(r'''
sealed class A {}
class B extends A {}
class C extends A {}

void f(A x) {
  switch (x) {
    case B():
      break;
    case _:
      break;
  }
}
''');
  }

  test_alwaysExhaustive_sealedClass_constraintsMixin() async {
    await assertErrorsInCode(r'''
sealed class A {}

class B extends A {}

mixin M on A {}

void f(A x) {
  switch (x) {
    case B _:
      break;
  }
}
''', [
      error(CompileTimeErrorCode.NON_EXHAUSTIVE_SWITCH_STATEMENT, 74, 6),
    ]);
  }

  test_alwaysExhaustive_sealedClass_implementedByEnum_3at2() async {
    await assertErrorsInCode(r'''
sealed class A {}

class B implements A {}

enum E implements A {
  a, b
}

void f(A x) {
  switch (x) {
    case B _:
    case E.a:
      break;
  }
}
''', [
      error(CompileTimeErrorCode.NON_EXHAUSTIVE_SWITCH_STATEMENT, 92, 6),
    ]);
  }

  test_alwaysExhaustive_sealedClass_implementedByEnum_3at3() async {
    await assertNoErrorsInCode(r'''
sealed class A {}

class B implements A {}

enum E implements A {
  a, b
}

void f(A x) {
  switch (x) {
    case B _:
    case E.a:
    case E.b:
      break;
  }
}
''');
  }

  test_alwaysExhaustive_sealedClass_implementedByMixin_2at1() async {
    await assertErrorsInCode(r'''
sealed class A {}

class B implements A {}

mixin M implements A {}

void f(A x) {
  switch (x) {
    case B _:
      break;
  }
}
''', [
      error(CompileTimeErrorCode.NON_EXHAUSTIVE_SWITCH_STATEMENT, 85, 6),
    ]);
  }

  test_alwaysExhaustive_sealedClass_implementedByMixin_2at2() async {
    await assertNoErrorsInCode(r'''
sealed class A {}

class B implements A {}

mixin M implements A {}

void f(A x) {
  switch (x) {
    case B _:
    case M _:
      break;
  }
}
''');
  }

  test_alwaysExhaustive_sealedClass_unresolvedIdentifier() async {
    await assertErrorsInCode(r'''
sealed class A {}
class B extends A {}

void f(A x) {
  switch (x) {
    case unresolved:
      break;
  }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 78, 10),
    ]);
  }

  test_alwaysExhaustive_sealedClass_unresolvedObject() async {
    await assertErrorsInCode(r'''
sealed class A {}
class B extends A {}

void f(A x) {
  switch (x) {
    case Unresolved():
      break;
  }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_CLASS, 78, 10),
    ]);
  }

  test_alwaysExhaustive_typeVariable_bound_bool_true() async {
    await assertErrorsInCode(r'''
void f<T extends bool>(T x) {
  switch (x) {
    case true:
      break;
  }
}
''', [
      error(CompileTimeErrorCode.NON_EXHAUSTIVE_SWITCH_STATEMENT, 32, 6),
    ]);
  }

  test_alwaysExhaustive_typeVariable_bound_bool_true_false() async {
    await assertNoErrorsInCode(r'''
void f<T extends bool>(T x) {
  switch (x) {
    case true:
    case false:
      break;
  }
}
''');
  }

  test_alwaysExhaustive_typeVariable_promoted_bool_true() async {
    await assertErrorsInCode(r'''
void f<T>(T x) {
  if (x is bool) {
    switch (x) {
      case true:
        break;
    }
  }
}
''', [
      error(CompileTimeErrorCode.NON_EXHAUSTIVE_SWITCH_STATEMENT, 40, 6),
    ]);
  }

  test_alwaysExhaustive_typeVariable_promoted_bool_true_false() async {
    await assertNoErrorsInCode(r'''
void f<T>(T x) {
  if (x is bool) {
    switch (x) {
      case true:
      case false:
        break;
    }
  }
}
''');
  }

  test_invalidType_empty() async {
    await assertErrorsInCode(r'''
void f(Unresolved x) {
  switch (x) {}
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_CLASS, 7, 10),
    ]);
  }

  test_notAlwaysExhaustive_int() async {
    await assertNoErrorsInCode(r'''
void f(int x) {
  switch (x) {
    case 0:
      break;
  }
}
''');
  }
}
