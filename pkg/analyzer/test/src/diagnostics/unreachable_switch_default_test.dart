// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnreachableSwitchDefaultTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class UnreachableSwitchDefaultTest extends PubPackageResolutionTest {
  test_bool() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(bool x) {
  switch (x) {
    case false:
    case true:
    default:
//  ^^^^^^^
// [diag.unreachableSwitchDefault] This default clause is covered by the previous cases.
      break;
  }
}
''');
  }

  test_enum() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E { e1, e2 }

String f(E e) {
  switch (e) {
    case E.e1:
      return 'e1';
    case E.e2:
      return 'e2';
    default:
//  ^^^^^^^
// [diag.unreachableSwitchDefault] This default clause is covered by the previous cases.
      return 'Some other value of E (impossible)';
  }
}
''');
  }

  test_not_always_exhaustive() async {
    // If the type being switched on isn't "always exhaustive", the diagnostic
    // isn't reported, because flow analysis might not understand that the
    // switch cases fully exhaust the switch, so removing the default clause
    // might result in spurious errors.
    await resolveTestCodeWithDiagnostics(r'''
String f(List x) {
  switch (x) {
    case []:
      return 'empty';
    case [var y, ...]:
      return 'non-empty starting with $y';
    default:
      return 'impossible';
  }
}
''');
  }

  test_sealed_class() async {
    await resolveTestCodeWithDiagnostics(r'''
sealed class A {}
class B extends A {}
class C extends A {}

String f(A x) {
  switch (x) {
    case B():
      return 'B';
    case C():
      return 'C';
    default:
//  ^^^^^^^
// [diag.unreachableSwitchDefault] This default clause is covered by the previous cases.
      return 'Some other subclass of A (impossible)';
  }
}
''');
  }
}
