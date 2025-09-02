// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DiscardedFuturesTest);
  });
}

@reflectiveTest
class DiscardedFuturesTest extends LintRuleTest {
  @override
  bool get addMetaPackageDep => true;

  @override
  String get lintRule => LintNames.discarded_futures;

  Future<void> test_as_ok_future() async {
    await assertNoDiagnostics(r'''
void foo() {
  // ignore: unnecessary_cast
  Future<int> _ = g() as Future<int>;
}

Future<int> g() async => 0;
''');
  }

  Future<void> test_as_ok_futureOr() async {
    await assertNoDiagnostics(r'''
import 'dart:async';

void foo() {
  // ignore: unnecessary_cast
  FutureOr<int> _ = g() as Future<int>;
}

Future<int> g() async => 0;
''');
  }

  Future<void> test_assignment_mapLiteral() async {
    await assertNoDiagnostics(r'''
void foo() {
  var _ = {
    'a': g(),
    'b': '',
  };
}

Future<int> g() async => 0;
''');
  }

  Future<void> test_assignment_mapLiteral_key_ok_future() async {
    await assertNoDiagnostics(r'''
void foo() {
  var _ = {
    g(): 0,
    null: null,
  };
}

Future<int> g() async => 0;
''');
  }

  Future<void> test_assignment_mapLiteral_value_ok_future() async {
    await assertNoDiagnostics(r'''
void foo() {
  var _ = {
    'a': g(),
    'b': null,
  };
}

Future<int> g() async => 0;
''');
  }

  Future<void> test_assignment_ok() async {
    await assertNoDiagnostics(r'''
var handler = <String, Function>{};

void ff(String command) {
  handler[command] = () async {
    await g();
    g();
  };
}
Future<int> g() async => 0;
''');
  }

  Future<void> test_assignment_ok_implicit_listOfFuture() async {
    await assertNoDiagnostics(r'''
void foo() {
  var _ = [g()];
}

Future<int> g() async => 0;
''');
  }

  Future<void> test_assignment_ok_implicit_setOfFuture() async {
    await assertNoDiagnostics(r'''
void foo() {
  var _ = {g()};
}

Future<int> g() async => 0;
''');
  }

  Future<void> test_cascade_ok_future() async {
    await assertNoDiagnostics(r'''
void foo() {
  Future<int> _ = g()..hashCode;
}

Future<int> g() async => 0;
''');
  }

  Future<void> test_cascade_ok_futureOr() async {
    await assertNoDiagnostics(r'''
import 'dart:async';

void foo() {
  FutureOr<int> _ = g()..hashCode;
}

Future<int> g() async => 0;
''');
  }

  Future<void> test_cascadeSection() async {
    await assertDiagnostics(
      r'''
void foo() {
  var _ = 0..g();
}

extension on int {
  Future<int> g() async => this;
}
''',
      [lint(26, 1)],
    );
  }

  Future<void> test_conditionalOperator_assignment_future() async {
    await assertNoDiagnostics(r'''
void foo() {
  var _ = 1 == 1 ? g() : Future.value(1);
}

Future<int> g() async => 0;
''');
  }

  Future<void> test_conditionalOperator_assignment_ok_future() async {
    await assertNoDiagnostics(r'''
void foo() {
  Future<int> _ = 1 == 1 ? g() : Future.value(1);
}

Future<int> g() async => 0;
''');
  }

  Future<void> test_conditionalOperator_assignment_ok_futureOr() async {
    await assertNoDiagnostics(r'''
import 'dart:async';

void foo() {
  FutureOr<int> _ = 1 == 1 ? g() : Future.value(1);
}

Future<int> g() async => 0;
''');
  }

  Future<void> test_constructor() async {
    await assertDiagnostics(
      r'''
class A {
  A() {
    g();
  }
}

Future<int> g() async => 0;
''',
      [lint(22, 1)],
    );
  }

  Future<void> test_constructor_assignment_named_ok_future() async {
    await assertNoDiagnostics(r'''
class A {
  A({required Future<int> fn});
}

void foo() {
  A(fn: g());
}

Future<int> g() async => 0;
''');
  }

  Future<void> test_constructor_assignment_named_ok_futureOr() async {
    await assertNoDiagnostics(r'''
import 'dart:async';

class A {
  A({required FutureOr<int> fn});
}

void foo() {
  A(fn: g());
}

Future<int> g() async => 0;
''');
  }

  Future<void> test_constructor_assignment_ok_future() async {
    await assertNoDiagnostics(r'''
class A {
  A(Future<int> _);
}

void foo() {
  A(g());
}

Future<int> g() async => 0;
''');
  }

  Future<void> test_constructor_assignment_ok_futureOr() async {
    await assertNoDiagnostics(r'''
import 'dart:async';

class A {
  A(FutureOr<int> _);
}

void foo() {
  A(g());
}

Future<int> g() async => 0;
''');
  }

