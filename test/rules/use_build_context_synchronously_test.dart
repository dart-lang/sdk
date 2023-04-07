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

  test_awaitBeforeIfStatement_beforeReferenceToContext() async {
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context, Future<bool> condition) async {
  var b = await condition;
  if (b) {
    Navigator.of(context);
  }
}
''', [
      lint(145, 21),
    ]);
  }

  test_awaitBeforeReferenceToContext_inClosure() async {
    // todo (pq): what about closures?
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context, Future<bool> condition) async {
  await condition;
  f1(() {
    f2(context);
  });
}

void f1(Function f) {}
void f2(BuildContext c) {}
''');
  }

  // https://github.com/dart-lang/linter/issues/3457
  test_awaitInIfCondition_aboveReferenceToContext() async {
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context, Future<bool> condition) async {
  if (await condition) {
    Navigator.of(context);
  }
}

''', [
      lint(132, 21),
    ]);
  }

  test_awaitInIfCondition_beforeReferenceToContext() async {
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context, Future<bool> condition) async {
  if (await condition) return;
  Navigator.of(context);
}
''', [
      lint(136, 21),
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

void foo(BuildContext context, Future<bool> condition) async {
  Navigator.of(context);
  if (1 == 2) {
    await condition;
    return;
  }
}
''');
  }

  test_awaitInIfThen_beforeReferenceToContext() async {
    // TODO(srawlins): I think this should report a lint, since an `await` is
    // encountered in the if-body.
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context, Future<bool> condition) async {
  if (1 == 2) {
    await condition;
    return;
  }
  Navigator.of(context);
}
''');
  }

  test_awaitInIfThenAndExitInElse_afterReferenceToContext() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context, Future<bool> condition) async {
  Navigator.of(context);
  if (1 == 2) {
    await condition;
  } else {
    await condition;
    return;
  }
}
''');
  }

  test_awaitInIfThenAndExitInElse_beforeReferenceToContext() async {
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context, Future<bool> condition) async {
  if (1 == 2) {
    await condition;
  } else {
    await condition;
    return;
  }
  Navigator.of(context);
}
''', [
      lint(190, 21),
    ]);
  }

  test_awaitInWhileBody_afterReferenceToContext() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context, Future<void> condition) async {
  Navigator.of(context);
  while (true) {
    await condition;
    break;
  }
}
''');
  }

  test_awaitInWhileBody_beforeReferenceToContext() async {
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context, Future<void> condition) async {
  while (true) {
    await condition;
    break;
  }
  Navigator.of(context);
}
''', [
      lint(158, 21),
    ]);
  }

  test_awaitThenExitInIfThenAndElse_afterReferenceToContext() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context, Future<bool> condition) async {
  Navigator.of(context);
  if (1 == 2) {
    await condition;
    return;
  } else {
    await condition;
    return;
  }
}
''');
  }

  test_awaitThenExitInIfThenAndElse_beforeReferenceToContext() async {
    await assertDiagnostics(r'''
import 'package:flutter/widgets.dart';

void foo(BuildContext context, Future<bool> condition) async {
  if (1 == 2) {
    await condition;
    return;
  } else {
    await condition;
    return;
  }
  Navigator.of(context);
}
''', [
      // No lint.
      error(WarningCode.DEAD_CODE, 202, 22),
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
