// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnreachableSwitchDefaultTest);
  });
}

@reflectiveTest
class UnreachableSwitchDefaultTest extends PubPackageResolutionTest {
  test_bool() async {
    await assertErrorsInCode(r'''
void f(bool x) {
  switch (x) {
    case false:
    case true:
    default:
      break;
  }
}
''', [
      error(WarningCode.UNREACHABLE_SWITCH_DEFAULT, 67, 7),
    ]);
  }

  test_enum() async {
    await assertErrorsInCode(r'''
enum E { e1, e2 }

String f(E e) {
  switch (e) {
    case E.e1:
      return 'e1';
    case E.e2:
      return 'e2';
    default:
      return 'Some other value of E (impossible)';
  }
}
''', [
      error(WarningCode.UNREACHABLE_SWITCH_DEFAULT, 122, 7),
    ]);
  }

  test_not_always_exhaustive() async {
    // If the type being switched on isn't "always exhaustive", the diagnostic
    // isn't reported, because flow analysis might not understand that the
    // switch cases fully exhaust the switch, so removing the default clause
    // might result in spurious errors.
    await assertNoErrorsInCode(r'''
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
    await assertErrorsInCode(r'''
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
      return 'Some other subclass of A (impossible)';
  }
}
''', [
      error(WarningCode.UNREACHABLE_SWITCH_DEFAULT, 160, 7),
    ]);
  }
}
