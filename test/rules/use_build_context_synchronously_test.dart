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

  test_assignmentExpressionContainsMountedCheck_thenReferenceToContext() async {
    // Assignment statement-expression with mounted check, then use of
    // BuildContext in if-then statement, is REPORTED.
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  await c();
  var m = context.mounted;
  Navigator.of(context);
}

Future<void> c() async {}
''', [
      lint(121, 21),
    ]);
  }

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

  test_awaitAndExitInIfElse_beforeReferenceToContext() async {
    // Await-and-exit in an if-else, then use of BuildContext, is REPORTED.
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  if (1 == 2) {
    ;
  } else {
    await c();
    return;
  }
  Navigator.of(context);
}
Future<bool> c() async => true;
''');
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

  test_awaitBeforeConditional_mountedGuard5() async {
    // Await, then an "if mounted" guard in a conditional expression, an await
    // in the conditional-else, and use of BuildContext afterward, is REPORTED.
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  await c();
  mounted ? 'x' : await c();
  Navigator.of(context);
}
Future<void> c() async => true;
bool mounted = false;
''', [
      lint(123, 21),
    ]);
  }

  test_awaitBeforeIf_awaitAndMountedGuard() async {
    // Await, then if-condition with an await "&&" a mounted check, then use of
    // BuildContext in the if-body, is OK.
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  await f();
  if (await c() && mounted) {
    Navigator.of(context);
  }
}

bool mounted = false;
Future<void> f() async {}
Future<bool> c() async => true;
''');
  }

  test_awaitBeforeIf_AwaitOrMountedGuard() async {
    // Await, then if-condition with an await "||" a mounted check, then use of
    // BuildContext in the if-body, is REPORTED.
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  await f();
  if (await c() || mounted) {
    Navigator.of(context);
  }
}

bool mounted = false;
Future<void> f() async {}
Future<bool> c() async => true;
''', [
      lint(126, 21),
    ]);
  }

  test_awaitBeforeIf_ConditionOrMountedGuard() async {
    // Await, then if-condition with a condition "||" a mounted check, then use
    // of BuildContext in the if-body, is REPORTED.
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  await f();
  if (c() || mounted) {
    Navigator.of(context);
  }
}

bool mounted = false;
Future<void> f() async {}
bool c() => true;
''', [
      lint(120, 21),
    ]);
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

  test_awaitBeforeIf_mountedExitGuardInIf_beforeReferenceToContext5() async {
    // Await, then an unrelated if/else, and both the then-statement and the
    // else-statement contain an "exit if not mounted" guard and an await, then
    // use of BuildContext, is REPORTED.
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  await f();
  if (1 == 2) {
    if (!mounted) return;
    await f();
  } else {
    if (!mounted) return;
    await f();
  }
  Navigator.of(context);
}

bool mounted = false;
Future<void> f() async {}
''', [
      lint(207, 21),
    ]);
  }

  test_awaitBeforeIf_mountedExitGuardInIf_beforeReferenceToContext6() async {
    // Await, then an unrelated if/else, and the then-statement contains an
    // await, and the else-statement contains an "exit if not mounted" check,
    // then use of BuildContext, is REPORTED.
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  await f();
  if (1 == 2) {
    await f();
  } else {
    if (!mounted) return;
  }
  Navigator.of(context);
}

bool mounted = false;
Future<void> f() async {}
''', [
      lint(166, 21),
    ]);
  }

  test_awaitBeforeIf_mountedExitGuardInIf_beforeReferenceToContext7() async {
    // Await, then a proper "exit if not mounted" guard in an if-condition,
    // then more await in else-statement, then use of BuildContext, is REPORTED.
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  await f();
  if (!context.mounted) {
    return;
  } else {
    await f();
  }
  Navigator.of(context);
}

Future<void> f() async {}
''', [
      lint(162, 21),
    ]);
  }

  test_awaitBeforeIf_mountedGuardAndAwait() async {
    // Await, then if-condition with a mounted check "&&" an await, then use of
    // BuildContext in the if-body, is REPORTED.
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  await f();
  if (mounted && await c()) {
    Navigator.of(context);
  }
}

bool mounted = false;
Future<void> f() async {}
Future<bool> c() async => true;
''', [
      lint(126, 21),
    ]);
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

  test_awaitBeforeMountedCheckInTryBody_beforeReferenceToContext() async {
    // Await, then try-statement with mounted check in the try-body, then use of
    // BuildContext, is REPORTED.
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  await c();
  try {
    if (!context.mounted) return;
  } on Exception {
  }
  Navigator.of(context);
}
Future<void> c() async {}
''', [
      lint(159, 21),
    ]);
  }

  test_awaitBeforeMountedCheckInTryFinally_beforeReferenceToContext() async {
    // Await, then try-statement with mounted check in the try-finally, then use
    // of BuildContext, is OK.
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  await c();
  try {
  } finally {
    if (!context.mounted) return;
  }
  Navigator.of(context);
}
Future<void> c() async {}
''');
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

  test_awaitBeforeWhileBody_referenceToContext_thenMountedGuard() async {
    // Await, then While-true statement, and inside the while-body: use of
    // BuildContext, then mounted guard, is REPORTED.
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  await f();
  while (true) {
    Navigator.of(context);
    if (context.mounted) return;
  }
}

