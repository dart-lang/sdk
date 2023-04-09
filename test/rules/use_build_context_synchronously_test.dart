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

  test_await_afterReferenceToContextInBody() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  Navigator.of(context);
  await f();
}

Future<void> f() async {}
''');
  }

  test_await_beforeReferenceToContextInBody() async {
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

  test_awaitBeforeIf_mountedExitGuardInIfConditionWithOr_beforeReferenceToContext() async {
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

  test_awaitBeforeIf_mountedGuardInIfCondition_referenceToContextInIfBody() async {
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

  test_awaitBeforeIf_mountedGuardInIfConditionWithAnd_referenceToContextInIfBody() async {
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

  test_awaitBeforeIfStatement_beforeReferenceToContext() async {
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

  test_awaitBeforeSwitch_mountedExitGuardInCase_beforeReferenceToContext() async {
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

  // https://github.com/dart-lang/linter/issues/3457
  test_awaitInIfCondition_aboveReferenceToContext() async {
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

  test_awaitInIfReferencesContext_beforeReferenceToContext() async {
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(
    BuildContext context, Future<bool> Function(BuildContext) condition) async {
  if (await condition(context)) {
    Navigator.of(context);
  }
}
''', [
      lint(169, 21),
    ]);
  }

  test_awaitInIfThen_afterReferenceToContext() async {
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

  test_awaitThenExitInIfThenAndElse_afterReferenceToContext() async {
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

  test_awaitThenExitInIfThenAndElse_beforeReferenceToContext() async {
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
