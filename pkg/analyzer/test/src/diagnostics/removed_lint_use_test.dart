// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer/src/test_utilities/lint_registration_mixin.dart';
import 'package:linter/src/rules.dart' as linter;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemovedLintUseTest);
  });
}

@reflectiveTest
class RemovedLintUseTest extends PubPackageResolutionTest
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
  }

  @override
  Future<void> tearDown() {
    for (var rule in Registry.ruleRegistry.rules) {
      Registry.ruleRegistry.unregisterLintRule(rule);
    }
    return super.tearDown();
  }

  test_file() async {
    await assertErrorsInCode(
      r'''
// ignore_for_file: super_goes_last

void f() { }
''',
      [error(diag.removedLintUse, 20, 15)],
    );
  }

  test_line() async {
    await assertErrorsInCode(
      r'''
// ignore: super_goes_last
void f() { }
''',
      [error(diag.removedLintUse, 11, 15)],
    );
  }
}