bool mounted = false;
Future<void> f() async {}
''', [
      lint(113, 21),
    ]);
  }

  test_awaitInAdjacentStrings_beforeReferenceToContext() async {
    // Await in an adjacent strings, then use of BuildContext, is REPORTED.
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  '' '${await c()}';
  Navigator.of(context);
}
Future<bool> c() async => true;
''', [
      lint(102, 21),
    ]);
  }

  test_awaitInAdjacentStrings_beforeReferenceToContext2() async {
    // Await in adjacent strings, then use of BuildContext in later in same
    // adjacent strings, is REPORTED.
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  '${await c()}' '${Navigator.of(context)}';
}
Future<bool> c() async => true;
''', [
      lint(99, 21),
    ]);
  }

  test_awaitInCascadeSection_beforeReferenceToContext() async {
    // Await in a cascade target, then use of BuildContext in same cascade, is
    // REPORTED.
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  []..add(await c())..add(Navigator.of(context));
}
Future<int> c() async => 1;
''', [
      lint(105, 21),
    ]);
  }

  test_awaitInCascadeTarget_beforeReferenceToContext() async {
    // Await in a cascade target, then use of BuildContext, is REPORTED.
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  (await c())..toString();
  Navigator.of(context);
}
Future<bool> c() async => true;
''', [
      lint(108, 21),
    ]);
  }

  test_awaitInCascadeTarget_beforeReferenceToContext2() async {
    // Await in a cascade target, then use of BuildContext in same cascade, is
    // REPORTED.
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  (await c())..add(Navigator.of(context));
}
Future<List<void>> c() async => [];
''', [
      lint(98, 21),
    ]);
  }

  test_awaitInCascadeTarget_beforeReferenceToContext3() async {
    // Await in a cascade target, then use of BuildContext in same cascade, is
    // REPORTED.
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  (await c())..add(1)..add(Navigator.of(context));
}
Future<List<void>> c() async => [];
''', [
      lint(106, 21),
    ]);
  }

  test_awaitInForElementWithDeclaration_beforeReferenceToContext() async {
    // Await in for-element for-parts-with-declaration variables, then use of
    // BuildContext, is REPORTED.
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  [
    for (var i = await c(); i < 5; i++) 'text',
  ];
  Navigator.of(context);
}
Future<int> c() async => 1;
''', [
      lint(138, 21),
    ]);
  }

  test_awaitInForElementWithDeclaration_beforeReferenceToContext2() async {
    // Await in for-element for-parts-with-declaration condition, then use of
    // BuildContext, is REPORTED.
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  [
    for (var i = 0; i < await c(); i++) 'text',
  ];
  Navigator.of(context);
}
Future<int> c() async => 1;
''', [
      lint(138, 21),
    ]);
  }

  test_awaitInForElementWithDeclaration_beforeReferenceToContext3() async {
    // Await, then mounted check in for-element for-parts-with-declaration
    // condition, then use of
    // BuildContext in the same for-element body, is OK.
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  await c();
  [
    for (var i = 0; context.mounted; i++)
      Navigator.of(context),
  ];
}
Future<void> c() async => 1;
''');
  }

  test_awaitInForElementWithDeclaration_beforeReferenceToContext4() async {
    // Await in for-element for-parts-with-declaration updaters, then use of
    // BuildContext, is REPORTED.
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  [
    for (var i = 0; i < 5; i += await c()) 'text',
  ];
  Navigator.of(context);
}
Future<int> c() async => 1;
''', [
      lint(141, 21),
    ]);
  }

  test_awaitInForElementWithEach_beforeReferenceToContext() async {
    // Await in for-element for-each-parts condition, then use of BuildContext,
    // is REPORTED.
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  [
    for (var e in await c()) 'text',
  ];
  Navigator.of(context);
}
Future<List<int>> c() async => [];
''', [
      lint(127, 21),
    ]);
  }

  test_awaitInForElementWithEach_beforeReferenceToContext2() async {
    // Await in for-element for-each-parts condition, then use of BuildContext,
    // is REPORTED.
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  [
    for (var e in []) await c(),
  ];
  Navigator.of(context);
}
Future<int> c() async => 1;
''', [
      lint(123, 21),
    ]);
  }

  test_awaitInForElementWithExpression_beforeReferenceToContext() async {
    // Await in for-element for-parts-with-expression variables, then use of
    // BuildContext, is REPORTED.
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context, int i) async {
  [
    for (i = await c(); i < 5; i++) 'text',
  ];
  Navigator.of(context);
}
Future<int> c() async => 1;
''', [
      lint(141, 21),
    ]);
  }

  test_awaitInForElementWithExpression_beforeReferenceToContext2() async {
    // Await in for-element for-parts-with-expression condition, then use of
    // BuildContext, is REPORTED.
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context, int i) async {
  [
    for (i = 0; i < await c(); i++) 'text',
  ];
  Navigator.of(context);
}
Future<int> c() async => 1;
''', [
      lint(141, 21),
    ]);
  }

  test_awaitInForElementWithExpression_beforeReferenceToContext3() async {
    // Await, then mounted check in for-element for-parts-with-expression
    // condition, then use of BuildContext in the same for-element body, is OK.
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context, int i) async {
  await c();
  [
    for (var i = 0; context.mounted; i++)
      Navigator.of(context),
  ];
}
Future<void> c() async => 1;
''');
  }

  test_awaitInForElementWithExpression_beforeReferenceToContext4() async {
    // Await in for-element for-parts-with-expression updaters, then use of
    // BuildContext, is REPORTED.
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context, int i) async {
  [
    for (i = 0; i < 5; i += await c()) 'text',
  ];
  Navigator.of(context);
}
Future<int> c() async => 1;
''', [
      lint(144, 21),
    ]);
  }

  test_awaitInFunctionExpressionInvocation_beforeReferenceToContext() async {
    // Await in a function expression invocation function, then use of
    // BuildContext, is REPORTED.
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  ((await c()).add)(1);
  Navigator.of(context);
}
Future<List<int>> c() async => [];
''', [
      lint(105, 21),
    ]);
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

  test_awaitInIfElement_beforeReferenceToContext() async {
    // Await in an if-element condition, then use of BuildContext, is REPORTED.
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  [if (await c()) 1];
  Navigator.of(context);
}
Future<bool> c() async => false;
''', [
      lint(103, 21),
    ]);
  }

  test_awaitInIfElement_beforeReferenceToContext2() async {
    // Await in an if-element condition, then use of BuildContext in
    // then-expression, is REPORTED.
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  [if (await c()) Navigator.of(context)];
}
Future<bool> c() async => false;
''', [
      lint(97, 21),
    ]);
  }

  test_awaitInIfElement_beforeReferenceToContext3() async {
    // Await, then mounted check in an if-element condition, then use of
    // BuildContext in then-expression, is OK.
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  await c();
  [if (context.mounted) Navigator.of(context)];
}
Future<void> c() async {}
''');
  }

  test_awaitInIfElement_beforeReferenceToContext4() async {
    // Await, then mounted check in an if-element condition, then use of
    // BuildContext in then-expression, is OK.
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  await c();
  [
    if (context.mounted) 1
    else Navigator.of(context)
  ];
}
Future<void> c() async {}
''', [
      lint(132, 21),
    ]);
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
    // Await in an if-body, then definite exit, then use of BuildContext, is OK.
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
    // Await in an if-body and await-and-exit in the associated else, then use
    // of BuildContext, is REPORTED.
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

  test_awaitInIndexExpressionIndex_beforeReferenceToContext() async {
    // Await in an index expression index, then use of
    // BuildContext, is REPORTED.
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context, List<Object> list) async {
  list[await c()] = Navigator.of(context);
}
Future<int> c() async => 1;
''', [
      lint(118, 21),
    ]);
  }

  test_awaitInInstanceCreationExpression_beforeReferenceToContext() async {
    // Await in an instance creation expression parameter, then use of
    // BuildContext, is REPORTED.
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  List.filled(await c(), Navigator.of(context));
}
Future<int> c() async => 1;
''', [
      lint(104, 21),
    ]);
  }

  test_awaitInIsExpression_beforeReferenceToContext2() async {
    // Await in a record literal, then use of BuildContext, is REPORTED.
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  await c() is int;
  Navigator.of(context);
}
Future<bool> c() async => true;
''', [
      lint(101, 21),
    ]);
  }

  test_awaitInMethodInvocation_beforeReferenceToContext() async {
    // Await in a method invocation target, then use of BuildContext, is
    // REPORTED.
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  (await c()).add(1);
  Navigator.of(context);
}
Future<List<int>> c() async => [];
''', [
      lint(103, 21),
    ]);
  }

  test_awaitInMethodInvocation_beforeReferenceToContext2() async {
    // Await in a method invocation parameter, then use of BuildContext, is
    // REPORTED.
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  [].indexOf(1, await c());
  Navigator.of(context);
}
Future<int> c() async => 1;
''', [
      lint(109, 21),
    ]);
  }

  test_awaitInMethodInvocation_beforeReferenceToContext3() async {
    // Await in a method invocation parameter, then use of BuildContext, is
    // REPORTED.
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  f(await c(), Navigator.of(context));
}
Future<int> c() async => 1;
void f(int a, NavigatorState b) {}
''', [
      lint(94, 21),
    ]);
  }

  test_awaitInPostfixExpression_beforeReferenceToContext() async {
    // Await in postfix expression, then use of BuildContext, is REPORTED.
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  (await c())!;
  Navigator.of(context);
}
Future<bool?> c() async => true;
''', [
      lint(97, 21),
    ]);
  }

  test_awaitInPropertyAccess_beforeReferenceToContext() async {
    // Await in property access, then use of BuildContext, is REPORTED.
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  (await c()).isEven;
  Navigator.of(context);
}
Future<int> c() async => 1;
''', [
      lint(103, 21),
    ]);
  }

  test_awaitInRecordLiteral_beforeReferenceToContext() async {
    // Await in a record literal, then use of BuildContext, is REPORTED.
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  (await c(), );
  Navigator.of(context);
}
Future<bool> c() async => true;
''', [
      lint(98, 21),
    ]);
  }

  test_awaitInRecordLiteral_beforeReferenceToContext2() async {
    // Await in a record literal, then use of BuildContext, is REPORTED.
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  (f: await c(), );
  Navigator.of(context);
}
Future<bool> c() async => true;
''', [
      lint(101, 21),
    ]);
  }

  test_awaitInSpread_beforeReferenceToContext() async {
    // Await in a spread element, then use of BuildContext, is REPORTED.
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  [...(await c())];
  Navigator.of(context);
}
Future<List<int>> c() async => [];
''', [
      lint(101, 21),
    ]);
  }

  test_awaitInStringInterpolation_beforeReferenceToContext() async {
    // Await in a string interpolation, then use of BuildContext, is REPORTED.
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context, int i) async {
  '${await c()}';
  Navigator.of(context);
}
Future<String> c() async => '';
''', [
      lint(106, 21),
    ]);
  }

  test_awaitInSwitchExpressionCase_beforeReferenceToContext() async {
    // Await in a switch expression case, then use of BuildContext, is REPORTED.
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  (switch (1) {
    _ => await c(),
  });
  Navigator.of(context);
}
Future<int> c() async => 1;
''', [
      lint(123, 21),
    ]);
  }

  test_awaitInSwitchExpressionCase_beforeReferenceToContext2() async {
    // Await in a switch expression condition, then use of BuildContext, is
    // REPORTED.
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  (switch (await c()) {
    _ => 7,
  });
  Navigator.of(context);
}
Future<int> c() async => 1;
''', [
      lint(123, 21),
    ]);
  }

  test_awaitInSwitchStatementCase_beforeReferenceToContext() async {
    // Await in a switch statement case, then use of BuildContext, is REPORTED.
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context, int i) async {
  switch (i) {
    case 1:
      await c();
  }
  Navigator.of(context);
}
Future<int> c() async => 1;
''', [
      lint(136, 21),
    ]);
  }

  test_awaitInSwitchStatementCaseGuard_beforeReferenceToContext() async {
    // Await in a switch statement case guard, then use of BuildContext, is
    // REPORTED.
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  switch (1) {
    case 1 when await c():
  }
  Navigator.of(context);
}
Future<bool> c() async => true;
''', [
      lint(127, 21),
    ]);
  }

  test_awaitInSwitchStatementCaseGuard_beforeReferenceToContext2() async {
    // Await in a switch statement case guard, then use of BuildContext in the
    // case statements, is REPORTED.
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  switch (1) {
    case 1 when await c():
      Navigator.of(context);
  }
}
Future<bool> c() async => true;
''', [
      lint(127, 21),
    ]);
  }

  test_awaitInSwitchStatementDefault_beforeReferenceToContext() async {
    // Await in a switch statement default case, then use of BuildContext, is
    // REPORTED.
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context, int i) async {
  switch (i) {
    default:
      await c();
  }
  Navigator.of(context);
}
Future<int> c() async => 1;
''', [
      lint(137, 21),
    ]);
  }

  test_awaitInTryBody_beforeReferenceToContext() async {
    // Await in a try-body, then use of BuildContext, is REPORTED.
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  try {
    await c();
  } on Exception {
  }
  Navigator.of(context);
}
Future<void> c() async {}
''', [
      lint(127, 21),
    ]);
  }

  test_awaitInTryBody_beforeReferenceToContextInCatchClause() async {
    // Await in a try-body, then use of BuildContext in try-catch clause,
    // is REPORTED.
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  try {
    await c();
  } on Exception {
    Navigator.of(context);
  }
}
Future<void> c() async {}
''', [
      lint(125, 21),
    ]);
  }

  test_awaitInTryBody_beforeReferenceToContextInTryBody() async {
    // Await in a try-body, then use of BuildContext in try-body,
    // is REPORTED.
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  try {
    await c();
    Navigator.of(context);
  } on Exception {
    return;
  }
}
Future<void> c() async {}
''', [
      lint(106, 21),
    ]);
  }

  test_awaitInWhileBody_afterReferenceToContext() async {
    // While-true statement, and inside the while-body: use of BuildContext,
    // then await, is REPORTED.
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  while (true) {
    // OK the first time only!
    Navigator.of(context);
    await f();
  }
}

Future<void> f() async {}
''', [
      lint(131, 21),
    ]);
  }

  test_awaitInWhileBody_afterReferenceToContext2() async {
    // While-true statement, and inside the while-body: use of BuildContext,
    // then await, then mounted guard, is OK.
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  while (true) {
    Navigator.of(context);
    await f();
    if (!context.mounted) return;
  }
}