  Future<void> test_discardedFuture_awaited() async {
    await assertDiagnostics(
      '''
void f() {
  await g();
}

Future<void> g() async {}
''',
      [
        // No lint.
        error(CompileTimeErrorCode.awaitInWrongContext, 13, 5),
      ],
    );
  }

  Future<void> test_discardedFuture_awaited_method() async {
    await assertDiagnostics(
      '''
class C {
  void f() {
    await g();
  }

  Future<void> g() async {}
}
''',
      [
        // No lint.
        error(CompileTimeErrorCode.awaitInWrongContext, 27, 5),
      ],
    );
  }

  Future<void> test_field_assignment() async {
    await assertDiagnostics(
      r'''
class A {
  var a = () {
    g();
  };
}

Future<int> g() async => 0;
''',
      [lint(29, 1)],
    );
  }

  Future<void> test_function() async {
    await assertDiagnostics(
      r'''
void f() {
  g();
}

Future<int> g() async => 7;
''',
      [lint(13, 1)],
    );
  }

  Future<void> test_function_awaitNotRequired() async {
    await assertNoDiagnostics(r'''
import 'package:meta/meta.dart';
void f() {
  g();
}

@awaitNotRequired
Future<int> g() async => 7;
''');
  }

  Future<void> test_function_closure() async {
    await assertDiagnostics(
      r'''
void f() {
  () {
    createDir('.');
  }();
}

Future<void> createDir(String path) async {}
''',
      [lint(22, 9)],
    );
  }

  Future<void> test_function_closure2() async {
    await assertDiagnostics(
      r'''
Future<void> f() async {
  () {
    createDir('.');
  }();
}

Future<void> createDir(String path) async {}
''',
      [lint(36, 9)],
    );
  }

  Future<void> test_function_expression() async {
    await assertNoDiagnostics(r'''
void f() {
  var x = h(() => g());
  print(x);
}

int h(Function f) => 0;

Future<int> g() async => 0;
''');
  }

  Future<void> test_function_futureOr() async {
    await assertDiagnostics(
      '''
import 'dart:async';

void f() {
  g();
}

FutureOr<int> g() async => 0;
''',
      [lint(35, 1)],
    );
  }

  Future<void> test_function_ok_async() async {
    await assertNoDiagnostics(r'''
Future<void> recreateDir(String path) async {
  await deleteDir(path);
  await createDir(path);
}

Future<void> deleteDir(String path) async {}
Future<void> createDir(String path) async {}
''');
  }

  Future<void> test_function_ok_return_invocation() async {
    await assertNoDiagnostics(r'''
Future<int> f() {
  return g();
}
Future<int> g() async => 0;
''');
  }

  Future<void> test_function_unawaited() async {
    // https://github.com/dart-lang/sdk/issues/59204
    await assertDiagnostics(
      r'''
import 'dart:async';

void baz(String path) {
  foo(() {                // This should trigger
    unawaited(foo(() {    // This should _not_ trigger
      unawaited(bar());   // This should _not_ trigger
      bar();              // This should trigger
    }));
  });
}

Future<void> foo(void Function() f) async {}
Future<void> bar() async {}
''',
      [lint(48, 3), lint(211, 3)],
    );
  }

  Future<void> test_ifNull_ok_future() async {
    await assertNoDiagnostics(r'''
void foo() {
  Future<int>? variable;
  Future<int> _ = variable ?? g();
}

Future<int> g() async => 0;
''');
  }

  Future<void> test_ifNull_ok_futureOr() async {
    await assertNoDiagnostics(r'''
import 'dart:async';

void foo() {
  Future<int>? variable;
  FutureOr<int> _ = variable ?? g();
}

Future<int> g() async => 0;
''');
  }

  Future<void> test_method() async {
    await assertDiagnostics(
      r'''
class C {
  void m() {
    g();
  }

  Future<void> g() async {}
}
''',
      [lint(27, 1)],
    );
  }

  Future<void> test_method_assignment_named_ok_future() async {
    await assertNoDiagnostics(r'''
void f({required Future<int> fn}) {}

void foo() {
  f(fn: g());
}

Future<int> g() async => 0;
''');
  }

  Future<void> test_method_assignment_named_ok_futureOr() async {
    await assertNoDiagnostics(r'''
import 'dart:async';

void f({required FutureOr<int> fn}) {}

void foo() {
  f(fn: g());
}

Future<int> g() async => 0;
''');
  }

  Future<void> test_method_assignment_ok_future() async {
    await assertNoDiagnostics(r'''
void f(Future<int> _) {}

void foo() {
  f(g());
}

Future<int> g() async => 0;
''');
  }

  Future<void> test_method_assignment_ok_futureOr() async {
    await assertNoDiagnostics(r'''
import 'dart:async';

void f(FutureOr<int> _) {}

void foo() {
  f(g());
}

Future<int> g() async => 0;
''');
  }

  Future<void> test_method_awaitNotRequired() async {
    await assertNoDiagnostics(r'''
import 'package:meta/meta.dart';
class C {
  void m() {
    g();
  }

  @awaitNotRequired
  Future<void> g() async {}
}
''');
  }

