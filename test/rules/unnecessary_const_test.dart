// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecessaryConstPatternsTest);
    defineReflectiveTests(UnnecessaryConstRecordsTest);
  });
}

@reflectiveTest
class UnnecessaryConstPatternsTest extends LintRuleTest {
  @override
  String get lintRule => 'unnecessary_const';

  test_case_constConstructor_ok() async {
    await assertNoDiagnostics(r'''
class C {
  const C();
}
f(C c) {
  switch (c) {
    case const C():
  }
}
''');
  }

  test_case_listLiteral_ok() async {
    await assertNoDiagnostics(r'''
void f(Object o) {
  switch (o) {
    case const [1, 2]:
  }
}
''');
  }

  test_case_mapLiteral_ok() async {
    await assertNoDiagnostics(r'''
void f(Object o) {
  switch (o) {
   case const {'k': 'v'}:
  }
}
''');
  }

  test_case_setLiteral_ok() async {
    await assertNoDiagnostics(r'''
void f(Object o) {
  switch (o) {
    case const {1}:
  }
}
''');
  }

  test_constConstructor() async {
    await assertDiagnostics(r'''
class C {
  const C();
}
const c = const C();
''', [
      lint(35, 9),
    ]);
  }

  test_listLiteral() async {
    await assertDiagnostics(r'''
const l = const [];
''', [
      lint(10, 8),
    ]);
  }

  test_mapLiteral() async {
    await assertDiagnostics(r'''
const m = const {1: 1};
''', [
      lint(10, 12),
    ]);
  }

  test_setLiteral() async {
    await assertDiagnostics(r'''
const s = const {1};
''', [
      lint(10, 9),
    ]);
  }
}

@reflectiveTest
class UnnecessaryConstRecordsTest extends LintRuleTest {
  @override
  String get lintRule => 'unnecessary_const';

  test_constCall_nonConstArgument() async {
    await assertNoDiagnostics(r'''
var x = const A({});
class A {
  const A(Object o);
}
''');
  }

  test_constVariable_constCall() async {
    await assertDiagnostics(r'''
const x = const A();
class A {
  const A();
}
''', [
      lint(10, 9),
    ]);
  }

  test_constVariable_constCall_newName_noArgument() async {
    await assertDiagnostics(r'''
const x = const A.new();
class A {
  const A();
}
''', [
      lint(10, 13),
    ]);
  }

  test_constVariable_constCall_nonConstArgument() async {
    await assertDiagnostics(r'''
const x = const A([]);
class A {
  const A(Object o);
}
''', [
      lint(10, 11),
    ]);
  }

  test_constVariable_nonConstCall() async {
    await assertNoDiagnostics(r'''
const x = A();
class A {
  const A();
}
''');
  }

  test_constVariable_nonConstCall_nonConstArgument() async {
    await assertNoDiagnostics(r'''
const x = A([]);
class A {
  const A(Object o);
}
''');
  }

  test_noContext_constCall() async {
    await assertNoDiagnostics(r'''
void f() {
  const A();
}
class A {
  const A();
}
''');
  }

  test_noContext_constCall_newName() async {
    await assertNoDiagnostics(r'''
void f() {
  const A.new();
}
class A {
  const A();
}
''');
  }

  test_noContext_constCall_nonConstArgument() async {
    await assertNoDiagnostics(r'''
void f() {
  const A(A());
}
class A {
  const A([o]);
}
''');
  }

  test_noContext_constCall_nonConstListArgument() async {
    await assertNoDiagnostics(r'''
void f() {
  const A([]);
}
class A {
  const A(Object o);
}
''');
  }

  test_noContext_newName_nonConstCall() async {
    await assertNoDiagnostics(r'''
void f() {
  A.new();
}
class A {
  const A();
}
''');
  }

  test_noContext_nonConstCall() async {
    await assertNoDiagnostics(r'''
void f() {
  A();
}
class A {
  const A();
}
''');
  }

  test_noContext_nonConstCall_constListArgument() async {
    await assertNoDiagnostics(r'''
void f() {
  A(const []);
}
class A {
  const A([o]);
}
''');
  }

  test_noContext_nonConstCall_constObjectArgument() async {
    await assertNoDiagnostics(r'''
void f() {
  A(const A());
}
class A {
  const A([o]);
}
''');
  }

  test_noContext_nonConstCall_nonConstArgument() async {
    await assertNoDiagnostics(r'''
void f() {
  A([]);
}
class A {
  const A([o]);
}
''');
  }

  test_noContext_nonConstCall_nonConstObjectArgument() async {
    await assertNoDiagnostics(r'''
void f() {
  A(A());
}
class A {
  const A([o]);
}
''');
  }

  test_recordLiteral() async {
    await assertDiagnostics(r'''
const r = const (a: 1);
''', [
      lint(10, 12),
    ]);
  }

  test_recordLiteral_ok() async {
    await assertNoDiagnostics(r'''
const r = (a: 1);
''');
  }

  test_variable_constCall_constListArgument() async {
    await assertDiagnostics(r'''
var x = const A(const []);
class A {
  const A(Object o);
}
''', [
      lint(16, 8),
    ]);
  }

  test_variable_constCall_constSetArgument() async {
    await assertDiagnostics(r'''
var x = const A(const {});
class A {
  const A(Object o);
}
''', [
      lint(16, 8),
    ]);
  }

  test_variable_constCall_newName_constArgument() async {
    await assertDiagnostics(r'''
var x = const A.new(const []);
class A {
  const A(Object o);
}
''', [
      lint(20, 8),
    ]);
  }

  test_variable_constCall_nonConstArgument() async {
    await assertNoDiagnostics(r'''
final x = const A([]);
class A {
  const A(Object o);
}
''');
  }

  test_variable_constCall_nonConstListArgument() async {
    await assertNoDiagnostics(r'''
var x = const A([]);
class A {
  const A(Object o);
}
''');
  }

  test_variable_nonConstCall() async {
    await assertNoDiagnostics(r'''
var a = A();
class A {
  const A();
}
''');
  }

  test_variable_nonConstCall_constListArgument() async {
    await assertNoDiagnostics(r'''
var x = A(const []);
class A {
  const A(Object o);
}
''');
  }

  test_variable_nonConstCall_newName_constArgument() async {
    await assertNoDiagnostics(r'''
var x = A.new(const []);
class A {
  const A(Object o);
}
''');
  }
}
