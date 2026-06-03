// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnreachableSwitchCaseTest_SwitchExpression);
    defineReflectiveTests(UnreachableSwitchCaseTest_SwitchStatement);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class UnreachableSwitchCaseTest_SwitchExpression
    extends PubPackageResolutionTest {
  test_bool_false_true_false() async {
    await resolveTestCodeWithDiagnostics(r'''
Object f(bool x) {
  return switch (x) {
    false => 0,
    true => 1,
    false => 2,
//        ^^
// [diag.unreachableSwitchCase] This case is covered by the previous cases.
  };
}
''');
  }

  test_bool_wildcard_true_false() async {
    await resolveTestCodeWithDiagnostics(r'''
Object f(bool x) {
  return switch (x) {
    _ => 0,
    true => 1,
//  ^^^^^^^^^
// [diag.deadCode] Dead code.
//       ^^
// [diag.unreachableSwitchCase] This case is covered by the previous cases.
    false => 2,
//  ^^^^^^^^^^
// [diag.deadCode] Dead code.
//        ^^
// [diag.unreachableSwitchCase] This case is covered by the previous cases.
  };
}
''');
  }

  test_guarded_reachable() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E { e1, e2 }
Object f(E e, bool b) => switch (e) {
  E.e1 when b => 0,
  E.e2 => 1,
  E.e1 => 2,
};
''');
  }

  test_guarded_unreachable() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E { e1, e2 }
Object f(E e, bool b) => switch (e) {
  E.e1 => 0,
  E.e2 => 1,
  E.e1 when b => 2,
//            ^^
// [diag.unreachableSwitchCase] This case is covered by the previous cases.
};
''');
  }

  test_unresolved_wildcard() async {
    await resolveTestCodeWithDiagnostics(r'''
int f(Object? x) {
  return switch (x) {
    Unresolved() => 0,
//  ^^^^^^^^^^
// [diag.undefinedClass] Undefined class 'Unresolved'.
    _ => -1,
  };
}
''');
  }
}

@reflectiveTest
class UnreachableSwitchCaseTest_SwitchStatement
    extends PubPackageResolutionTest {
  test_bool() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool x) {
  switch (x) {
    case false:
    case true:
    case false:
//  ^^^^
// [diag.unreachableSwitchCase] This case is covered by the previous cases.
      break;
  }
}
''');
  }

  test_const_unresolvedIdentifier_const() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Object? x) {
  switch (x) {
    case 0:
      break;
    case unresolved:
//       ^^^^^^^^^^
// [diag.undefinedIdentifier] Undefined name 'unresolved'.
      break;
    case 2:
      break;
  };
}
''');
  }

  test_const_unresolvedObject_const() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Object? x) {
  switch (x) {
    case 0:
      break;
    case Unresolved():
//       ^^^^^^^^^^
// [diag.undefinedClass] Undefined class 'Unresolved'.
      break;
    case 2:
      break;
  };
}
''');
  }

  test_guarded_reachable() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E { e1, e2 }
void f(E e, bool b) {
  switch (e) {
    case E.e1 when b:
      break;
    case E.e2:
      break;
    case E.e1:
      break;
  }
}
''');
  }

  test_guarded_unreachable() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E { e1, e2 }
void f(E e, bool b) {
  switch (e) {
    case E.e1:
      break;
    case E.e2:
      break;
    case E.e1 when b:
//  ^^^^
// [diag.unreachableSwitchCase] This case is covered by the previous cases.
      break;
  }
}
''');
  }

  test_typeCheck_exact() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(int x) {
  switch (x) {
    case int():
      break;
    case int():
//  ^^^^
// [diag.deadCode] Dead code.
// [diag.unreachableSwitchCase] This case is covered by the previous cases.
    case int():
//  ^^^^
// [diag.deadCode] Dead code.
// [diag.unreachableSwitchCase] This case is covered by the previous cases.
      break;
//    ^^^^^^
// [diag.deadCode] Dead code.
  }
}
''');
  }
}
