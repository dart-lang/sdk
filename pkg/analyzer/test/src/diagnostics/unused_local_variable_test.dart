// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnusedLocalVariableTest);
  });
}

@reflectiveTest
class UnusedLocalVariableTest extends PubPackageResolutionTest {
  test_forEachPartsWithPattern_notUsed() async {
    await assertErrorsInCode(r'''
void f(List<(int,)> x) {
  for (var (a,) in x) {}
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 37, 1),
    ]);
  }

  test_forEachPartsWithPattern_used() async {
    await assertNoErrorsInCode(r'''
void f(List<(int,)> x) {
  for (var (a,) in x) {
    a;
  }
}
''');
  }

  test_forEachPartsWithPattern_wildcard() async {
    await assertNoErrorsInCode(r'''
void f(List<(int,)> x) {
  for (var (_,) in x) {}
}
''');
  }

  test_forPartsWithPattern_notUsed() async {
    await assertErrorsInCode(r'''
void f() {
  for (var (a,) = (0,);;) {}
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 23, 1),
    ]);
  }

  test_forPartsWithPattern_used() async {
    await assertNoErrorsInCode(r'''
void f() {
  for (var (a,) = (0,);;) {
    a;
  }
}
''');
  }

  test_forPartsWithPattern_wildcard() async {
    await assertNoErrorsInCode(r'''
void f() {
  for (var (_,) = (0,);;) {}
}
''');
  }

  test_ifStatement_caseClause_logicalOr_notUsed() async {
    await assertErrorsInCode(r'''
void f(Object? x) {
  if (x case int a || [int a]) {}
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 37, 1),
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 47, 1),
    ]);
  }

  test_ifStatement_caseClause_logicalOr_used() async {
    await assertNoErrorsInCode(r'''
void f(Object? x) {
  if (x case int a || [int a]) {
    a;
  }
}
''');
  }

  test_ifStatement_caseClause_single_notUsed() async {
    await assertErrorsInCode(r'''
void f(Object? x) {
  if (x case int a) {}
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 37, 1),
    ]);
  }

  test_ifStatement_caseClause_single_used() async {
    await assertNoErrorsInCode(r'''
void f(Object? x) {
  if (x case int a) {
    a;
  }
}
''');
  }

  test_ifStatement_caseClause_whenClause() async {
    await assertNoErrorsInCode(r'''
void f(Object? x) {
  if (x case int a when a > 0) {}
}
''');
  }

  test_ifStatement_caseClause_wildcard() async {
    await assertNoErrorsInCode(r'''
void f(Object? x) {
  if (x case int _) {}
}
''');
  }

  test_inFor_underscores() async {
    await assertErrorsInCode(r'''
f() {
  for (var _ in [1,2,3]) {
    for (var __ in [4,5,6]) {
      // do something
    }
  }
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 46, 2),
    ]);
  }

  test_inFor_underscores_preWildCards() async {
    await assertNoErrorsInCode(r'''
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
    await assertErrorsInCode(r'''
f() {
    [
      for (var __ in [1, 2, 3]) 1
    ];
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 27, 2),
    ]);
  }

  test_localVariable_underscores() async {
    await assertErrorsInCode(r'''
f() {
  var __ = 0;
  var ___ = 0;
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 12, 2),
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 26, 3),
    ]);
  }

  test_localVariable_wildcard() async {
    await assertNoErrorsInCode(r'''
f() {
  var _ = 0;
}
''');
  }

  test_localVariableListPattern_underscores() async {
    await assertErrorsInCode(r'''
f() {
  var [__] = [1];
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 13, 2),
    ]);
  }

  test_localVariableListPattern_wildcard() async {
    await assertNoErrorsInCode(r'''
f() {
  var [_] = [1];
}
''');
  }

  test_localVariablePattern_underscores() async {
    await assertErrorsInCode(r'''
f() {
  var (__) = (1);
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 13, 2),
    ]);
  }

  test_localVariablePattern_wildcard() async {
    await assertNoErrorsInCode(r'''
f() {
  var (_) = (1);
}
''');
  }

  test_localVariableSwitchListPattern_underscores() async {
    await assertErrorsInCode(r'''
void f(Object o) {
  switch(o) {
    case [var __] : {}
  }
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 47, 2),
    ]);
  }

  test_localVariableSwitchListPattern_wildcard() async {
    await assertNoErrorsInCode(r'''
void f(Object o) {
  switch(o) {
    case [var _] : {}
  }
}
''');
  }

  test_patternVariableDeclarationStatement_noneUsed() async {
    await assertErrorsInCode(r'''
void f() {
  var (a, b) = (0, 1);
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 18, 1),
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 21, 1),
    ]);
  }

  test_patternVariableDeclarationStatement_noneUsed_nested() async {
    await assertErrorsInCode(r'''
void f() {
  var (a, [b, _]) = (0, []);
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 18, 1),
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 22, 1),
    ]);
  }

  test_patternVariableDeclarationStatement_noneUsed_withChildStatements() async {
    await assertErrorsInCode(r'''
void f() {
  var (a, b) = () {
    var (c, d) = (0, 1);
    return (c, d);
  }();
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 18, 1),
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 21, 1),
    ]);
  }

  test_patternVariableDeclarationStatement_notUsed() async {
    await assertErrorsInCode(r'''
void f() {
  var (a,) = (0,);
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 18, 1),
    ]);
  }

  test_patternVariableDeclarationStatement_someUsed() async {
    await assertNoErrorsInCode(r'''
void f() {
  var (a, b) = (0, 1);
  a;
}
''');
  }

  test_patternVariableDeclarationStatement_someUsed_nested() async {
    await assertNoErrorsInCode(r'''
void f() {
  var (a, [b, c]) = (0, []);
  c;
}
''');
  }

  test_patternVariableDeclarationStatement_used() async {
    await assertNoErrorsInCode(r'''
void f() {
  var (a,) = (0,);
  a;
}
''');
  }

  test_patternVariableDeclarationStatement_wildcard() async {
    await assertNoErrorsInCode(r'''
void f() {
  var (a, _) = (0, 1);
  a;
}
''');
  }

  test_switchExpression_notUsed() async {
    await assertErrorsInCode(r'''
Object? f(Object? x) {
  return switch (x) {
    (int a,) => 0,
    _ => 0,
  };
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 54, 1),
    ]);
  }

  test_switchExpression_used() async {
    await assertNoErrorsInCode(r'''
Object? f(Object? x) {
  return switch (x) {
    (int a,) => a,
    _ => 0,
  };
}
''');
  }

  test_switchExpression_wildcard() async {
    await assertNoErrorsInCode(r'''
Object? f(Object? x) {
  return switch (x) {
    (int _,) => 0,
    _ => 0,
  };
}
''');
  }

  test_switchStatement_patternCase_notUsed() async {
    await assertErrorsInCode(r'''
void f(Object? x) {
  switch (x) {
    case (var a,):
      break;
  };
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 49, 1),
    ]);
  }

  test_switchStatement_patternCase_used() async {
    await assertNoErrorsInCode(r'''
void f(Object? x) {
  switch (x) {
    case (var a,):
      a;
  };
}
''');
  }

  test_switchStatement_patternCase_wildcard() async {
    await assertNoErrorsInCode(r'''
void f(Object? x) {
  switch (x) {
    case (int _,):
      break;
  };
}
''');
  }

  test_switchStatement_sharedScope_consistent_notUsed() async {
    await assertErrorsInCode(r'''
void f(Object? x) {
  switch (x) {
    case (var a,):
    case [var a,]:
      break;
  };
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 49, 1),
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 68, 1),
    ]);
  }

  test_switchStatement_sharedScope_consistent_used() async {
    await assertNoErrorsInCode(r'''
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
    await assertErrorsInCode(r'''
void f(Object? x) {
  switch (x) {
    case 0:
    case [var a]:
      break;
  };
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 61, 1),
    ]);
  }

  test_switchStatement_sharedScope_notConsistent_used() async {
    await assertErrorsInCode(r'''
void f(Object? x) {
  switch (x) {
    case 0:
    case [var a]:
      a;
  };
}
''', [
      error(
          CompileTimeErrorCode.PATTERN_VARIABLE_SHARED_CASE_SCOPE_NOT_ALL_CASES,
          71,
          1),
    ]);
  }

  test_switchStatement_sharedScope_whenClause_notUsed_used() async {
    await assertErrorsInCode(r'''
void f(Object? x) {
  switch (x) {
    case [int a,]:
    case (int a,) when a > 0:
      break;
  };
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 49, 1),
    ]);
  }

  test_switchStatement_sharedScope_whenClause_used_notDeclared() async {
    await assertNoErrorsInCode(r'''
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
    await assertErrorsInCode(r'''
void f(Object? x) {
  switch (x) {
    case (int a,) when a > 0:
    case [int a,]:
      break;
  };
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 79, 1),
    ]);
  }

  test_switchStatement_sharedScope_whenClause_used_used() async {
    await assertNoErrorsInCode(r'''
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
    await assertErrorsInCode(r'''
main() {
  var v = 1;
  v = 2;
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 15, 1),
    ]);
  }

  test_variableDeclarationStatement_inMethod() async {
    await assertErrorsInCode(r'''
class A {
  foo() {
    var v = 1;
    v = 2;
  }
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 28, 1),
    ]);
  }

  test_variableDeclarationStatement_isInvoked() async {
    await assertNoErrorsInCode(r'''
typedef Foo();
main() {
  Foo foo = () {};
  foo();
}
''');
  }

  test_variableDeclarationStatement_isNullAssigned() async {
    await assertNoErrorsInCode(r'''
typedef Foo();
main() {
  var v;
  v ??= doSomething();
}
doSomething() => 42;
''');
  }

  test_variableDeclarationStatement_isRead_notUsed_compoundAssign() async {
    await assertErrorsInCode(r'''
main() {
  var v = 1;
  v += 2;
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 15, 1),
    ]);
  }

  test_variableDeclarationStatement_isRead_notUsed_postfixExpr() async {
    await assertErrorsInCode(r'''
main() {
  var v = 1;
  v++;
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 15, 1),
    ]);
  }

  test_variableDeclarationStatement_isRead_notUsed_prefixExpr() async {
    await assertErrorsInCode(r'''
main() {
  var v = 1;
  ++v;
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 15, 1),
    ]);
  }

  test_variableDeclarationStatement_isRead_usedArgument() async {
    await assertNoErrorsInCode(r'''
main() {
  var v = 1;
  print(++v);
}
print(x) {}
''');
  }

  test_variableDeclarationStatement_isRead_usedInvocationTarget() async {
    await assertNoErrorsInCode(r'''
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
