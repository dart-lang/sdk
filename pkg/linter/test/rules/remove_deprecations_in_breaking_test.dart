// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveDeprecatedInBreakingVersionTest);
  });
}

@reflectiveTest
class RemoveDeprecatedInBreakingVersionTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.remove_deprecations_in_breaking_versions;

  test_breakingBuild() async {
    await testVersion('2.0.0+mybuild', isProblem: false);
  }

  test_breakingFirstMajor() async {
    await testVersion('1.0.0', isProblem: true);
  }

  test_breakingFirstMinor() async {
    await testVersion('0.1.0', isProblem: true);
  }

  test_breakingMajor() async {
    await testVersion('2.0.0', isProblem: true);
  }

  test_breakingMinor() async {
    await testVersion('0.1.0', isProblem: true);
  }

  test_breakingPrerelease() async {
    await testVersion('2.0.0-dev', isProblem: true);
  }

  test_MinorIncrement() async {
    await testVersion('2.1.0', isProblem: false);
  }

  test_minorIncrement() async {
    await testVersion('2.1.0', isProblem: false);
  }

  test_onlyHiglightConstructorName() async {
    newFile(testPackagePubspecPath, '''
name: foo
version: 1.0.0
environment:
  sdk: ^3.9.0
''');
    var p =
        "@Deprecated('Please stop using this before it explodes!') foo() {}";
    await assertDiagnostics(p, [lint(1, 10)]);
  }

  test_patchIncrement() async {
    await testVersion('2.0.1', isProblem: false);
  }

  test_patchIncrementFromZero() async {
    await testVersion('0.0.1', isProblem: false);
  }

  test_PatchIncrementFromZeroOne() async {
    await testVersion('0.1.1', isProblem: false);
  }

  test_Zero() async {
    await testVersion('0.0.0', isProblem: true);
  }

  Future<void> testVersion(String version, {required bool isProblem}) async {
    newFile(testPackagePubspecPath, '''
name: foo
version: $version
environment:
  sdk: ^3.9.0
''');
    var p = '@deprecated foo() {}';
    await assertDiagnostics(p, [if (isProblem) lint(1, 10)]);
  }
}
