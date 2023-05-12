// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UseBuildContextSynchronouslyTest);
  });
}

@reflectiveTest
class UseBuildContextSynchronouslyTest extends LintRuleTest {
  @override
  bool get addFlutterPackageDep => true;

  @override
  String get lintRule => 'use_build_context_synchronously';

  /// Ensure we're not run in the test dir.
  @override
  String get testPackageRootPath => '$workspaceRootPath/lib';

  test_await_afterReferenceToContext() async {
    // Use of BuildContext, then await, in statement block is OK.
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  Navigator.of(context);
  await f();
}

Future<void> f() async {}
''');
  }

  test_await_beforeReferenceToContext() async {
    // Await, then use of BuildContext, in statement block is REPORTED.
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  await f();
  Navigator.of(context);
}

Future<void> f() async {}
''', [
      lint(94, 21),
    ]);
  }

  test_await_beforeReferenceToContext_inParens() async {
    // Await, then use of BuildContext in parentheses, in statement block is
    // REPORTED.
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  await f();
  Navigator.of((context));
}

Future<void> f() async {}
''', [
      lint(94, 23),
    ]);
  }

  test_await_beforeReferenceToContext_nullAsserted() async {
    // Await, then use of null-asserted BuildContext, in statement block is
    // REPORTED.
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext? context) async {
  await f();
  Navigator.of(context!);
}

Future<void> f() async {}
''', [
      lint(95, 22),
    ]);
  }

  test_awaitBeforeConditional_mountedGuard() async {
    // Await, then an "if mounted" guard in a conditional expression, and use of
    // BuildContext in the conditional-then, is OK.
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  await c();
  mounted ? Navigator.of(context) : null;
}
Future<void> c() async => true;
bool mounted = false;
''');
  }

  test_awaitBeforeConditional_mountedGuard2() async {
    // Await, then an "if not mounted" guard in a conditional expression, and
    // use of BuildContext in the conditional-else, is OK.
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  await c();
  !mounted ? null : Navigator.of(context);
}
Future<void> c() async => true;
bool mounted = false;
''');
  }

  test_awaitBeforeConditional_mountedGuard3() async {
    // Await, then an "if mounted" guard in a conditional expression, and
    // use of BuildContext in the conditional-else, is REPORTED.
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  await c();
  mounted ? null : Navigator.of(context);
}
Future<void> c() async => true;
bool mounted = false;
''', [
      lint(111, 21),
    ]);
  }

  test_awaitBeforeConditional_mountedGuard4() async {
    // Await, then an "if not mounted" guard in a conditional expression, and
    // use of BuildContext in the conditional-then, is REPORTED.
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  await c();
  !mounted ? Navigator.of(context) : null;
}
Future<void> c() async => true;
bool mounted = false;
''', [
      lint(105, 21),
    ]);
  }

  test_awaitBeforeIf_mountedExitGuardInIf_beforeReferenceToContext() async {
    // Await, then a proper "exit if not mounted" guard in an if-condition (or'd
    // with another bool), then use of BuildContext, is OK.
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  await f();
  if (c || !mounted) return;
  Navigator.of(context);
}

bool mounted = false;
Future<void> f() async {}
bool get c => true;
''');
  }

  test_awaitBeforeIf_mountedExitGuardInIf_beforeReferenceToContext4() async {
    // Await, then an unrelated if/else, with a proper "exit if not mounted"
    // guard in the then-statement, and another in the else-statement, then use
    // of BuildContext, is OK.
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  await f();
  if (1 == 2) {
    if (!mounted) return;
  } else {
    if (!mounted) return;
  }
  Navigator.of(context);
}

bool mounted = false;
Future<void> f() async {}
''');
  }

  test_awaitBeforeIf_mountedExitGuardInIf_beforeReferenceToContext2() async {
    // Await, then a proper "exit if not mounted" guard in an if-condition,
    // then use of BuildContext, is OK.
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  await f();
  if (!context.mounted) return;
  Navigator.of(context);
}

Future<void> f() async {}
''');
  }

  test_awaitBeforeIf_mountedExitGuardInIf_beforeReferenceToContext3() async {
    // Await, then a proper "exit if not mounted" guard in an if-condition,
    // then use of BuildContext, is OK.
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  await f();
  if (!context.mounted) {
    return;
  }
  Navigator.of(context);
}

Future<void> f() async {}
''');
  }

  test_awaitBeforeIf_mountedGuardInIf1() async {
    // Await, then a proper "if mounted" guard in an if-condition, then use of
    // BuildContext in the if-body, is OK.
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  await f();
  if (mounted) {
    Navigator.of(context);
  }
}

