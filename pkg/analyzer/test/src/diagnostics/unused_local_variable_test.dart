// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnusedLocalVariableTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class UnusedLocalVariableTest extends PubPackageResolutionTest {
  test_forEachPartsWithPattern_notUsed() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(List<(int,)> x) {
  for (var (a,) in x) {}
//          ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
}
''');
  }

  test_forEachPartsWithPattern_used() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(List<(int,)> x) {
  for (var (a,) in x) {
    a;
  }
}
''');
  }

  test_forEachPartsWithPattern_wildcard() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(List<(int,)> x) {
  for (var (_,) in x) {}
}
''');
  }

  test_forPartsWithPattern_notUsed() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  for (var (a,) = (0,);;) {}
//          ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
}
''');
  }

  test_forPartsWithPattern_used() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  for (var (a,) = (0,);;) {
    a;
  }
}
''');
  }

  test_forPartsWithPattern_wildcard() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  for (var (_,) = (0,);;) {}
}
''');
  }

  test_ifStatement_caseClause_logicalOr_notUsed() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Object? x) {
  if (x case int a || [int a]) {}
//               ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
//                         ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
}
''');
  }

  test_ifStatement_caseClause_logicalOr_used() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Object? x) {
  if (x case int a || [int a]) {
    a;
  }
}
''');
  }

  test_ifStatement_caseClause_single_notUsed() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Object? x) {
  if (x case int a) {}
//               ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
}
''');
  }

  test_ifStatement_caseClause_single_used() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Object? x) {
  if (x case int a) {
    a;
  }
}
''');
  }

  test_ifStatement_caseClause_whenClause() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Object? x) {
  if (x case int a when a > 0) {}
}
''');
  }

  test_ifStatement_caseClause_wildcard() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Object? x) {
  if (x case int _) {}
}
''');
  }

  test_inFor_underscores() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  for (var _ in [1,2,3]) {
    for (var __ in [4,5,6]) {
//           ^^
// [diag.unusedLocalVariable] The value of the local variable '__' isn't used.
      // do something
    }
  }
}
''');
  }

  test_inFor_underscores_preWildCards() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.4
// (pre wildcard-variables)
f() {
  for (var _ in [1,2,3]) {
    for (var __ in [4,5,6]) {
      // do something
    }
  }
}
''');
  }

  test_localVariable_forElement_underscores() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
    [
      for (var __ in [1, 2, 3]) 1
//             ^^
// [diag.unusedLocalVariable] The value of the local variable '__' isn't used.
    ];
}
''');
  }

  test_localVariable_underscores() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  var __ = 0;
//    ^^
// [diag.unusedLocalVariable] The value of the local variable '__' isn't used.
  var ___ = 0;
//    ^^^
// [diag.unusedLocalVariable] The value of the local variable '___' isn't used.
}
''');
  }

  test_localVariable_wildcard() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  var _ = 0;
}
''');
  }

  test_localVariableListPattern_underscores() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  var [__] = [1];
//     ^^
// [diag.unusedLocalVariable] The value of the local variable '__' isn't used.
}
''');
  }

  test_localVariableListPattern_wildcard() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  var [_] = [1];
}
''');
  }

  test_localVariablePattern_underscores() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  var (__) = (1);
//     ^^
// [diag.unusedLocalVariable] The value of the local variable '__' isn't used.
}
''');
  }

  test_localVariablePattern_wildcard() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  var (_) = (1);
}
''');
  }

  test_localVariableSwitchListPattern_underscores() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Object o) {
  switch(o) {
    case [var __] : {}
//            ^^
// [diag.unusedLocalVariable] The value of the local variable '__' isn't used.
  }
}
''');
  }

  test_localVariableSwitchListPattern_wildcard() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Object o) {
  switch(o) {
    case [var _] : {}
  }
}
''');
  }

  test_patternVariableDeclarationStatement_noneUsed() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  var (a, b) = (0, 1);
//     ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
//        ^
// [diag.unusedLocalVariable] The value of the local variable 'b' isn't used.
}
''');
  }

  test_patternVariableDeclarationStatement_noneUsed_nested() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  var (a, [b, _]) = (0, []);
//     ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
//         ^
// [diag.unusedLocalVariable] The value of the local variable 'b' isn't used.
}
''');
  }

  test_patternVariableDeclarationStatement_noneUsed_withChildStatements() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  var (a, b) = () {
//     ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
//        ^
// [diag.unusedLocalVariable] The value of the local variable 'b' isn't used.
    var (c, d) = (0, 1);
    return (c, d);
  }();
}
''');
  }

  test_patternVariableDeclarationStatement_notUsed() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  var (a,) = (0,);
