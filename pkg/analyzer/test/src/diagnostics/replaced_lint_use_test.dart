// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/hint_codes.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer/src/lint/registry.dart';
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
          group: Group.style,
          state: State.removed(since: dart3, replacedBy: 'replacing_lint'),
          description: '',
          details: '',
        );
}

@reflectiveTest
class ReplacedLintUseTest extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();
    Registry.ruleRegistry.register(RemovedLint());
    Registry.ruleRegistry.register(ReplacingLint());
  }

  test_file() async {
    await assertErrorsInCode(r'''
// ignore_for_file: removed_lint

void f() { }
''', [
      error(HintCode.REPLACED_LINT_USE, 20, 12),
    ]);
  }

  test_line() async {
    await assertErrorsInCode(r'''
// ignore: removed_lint
void f() { }
''', [
      error(HintCode.REPLACED_LINT_USE, 11, 12),
    ]);
  }
}

class ReplacingLint extends LintRule {
  ReplacingLint()
      : super(
          name: 'replacing_lint',
          group: Group.style,
          state: State.removed(since: dart3),
          description: '',
          details: '',
        );
}
