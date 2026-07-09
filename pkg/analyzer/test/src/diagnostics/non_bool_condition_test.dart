// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonBoolConditionTest);
    defineReflectiveTests(NonBoolConditionWithStrictCastsTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class NonBoolConditionTest extends PubPackageResolutionTest {
  test_conditional() async {
    await resolveTestCodeWithDiagnostics(r'''
f() { return 3 ? 2 : 1; }
//           ^
// [diag.nonBoolCondition] Conditions must have a static type of 'bool'.
''');
  }

  test_conditional_fromLiteral() async {
    await resolveTestCodeWithDiagnostics(r'''
f() { return [1, 2, 3] ? 2 : 1; }
//           ^^^^^^^^^
// [diag.nonBoolCondition] Conditions must have a static type of 'bool'.
''');
  }

  test_conditional_fromSupertype() async {
    await resolveTestCodeWithDiagnostics(r'''
f(Object o) { return o ? 2 : 1; }
//                   ^
// [diag.nonBoolCondition] Conditions must have a static type of 'bool'.
''');
  }

  test_const_list_ifElement() async {
    await resolveTestCodeWithDiagnostics(r'''
const dynamic c = 2;
const x = [1, if (c) 2 else 3, 4];
//                ^
// [diag.nonBoolCondition] Conditions must have a static type of 'bool'.
''');
  }

  test_const_list_ifElement_static() async {
    await resolveTestCodeWithDiagnostics(r'''
const x = [1, if (1) 2 else 3, 4];
//                ^
// [diag.nonBoolCondition] Conditions must have a static type of 'bool'.
''');
  }

  test_do() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  do {} while (3);
//             ^
// [diag.nonBoolCondition] Conditions must have a static type of 'bool'.
}
''');
  }

  test_do_fromLiteral() async {
    await resolveTestCodeWithDiagnostics(r'''
f(Object o) {
  do {} while ([1, 2, 3]);
//             ^^^^^^^^^
// [diag.nonBoolCondition] Conditions must have a static type of 'bool'.
}
''');
  }

  test_do_fromSupertype() async {
    await resolveTestCodeWithDiagnostics(r'''
f(Object o) {
  do {} while (o);
//             ^
// [diag.nonBoolCondition] Conditions must have a static type of 'bool'.
}
''');
  }

  test_for() async {
    // https://github.com/dart-lang/sdk/issues/24713
    await resolveTestCodeWithDiagnostics(r'''
f() {
  for (;3;) {}
//      ^
// [diag.nonBoolCondition] Conditions must have a static type of 'bool'.
}
''');
  }

  test_for_declaration() async {
    // https://github.com/dart-lang/sdk/issues/24713
    await resolveTestCodeWithDiagnostics(r'''
f() {
  for (int i = 0; 3;) {}
//         ^
// [diag.unusedLocalVariable] The value of the local variable 'i' isn't used.
//                ^
// [diag.nonBoolCondition] Conditions must have a static type of 'bool'.
}
''');
  }

  test_for_expression() async {
    // https://github.com/dart-lang/sdk/issues/24713
    await resolveTestCodeWithDiagnostics(r'''
f() {
  int i;
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'i' isn't used.
  for (i = 0; 3;) {}
//            ^
// [diag.nonBoolCondition] Conditions must have a static type of 'bool'.
}''');
  }

  test_for_fromLiteral() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  for (;[1, 2, 3];) {}
//      ^^^^^^^^^
// [diag.nonBoolCondition] Conditions must have a static type of 'bool'.
}
''');
  }

  test_for_fromSupertype() async {
    await resolveTestCodeWithDiagnostics(r'''
f(Object o) {
  for (;o;) {}
//      ^
// [diag.nonBoolCondition] Conditions must have a static type of 'bool'.
}
''');
  }

  test_forElement() async {
    await resolveTestCodeWithDiagnostics(r'''
var v = [for (; 0;) 1];
//              ^
// [diag.nonBoolCondition] Conditions must have a static type of 'bool'.
''');
  }

  test_guardedPattern_whenClause() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  if (0 case _ when 1) {}