Future<void> f() async {}
''');
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

  test_awaitInYield_beforeReferenceToContext() async {
    // Await in a yield expression, then use of BuildContext, is REPORTED.
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

Stream<int> foo(BuildContext context) async* {
  yield await c();
  Navigator.of(context);
}
Future<int> c() async => 1;
''', [
      lint(108, 21),
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
    // Await-and-return in an if-body, then use of BuildContext, is OK.
    await assertNoDiagnostics(
      r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  if (1 == 2) {
    await c();
    return;
  }
  Navigator.of(context);
}
Future<bool> c() async => true;
''',
    );
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

  test_ifConditionContainsMountedAndReferenceToContext() async {
    // Binary expression contains mounted check AND use of BuildContext, is
    // OK.
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(
    BuildContext context, bool Function(BuildContext) condition) async {
  await c();
  if (context.mounted && condition(context)) {
    return;
  }
}

Future<void> c() async {}
''');
  }

  test_ifConditionContainsMountedCheckInAssignmentLhs_thenReferenceToContext() async {
    // If-condition contains assignment with mounted check on LHS, then use of
    // BuildContext in if-then statement, is REPORTED.
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  await c();
  if (A(context.mounted).b = false) {
    Navigator.of(context);
  }
}

class A {
  bool b;
  A(this.b);
}

