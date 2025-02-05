// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecessaryLambdasTest);
  });
}

@reflectiveTest
class UnnecessaryLambdasTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.unnecessary_lambdas;

  test_asyncLambda() async {
    await assertNoDiagnostics(r'''
var x = [].forEach((x) async => print(x));
''');
  }

  test_constructorCall_const() async {
    await assertNoDiagnostics(r'''
class C {
  const C();
}
var x = [() => const C()];
''');
  }

  test_constructorCall_explicitNew() async {
    await assertNoDiagnostics(r'''
class C {
  C(int a);
}
var x = [].map((e) => C.new(e));
''');
  }

  test_constructorCall_imported() async {
    newFile('$testPackageLibPath/b.dart', r'''
class C {}
''');
    await assertDiagnostics(r'''
import 'b.dart' as b;

var x = [() => b.C()];
''', [
      lint(32, 11),
    ]);
  }

  test_constructorCall_importedDeferred() async {
    newFile('$testPackageLibPath/b.dart', r'''
class C {}
''');
    await assertNoDiagnostics(r'''
import 'b.dart' deferred as b;

var x = [() => b.C()];
''');
  }

  test_constructorCall_multipleArgs() async {
    await assertNoDiagnostics(r'''
class C {
  C(int i, int j);
}
var x = [].map((x) => C(3, x));
''');
  }

  test_constructorCall_named() async {
    await assertNoDiagnostics(r'''
class C {
  C.named(int a);
}
var x = [].map((e) => C.named(e));
''');
  }

  test_constructorCall_noArgs() async {
    await assertDiagnostics(r'''
class C {}
var x = [() => C()];
''', [
      lint(20, 9),
    ]);
  }

  test_constructorCall_noParameter_oneArg() async {
    await assertNoDiagnostics(r'''
class C {
  C(int i);
}
var x = [() => C(3)];
''');
  }

  test_constructorCall_unnamed() async {
    await assertNoDiagnostics(r'''
class C {
  C(int a);
}
var x = [].map((e) => C(e));
''');
  }

  test_constructorCall_unnamed_blockBody() async {
    await assertNoDiagnostics(r'''
class C {
  C(int a);
}
var x = [].map((e) { return C(e); });
''');
  }

  test_constructorCall_unrelatedArg() async {
    await assertNoDiagnostics(r'''
class C {
  C(int i);
}
var x = [].map((x) => C(3));
''');
  }

  test_deeplyNestedVariable() async {
    await assertNoDiagnostics(r'''
void f() {
  var x = (a, b) => foo(foo(b)).foo(a, b);
}
dynamic foo(a) => 7;
''');
  }

  test_emptyLambda() async {
    await assertNoDiagnostics(r'''
var f = () {};
''');
  }

  test_functionCall_explicitTypeArg() async {
    await assertNoDiagnostics(r'''
void f<T>() {}
var x = [() => f<int>()];
''');
  }

  test_functionCall_matchingArg() async {
    await assertDiagnostics(r'''
var x = [].forEach((x) => print(x));
''', [
      lint(19, 15),
    ]);
  }

  test_functionCall_singleStatement() async {
    await assertDiagnostics(r'''
final f = () {};
final l = () {
  f();
};
''', [
      lint(27, 13),
    ]);
  }

  test_functionTearoff() async {
    await assertNoDiagnostics(r'''
var x = [].forEach(print);
''');
  }

  test_importedFunction() async {
    newFile('$testPackageLibPath/b.dart', r'''
bool isB(Object o) => true;
''');
    await assertDiagnostics(r'''
import 'b.dart' as b;

void f() {
  [].where((o) => b.isB(o));
}
''', [
      lint(45, 15),
    ]);
  }

  test_importedFunction_deferred() async {
    newFile('$testPackageLibPath/b.dart', r'''
bool isB(Object o) => true;
''');
    await assertNoDiagnostics(r'''
import 'b.dart' deferred as b;

void f() {
  [].where((o) => b.isB(o));
}
''');
  }

  test_importedStatic_deferred() async {
    newFile('$testPackageLibPath/b.dart', r'''
class C {
static bool isB(Object o) => true;
}
''');
    await assertNoDiagnostics(r'''
import 'b.dart' deferred as b;

void f() {
  [].where((o) => b.C.isB(o));
}

''');
  }

  test_importedTearoff_deferred() async {
    newFile('$testPackageLibPath/b.dart', r'''
bool isB(Object o) => true;
final isB2 = isB;
''');
    await assertNoDiagnostics(r'''
import 'b.dart' deferred as b;

void f() {
  [].where((o) => b.isB2(o));
}

''');
  }

  test_matchingArg_dynamicParameterToOtherArg_named() async {
    await assertNoDiagnostics(r'''
var x = f(fn: (s) => count(s));
int count(String s) => s.length;
void f({int Function(dynamic)? fn}) {}
''');
  }

  @FailingTest(issue: 'https://github.com/dart-lang/linter/issues/3516')
  test_matchingArg_dynamicParameterToOtherArg_positional() async {
    await assertNoDiagnostics(r'''
var x = f((s) => count(s));
int count(String s) => s.length;
void f(int Function(dynamic)? fn) {}
''');
  }

  test_methodCallOnFinalLocal_closureParameterIsPartOfTarget() async {
    await assertNoDiagnostics(r'''
void f() {
  [].where((e) => (e + e).contains(e));
}
''');
  }

  test_methodCallOnFinalLocal_closureParameterIsTarget() async {
    await assertNoDiagnostics(r'''
void f() {
  [].where((e) => e.contains(e));
}
''');
  }

  test_methodCallOnFinalLocal_matchingArg() async {
    await assertDiagnostics(r'''
void f() {
  final l = [];
  [].where((e) => l.contains(e));
}
''', [
      lint(38, 20),
    ]);
  }

  test_methodCallOnLateFinalLocal_matchingArg() async {
    await assertNoDiagnostics(r'''
void f() {
  late final List<int> l;
  if (1 == 2) l = [];
  [].where((e) => l.contains(e));
}
''');
  }

  test_methodCallOnNonFinalLocal_matchingArg() async {
    await assertNoDiagnostics(r'''
void f() {
  var l = [];
  [].where((e) => l.contains(e));
}
''');
  }

  test_methodTearoffOnFinalLocal_matchingArg() async {
    await assertNoDiagnostics(r'''
void f() {
  final l = [];
  [].where(l.contains);
}
''');
  }

  test_multipleStatements() async {
    await assertNoDiagnostics(r'''
void f() {
  [].forEach((e) {
    print(e);
    print(e);
  });
}
''');
  }

  test_nonFunctionCall() async {
    await assertNoDiagnostics(r'''
void f() {
  final l = [];
  [].where((e) => l.contains(e) || e is int);
}
''');
  }

  test_noParameter_targetIsFinalField() async {
    await assertDiagnostics(r'''
class C {
  final f = 1;
  Function m() {
    return () {
      f.toString();
    };
  }
}
''', [
      lint(53, 30),
    ]);
  }

  test_noParameter_targetIsGetter() async {
    await assertNoDiagnostics(r'''
class C {
  get f => 2;

  Function m() {
    return () {
      f.toString();
    };
  }
}
''');
  }

  test_targetIsFinalParameter() async {
    await assertDiagnostics(r'''
void f(List<String> list) {
  list.where((final e) => ((a) => e.contains(a))(e));
}
''', [
      lint(55, 20),
    ]);
  }

  test_targetIsVarParameter() async {
    await assertNoDiagnostics(r'''
void main(List<String> list) {
  list.where((e) => ((a) => e.contains(a))(e));
}
''');
  }
}