bool mounted = false;
Future<void> f() async {}
''');
  }

  test_awaitBeforeIf_mountedGuardInIf2() async {
    // Await, then a proper "if mounted" guard in an if-condition (and'd with
    // another condition), then use of BuildContext in the if-body, is OK.
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  await f();
  if (c && mounted) {
    Navigator.of(context);
  }
}

bool mounted = false;
Future<void> f() async {}
bool get c => true;
''');
  }

  test_awaitBeforeIf_mountedGuardInIf3() async {
    // Await, then a proper "if mounted" guard in an if-condition, then use of
    // BuildContext in the else-body, is OK.
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  await f();
  if (mounted) {
  } else {
    Navigator.of(context);
  }
}

bool mounted = false;
Future<void> f() async {}
''', [
      lint(124, 21),
    ]);
  }

  test_awaitBeforeIfStatement_withReferenceToContext() async {
    // Await, then use of BuildContext in an unrelated if-body, is REPORTED.
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  var b = await c();
  if (b) {
    Navigator.of(context);
  }
}
Future<bool> c() async => true;
''', [
      lint(115, 21),
    ]);
  }

  test_awaitBeforeReferenceToContext_inClosure() async {
    // Await, then use of BuildContext in a closure, is REPORTED.
    // todo (pq): what about closures?
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  await c();
  f1(() {
    f2(context);
  });
}

void f1(Function f) {}
void f2(BuildContext c) {}
Future<bool> c() async => true;
''');
  }

  test_awaitBeforeSwitch_mountedGuardInCase_beforeReferenceToContext() async {
    // Await, then switch statement, and in one case body, a proper "exit if
    // mounted" guard, then use of BuildContext, is OK.
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  await f();

  switch ('') {
    case 'a':
      if (!mounted) {
        break;
      }
      Navigator.of(context);
  }
}
bool mounted = false;
Future<void> f() async {}
''');
  }

  test_await_expressionContainsReferenceToContext() async {
    // Await expression contains use of BuildContext, is OK.
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(
    BuildContext context, Future<bool> Function(BuildContext) condition) async {
  await condition(context);
}
''');
  }

  // https://github.com/dart-lang/linter/issues/3457
  test_awaitInIfCondition_aboveReferenceToContext() async {
    // Await in an if-condition, then use of BuildContext in the if-body, is
    // REPORTED.
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  if (await c()) {
    Navigator.of(context);
  }
}
Future<bool> c() async => true;
''', [
      lint(102, 21),
    ]);
  }

  test_awaitInIfCondition_beforeReferenceToContext() async {
    // Await in an if-condition, then use of BuildContext, is REPORTED.
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  if (await c()) return;
  Navigator.of(context);
}
Future<bool> c() async => true;
''', [
      lint(106, 21),
    ]);
  }

  test_awaitInIfCondition_beforeReferenceToContext2() async {
    // Await in an if-condition, and use of BuildContext in single-statement
    // if-then, is REPORTED.
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  if (await c()) Navigator.of(context);
}
Future<bool> c() async => true;
''', [
      lint(96, 21),
    ]);
  }

  test_awaitInIfCondition_beforeReferenceToContext3() async {
    // Await in an if-condition, and use of BuildContext in single-statement
    // if-else, is REPORTED.
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  if (await c()) print(1);
  else Navigator.of(context);
}
Future<bool> c() async => true;
''', [
      lint(113, 21),
    ]);
  }

  test_awaitInIfCondition_expressionContainsReferenceToContext() async {
    // Await expression contains use of BuildContext, is OK.
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(
    BuildContext context, Future<bool> Function(BuildContext) condition) async {
  if (await condition(context)) {
    return;
  }
}
''');
  }

  test_awaitInIfReferencesContext_beforeReferenceToContext() async {
    // Await in an if-condition, then use of BuildContext in if-then statement,
    // is REPORTED.
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  if (await c()) {
    Navigator.of(context);
  }
}
Future<bool> c() async => true;
''', [
      lint(102, 21),
    ]);
  }

  test_awaitInIfThen_afterReferenceToContext() async {
    // Use of BuildContext, then await in an if-body, is OK.
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  Navigator.of(context);
  if (1 == 2) {
    await c();
    return;
  }
}
Future<bool> c() async => true;
''');
  }

  test_awaitInIfThen_beforeReferenceToContext() async {
    // Await in an if-body, then use of BuildContext, is OK.
    // TODO(srawlins): I think this should report a lint, since an `await` is
    // encountered in the if-body.
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  if (1 == 2) {
    await c();
    return;
  }
  Navigator.of(context);
}
Future<bool> c() async => true;
''');
  }

  test_awaitInIfThenAndExitInElse_afterReferenceToContext() async {
    // Use of BuildContext, then await in an if-body and await in the associated
    // else, is OK.
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  Navigator.of(context);
  if (1 == 2) {
    await c();
  } else {
    await c();
    return;
  }
}
Future<bool> c() async => true;
''');
  }

  test_awaitInIfThenAndExitInElse_beforeReferenceToContext() async {
    // Await in an if-body and await in the associated else, then use of
    // BuildContext, is REPORTED.
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  if (1 == 2) {
    await c();
  } else {
    await c();
    return;
  }
  Navigator.of(context);
}
Future<bool> c() async => true;
''', [
      lint(154, 21),
    ]);
  }

  @FailingTest(reason: 'Logic not implemented yet.')
  test_awaitInWhileBody_afterReferenceToContext() async {
    // While-true statement, and inside the while-body: use of
    // BuildContext, then await, is OK.
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  while (true) {
    // OK the first time only!
    Navigator.of(context);
    await f();
  }
}

bool mounted = false;
Future<void> f() async {}
''', [
      lint(149, 21),
    ]);
  }

  test_awaitInWhileBody_afterReferenceToContextOutsideWait() async {
    // Use of BuildContext, then While-true statement, and inside the
    // while-body: await and break, is OK.
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  Navigator.of(context);
  while (true) {
    await f();
    break;
  }
}
Future<void> f() async {}
''');
  }

  test_awaitInWhileBody_beforeReferenceToContext() async {
    // While-true statement, and inside the while-body: await and break, then
    // use of BuildContext, is REPORTED.
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  while (true) {
    await f();
    break;
  }
  Navigator.of(context);
}
Future<void> f() async {}
''', [
      lint(128, 21),
    ]);
  }

  test_awaitThenExitInIf_afterReferenceToContext() async {
    // Use of BuildContext, then await-and-return in an if-body and
    // await-and-return in the associated else, then use of BuildContext, is OK.
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  Navigator.of(context);
  if (1 == 2) {
    await c();
    return;
  } else {
    await c();
    return;
  }
}
Future<bool> c() async => true;
''');
  }

  test_awaitThenExitInIf_beforeReferenceToContext() async {
    // Await-and-return in an if-body and await-and-return in the associated
    // else, then use of BuildContext, is OK.
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  if (1 == 2) {
    await c();
    return;
  } else {
    await c();
    return;
  }
  Navigator.of(context);
}
Future<bool> c() async => true;
''', [
      // No lint.
      error(WarningCode.DEAD_CODE, 166, 22),
    ]);
  }

  test_conditionalOperator() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

