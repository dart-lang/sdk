// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnreachableSwitchCaseTest_SwitchExpression);
    defineReflectiveTests(UnreachableSwitchCaseTest_SwitchStatement);
  });
}

@reflectiveTest
class UnreachableSwitchCaseTest_SwitchExpression
    extends PubPackageResolutionTest {
  test_bool_false_true_false() async {
    await assertErrorsInCode(r'''
Object f(bool x) {
  return switch (x) {
    false => 0,
    true => 1,
    false => 2,
  };
}
''', [
      error(WarningCode.UNREACHABLE_SWITCH_CASE, 82, 2),
    ]);
  }

  test_bool_wildcard_true_false() async {
    await assertErrorsInCode(r'''
Object f(bool x) {
  return switch (x) {
    _ => 0,
    true => 1,
    false => 2,
  };
}
''', [
      error(WarningCode.DEAD_CODE, 57, 9),
      error(WarningCode.UNREACHABLE_SWITCH_CASE, 62, 2),
      error(WarningCode.DEAD_CODE, 72, 10),
      error(WarningCode.UNREACHABLE_SWITCH_CASE, 78, 2),
    ]);
  }

  test_unresolved_wildcard() async {
    await assertErrorsInCode(r'''
int f(Object? x) {
  return switch (x) {
    Unresolved() => 0,
    _ => -1,
  };
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_CLASS, 45, 10),
    ]);
  }
}

@reflectiveTest
class UnreachableSwitchCaseTest_SwitchStatement
    extends PubPackageResolutionTest {
  test_bool() async {
    await assertErrorsInCode(r'''
void f(bool x) {
  switch (x) {
    case false:
    case true:
    case false:
      break;
  }
}
''', [
      error(WarningCode.UNREACHABLE_SWITCH_CASE, 67, 4),
    ]);
  }

  test_const_unresolvedIdentifier_const() async {
    await assertErrorsInCode(r'''
void f(Object? x) {
  switch (x) {
    case 0:
      break;
    case unresolved:
      break;
    case 2:
      break;
  };
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 69, 10),
    ]);
  }

  test_const_unresolvedObject_const() async {
    await assertErrorsInCode(r'''
void f(Object? x) {
  switch (x) {
    case 0:
      break;
    case Unresolved():
      break;
    case 2:
      break;
  };
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_CLASS, 69, 10),
    ]);
  }

  test_typeCheck_exact() async {
    await assertErrorsInCode(r'''
void f(int x) {
  switch (x) {
    case int():
      break;
    case int():
    case int():
      break;
  }
}
''', [
      error(WarningCode.DEAD_CODE, 64, 4),
      error(WarningCode.UNREACHABLE_SWITCH_CASE, 64, 4),
      error(WarningCode.DEAD_CODE, 80, 4),
      error(WarningCode.UNREACHABLE_SWITCH_CASE, 80, 4),
      error(WarningCode.DEAD_CODE, 98, 6),
    ]);
  }
}