//                  ^
// [diag.nonBoolCondition] Conditions must have a static type of 'bool'.
}
''');
  }

  test_if() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  if (3) return 2; else return 1;
//    ^
// [diag.nonBoolCondition] Conditions must have a static type of 'bool'.
}
''');
  }

  test_if_fromLiteral() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  if ([1, 2, 3]) return 2; else return 1;
//    ^^^^^^^^^
// [diag.nonBoolCondition] Conditions must have a static type of 'bool'.
}
''');
  }

  test_if_fromSupertype() async {
    await resolveTestCodeWithDiagnostics(r'''
f(Object o) {
  if (o) return 2; else return 1;
//    ^
// [diag.nonBoolCondition] Conditions must have a static type of 'bool'.
}
''');
  }

  test_if_map() async {
    await resolveTestCodeWithDiagnostics(r'''
const dynamic nonBool = null;
const c = const {if (nonBool) 'a' : 1};
//                   ^^^^^^^
// [diag.nonBoolCondition] Conditions must have a static type of 'bool'.
''');
  }

  test_if_null() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Null a) {
  if (a) {}
//    ^
// [diag.nonBoolCondition] Conditions must have a static type of 'bool'.
}
''');
  }

  test_if_set() async {
    await resolveTestCodeWithDiagnostics(r'''
const dynamic nonBool = 'a';
const c = const {if (nonBool) 3};
//                   ^^^^^^^
// [diag.nonBoolCondition] Conditions must have a static type of 'bool'.
''');
  }

  test_ifElement() async {
    await resolveTestCodeWithDiagnostics(r'''
var v = [if (3) 1];
//           ^
// [diag.nonBoolCondition] Conditions must have a static type of 'bool'.
''');
  }

  test_ifElement_fromLiteral() async {
    await resolveTestCodeWithDiagnostics(r'''
var v = [if ([1, 2, 3]) 'x'];
//           ^^^^^^^^^
// [diag.nonBoolCondition] Conditions must have a static type of 'bool'.
''');
  }

  test_ifElement_fromSupertype() async {
    await resolveTestCodeWithDiagnostics(r'''
final o = Object();
var v = [if (o) 'x'];
//           ^
// [diag.nonBoolCondition] Conditions must have a static type of 'bool'.
''');
  }

  test_ternary_condition_null() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Null a) {
  a ? 0 : 1;
//^
// [diag.nonBoolCondition] Conditions must have a static type of 'bool'.
}
''');
  }

  test_while() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  while (3) {}
//       ^
// [diag.nonBoolCondition] Conditions must have a static type of 'bool'.
}
''');
  }

  test_while_fromLiteral() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  while ([1, 2, 3]) {}
//       ^^^^^^^^^
// [diag.nonBoolCondition] Conditions must have a static type of 'bool'.
}
''');
  }

  test_while_fromSupertype() async {
    await resolveTestCodeWithDiagnostics(r'''
f(Object o) {
  while (o) {}
//       ^
// [diag.nonBoolCondition] Conditions must have a static type of 'bool'.
}
''');
  }
}

@reflectiveTest
class NonBoolConditionWithStrictCastsTest extends PubPackageResolutionTest
    with WithStrictCastsMixin {
  test_map_ifElement_condition() async {
    await assertTestCodeWithStrictCastsDiagnostics('''
void f(dynamic c) {
  <int, int>{if (c) 0: 0};
//               ^
// [diag.nonBoolCondition] Conditions must have a static type of 'bool'.
}
''');
  }

  test_set_ifElement_condition() async {
    await assertTestCodeWithStrictCastsDiagnostics('''
void f(dynamic c) {
  <int>{if (c) 0};
//          ^
// [diag.nonBoolCondition] Conditions must have a static type of 'bool'.
}
''');
  }
}