//     ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
}
''');
  }

  test_patternVariableDeclarationStatement_someUsed() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  var (a, b) = (0, 1);
  a;
}
''');
  }

  test_patternVariableDeclarationStatement_someUsed_nested() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  var (a, [b, c]) = (0, []);
  c;
}
''');
  }

  test_patternVariableDeclarationStatement_used() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  var (a,) = (0,);
  a;
}
''');
  }

  test_patternVariableDeclarationStatement_wildcard() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  var (a, _) = (0, 1);
  a;
}
''');
  }

  test_switchExpression_notUsed() async {
    await resolveTestCodeWithDiagnostics(r'''
Object? f(Object? x) {
  return switch (x) {
    (int a,) => 0,
//       ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
    _ => 0,
  };
}
''');
  }

  test_switchExpression_used() async {
    await resolveTestCodeWithDiagnostics(r'''
Object? f(Object? x) {
  return switch (x) {
    (int a,) => a,
    _ => 0,
  };
}
''');
  }

  test_switchExpression_wildcard() async {
    await resolveTestCodeWithDiagnostics(r'''
Object? f(Object? x) {
  return switch (x) {
    (int _,) => 0,
    _ => 0,
  };
}
''');
  }

  test_switchStatement_patternCase_notUsed() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Object? x) {
  switch (x) {
    case (var a,):
//            ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
      break;
  };
}
''');
  }

  test_switchStatement_patternCase_used() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Object? x) {
  switch (x) {
    case (var a,):
      a;
  };
}
''');
  }

  test_switchStatement_patternCase_wildcard() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Object? x) {
  switch (x) {
    case (int _,):
      break;
  };
}
''');
  }

  test_switchStatement_sharedScope_consistent_notUsed() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Object? x) {
  switch (x) {
    case (var a,):
//            ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
    case [var a,]:
//            ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
      break;
  };
}
''');
  }

  test_switchStatement_sharedScope_consistent_used() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Object? x) {
  switch (x) {
    case (var a,):
    case [var a,]:
      a;
  };
}
''');
  }

  test_switchStatement_sharedScope_notConsistent_notUsed() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Object? x) {
  switch (x) {
    case 0:
    case [var a]:
//            ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
      break;
  };
}
''');
  }

  test_switchStatement_sharedScope_notConsistent_used() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Object? x) {
  switch (x) {
    case 0:
    case [var a]:
      a;
//    ^
// [diag.patternVariableSharedCaseScopeNotAllCases] The variable 'a' is available in some, but not all cases that share this body.
  };
}
''');
  }

  test_switchStatement_sharedScope_whenClause_notUsed_used() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Object? x) {
  switch (x) {
    case [int a,]:
//            ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
    case (int a,) when a > 0:
      break;
  };
}
''');
  }

  test_switchStatement_sharedScope_whenClause_used_notDeclared() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Object? x) {
  switch (x) {
    case (int a,) when a > 0:
    case [int _]:
      break;
  };
}
''');
  }

  test_switchStatement_sharedScope_whenClause_used_notUsed() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Object? x) {
  switch (x) {
    case (int a,) when a > 0:
    case [int a,]:
//            ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
      break;
  };
}
''');
  }

  test_switchStatement_sharedScope_whenClause_used_used() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(Object? x) {
  switch (x) {
    case (int a,) when a > 0:
    case [int a,] when a > 0:
      break;
  };
}
''');
  }

  test_variableDeclarationStatement_inFunction() async {
    await resolveTestCodeWithDiagnostics(r'''
main() {
  var v = 1;
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'v' isn't used.
  v = 2;
}
''');
  }

  test_variableDeclarationStatement_inMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  foo() {
    var v = 1;
//      ^
// [diag.unusedLocalVariable] The value of the local variable 'v' isn't used.
    v = 2;
  }
}
''');
  }

  test_variableDeclarationStatement_isInvoked() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef Foo();
main() {
  Foo foo = () {};
  foo();
}
''');
  }

  test_variableDeclarationStatement_isNullAssigned() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef Foo();
main() {
  var v;
  v ??= doSomething();
}
doSomething() => 42;
''');
  }

  test_variableDeclarationStatement_isRead_notUsed_compoundAssign() async {
    await resolveTestCodeWithDiagnostics(r'''
main() {
  var v = 1;
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'v' isn't used.
  v += 2;
}
''');
  }

  test_variableDeclarationStatement_isRead_notUsed_postfixExpr() async {
    await resolveTestCodeWithDiagnostics(r'''
main() {
  var v = 1;
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'v' isn't used.
  v++;
}
''');
  }

  test_variableDeclarationStatement_isRead_notUsed_prefixExpr() async {
    await resolveTestCodeWithDiagnostics(r'''
main() {
  var v = 1;
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'v' isn't used.
  ++v;
}
''');
  }

  test_variableDeclarationStatement_isRead_usedArgument() async {
    await resolveTestCodeWithDiagnostics(r'''
main() {
  var v = 1;
  print(++v);
}
print(x) {}
''');
  }

  test_variableDeclarationStatement_isRead_usedInvocationTarget() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  foo() {}
}
main() {
  var a = new A();
  a.foo();
}
''');
  }
}
