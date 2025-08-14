// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_state.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer/src/test_utilities/lint_registration_mixin.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReplacedLintUseTest);
  });
}

class RemovedLint extends LintRule {
  RemovedLint()
    : super(
        name: 'removed_lint',
        state: RuleState.removed(since: dart3),
        description: '',
      );

  @override
  DiagnosticCode get diagnosticCode => throw UnimplementedError();
}

@reflectiveTest
class ReplacedLintUseTest extends PubPackageResolutionTest
    with LintRegistrationMixin {
  @override
  void setUp() {
    super.setUp();
    registerLintRule(RemovedLint());
  }

  @override
  Future<void> tearDown() {
    unregisterLintRules();
    return super.tearDown();
  }

  @FailingTest(
    reason: 'Diagnostic reporting disabled',
    issue: 'https://github.com/dart-lang/sdk/issues/51214',
  )
  test_file() async {
    await assertErrorsInCode(
      r'''
// ignore_for_file: removed_lint

void f() { }
''',
      [error(WarningCode.removedLintUse, 20, 12)],
    );
  }

  @FailingTest(
    reason: 'Diagnostic reporting disabled',
    issue: 'https://github.com/dart-lang/sdk/issues/51214',
  )
  test_line() async {
    await assertErrorsInCode(
      r'''
// ignore: removed_lint
void f() { }
''',
      [error(WarningCode.removedLintUse, 11, 12)],
    );
  }
}