  Future<void> test_method_record_namedAssignment_ok_future() async {
    await assertNoDiagnostics(r'''
void foo() {
  bar((f: g(),));
}

Future<int> g() async => 0;
void bar(({Future<int> f,}) r) {}
''');
  }

  Future<void> test_method_record_namedAssignment_ok_futureOr() async {
    await assertNoDiagnostics(r'''
import 'dart:async';

void foo() {
  bar((f: g(),));
}

Future<int> g() async => 0;
void bar(({FutureOr<int> f,}) r) {}
''');
  }

  Future<void> test_method_record_positionalAssignment_ok_future() async {
    await assertNoDiagnostics(r'''
void foo() {
  bar((g(),));
}

Future<int> g() async => 0;
void bar((Future<int>,) r) {}
''');
  }

  Future<void> test_method_record_positionalAssignment_ok_futureOr() async {
    await assertNoDiagnostics(r'''
import 'dart:async';

void foo() {
  bar((g(),));
}

Future<int> g() async => 0;
void bar((FutureOr<int>,) r) {}
''');
  }

  Future<void> test_newMethod_invocation() async {
    await assertDiagnostics(
      r'''
void foo() {
  g().then((_) {});
}

Future<int> g() async => 0;
''',
      [lint(19, 4)],
    );
  }

  Future<void> test_parenthesized_ok_future() async {
    await assertNoDiagnostics(r'''
void foo() {
  Future<int> _ = (g());
}

Future<int> g() async => 0;
''');
  }

  Future<void> test_parenthesized_ok_futureOr() async {
    await assertNoDiagnostics(r'''
import 'dart:async';

void foo() {
  FutureOr<int> _ = (g());
}

Future<int> g() async => 0;
''');
  }

  Future<void> test_propertyAccess() async {
    await assertNoDiagnostics(r'''
void foo() {
  g().runtimeType;
}

Future<int> g() async => 0;
''');
  }

  Future<void> test_record_namedAssignment_ok_future() async {
    await assertNoDiagnostics(r'''
void foo() {
  ({Future<int> f,}) _ = (f: g(),);
}

Future<int> g() async => 0;
''');
  }

  Future<void> test_record_namedAssignment_ok_futureOr() async {
    await assertNoDiagnostics(r'''
import 'dart:async';

void foo() {
  ({FutureOr<int> f,}) _ = (f: g(),);
}

Future<int> g() async => 0;
''');
  }

  Future<void> test_record_positionalAssignment_ok_future() async {
    await assertNoDiagnostics(r'''
void foo() {
  (Future<int>,) _ = (g(),);
}

Future<int> g() async => 0;
''');
  }

  Future<void> test_record_positionalAssignment_ok_futureOr() async {
    await assertNoDiagnostics(r'''
import 'dart:async';

void foo() {
  (FutureOr<int>,) _ = (g(),);
}

Future<int> g() async => 0;
void bar((Future<int>,) r) {}
''');
  }

  Future<void> test_switch_assignment_ok_future() async {
    await assertNoDiagnostics(r'''
void foo() {
  Future<int> _ = switch(1) {
    1 => g(),
    _ => Future.value(1),
  };
}

Future<int> g() async => 0;
''');
  }

  Future<void> test_switch_assignment_ok_futureOr() async {
    await assertNoDiagnostics(r'''
import 'dart:async';

void foo() {
  FutureOr<int> _ = switch(1) {
    1 => g(),
    _ => Future.value(1),
  };
}

Future<int> g() async => 0;
''');
  }

  Future<void> test_topLevel_assignment() async {
    await assertDiagnostics(
      r'''
var a = () {
  g();
};

Future<int> g() async => 0;
''',
      [lint(15, 1)],
    );
  }

  Future<void> test_topLevel_assignment_expression_body() async {
    await assertNoDiagnostics(r'''
var a = () => g();

Future<int> g() async => 0;
''');
  }

  Future<void> test_topLevel_assignment_ok_async() async {
    await assertNoDiagnostics(r'''
var a = () async {
  g();
};

Future<int> g() async => 0;
''');
  }

  Future<void> test_topLevel_assignment_ok_future() async {
    await assertNoDiagnostics(r'''
Future<int> a = g();

Future<int> g() async => 0;
''');
  }

  Future<void> test_variable_assignment() async {
    await assertDiagnostics(
      r'''
var handler = <String, Function>{};

void ff(String command) {
  handler[command] = () {
    g();
  };
}

Future<int> g() async => 0;
''',
      [lint(93, 1)],
    );
  }

  Future<void> test_variable_assignment_ok_future() async {
    await assertNoDiagnostics(r'''
void foo() {
  Future<int> _ = g();
}

Future<int> g() async => 0;
''');
  }

  Future<void> test_variable_assignment_ok_futureOr() async {
    await assertNoDiagnostics(r'''
import 'dart:async';

void foo() {
  FutureOr<int> _ = g();
}

Future<int> g() async => 0;
''');
  }
}