Future<void> c() async {}
''', [
      lint(134, 21),
    ]);
  }

  test_ifConditionContainsMountedCheckInAssignmentRhs_thenReferenceToContext() async {
    // If-condition contains assignment with mounted check in RHS, then use of
    // BuildContext in if-then statement, is OK.
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context, bool m) async {
  await c();
  if (m = context.mounted) {
    Navigator.of(context);
  }
}

Future<void> c() async {}
''');
  }

  test_ifConditionContainsMountedOrReferenceToContext() async {
    // Binary expression contains mounted check OR use of BuildContext, is
    // REPORTED.
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(
    BuildContext context, bool Function(BuildContext) condition) async {
  await c();
  if (context.mounted || condition(context)) {
    return;
  }
}

Future<void> c() async {}
''', [
      lint(161, 18),
    ]);
  }

  test_ifConditionContainsNotMountedAndReferenceToContext() async {
    // Binary expression contains not-mounted check AND use of BuildContext, is
    // REPORTED.
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(
    BuildContext context, bool Function(BuildContext) condition) async {
  await c();
  if (!context.mounted && condition(context)) {
    return;
  }
}

Future<void> c() async {}
''', [
      lint(162, 18),
    ]);
  }

  test_methodCall_targetIsAsync_contextRefFollows() async {
    // Method call with async code in target and use of BuildContext in
    // following statement, is REPORTED.
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context) async {
  (await c()).add(1);
  Navigator.of(context);
}

Future<List<int>> c() async => [];
''', [
      lint(103, 21),
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