Future<String> foo(BuildContext context, bool condition) async {
  await Future<void>.delayed(Duration());
  return mounted ? bar(context) : 'no';
}

bool get mounted => true;

String bar(BuildContext context) => 'bar';
''');
  }

  /// https://github.com/dart-lang/linter/issues/3818
  test_context_propertyAccess() async {
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

class W {
  final BuildContext context;
  W(this.context);

  Future<void> f() async {
    await Future.value();
    g(this.context);
  }

  Future<void> g(BuildContext context) async {}
}
''', [
      lint(157, 15),
    ]);
  }

  /// https://github.com/dart-lang/linter/issues/3676
  test_contextPassedAsNamedParam() async {
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

Future<void> foo(BuildContext context) async {
    await Future.value();
    bar(context: context);
}

Future<void> bar({required BuildContext context}) async {}
''', [
      lint(117, 21),
    ]);
  }

  test_noAwaitBefore_ifEmptyThen_methodInvocation() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

void f(BuildContext context) async {
  if (true) {}
  context.foo();
}

extension on BuildContext {
  void foo() {}
}
''');
  }

  /// https://github.com/dart-lang/linter/issues/3700
  test_propertyAccess_getter() async {
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

extension on BuildContext {
  BuildContext get foo => this;
}

Future<void> f(BuildContext context) async {
  await Future.value();
  context.foo;
}
''', [
      lint(174, 11),
    ]);
  }

  test_propertyAccess_setter() async {
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

extension on BuildContext {
  set foo(int x){ }
}

Future<void> f(BuildContext context) async {
  await Future.value();
  context.foo = 1;
}
''', [
      lint(162, 11),
    ]);
  }
}
