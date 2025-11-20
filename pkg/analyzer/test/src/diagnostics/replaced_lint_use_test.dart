// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_state.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart'
    as diag
    hide removedLint;
import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer/src/test_utilities/lint_registration_mixin.dart';
import 'package:linter/src/diagnostic.dart' as diag;
import 'package:linter/src/rules.dart' as linter;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReplacedLintUseTest);
  });
}

class RemovedLint extends AnalysisRule {
  RemovedLint()
    : super(
        name: 'removed_lint',
        state: RuleState.removed(since: dart3, replacedBy: 'replacing_lint'),
        description: '',
      );

  @override
  DiagnosticCode get diagnosticCode => diag.removedLint;
}

@reflectiveTest
class ReplacedLintUseTest extends PubPackageResolutionTest
    with LintRegistrationMixin {
  @override
  void setUp() {
    super.setUp();
    linter.registerLintRules();

    // TODO(paulberry): remove as part of fixing
    // https://github.com/dart-lang/sdk/issues/62040.
    writeTestPackageAnalysisOptionsFile('''
linter:
  rules:
    - unnecessary_ignore
''');

    registerLintRule(RemovedLint());
    registerLintRule(ReplacingLint());
  }

  @override
  Future<void> tearDown() {
    unregisterLintRules();
    for (var rule in Registry.ruleRegistry.rules) {
      Registry.ruleRegistry.unregisterLintRule(rule);
    }
    return super.tearDown();
  }

  test_file() async {
    await assertErrorsInCode(
      r'''
// ignore_for_file: removed_lint

void f() { }
''',
      [error(diag.replacedLintUse, 20, 12)],
    );
  }

  test_line() async {
    await assertErrorsInCode(
      r'''
// ignore: removed_lint
void f() { }
''',
      [error(diag.replacedLintUse, 11, 12)],
    );
  }
}

class ReplacingLint extends AnalysisRule {
  ReplacingLint()
    : super(
        name: 'replacing_lint',
        state: RuleState.removed(since: dart3),
        description: '',
      );

  @override
  DiagnosticCode get diagnosticCode =>
      const LintCode('replacing_lint', 'problem message');
}
