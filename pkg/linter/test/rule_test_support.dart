// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:analyzer_testing/src/analysis_rule/pub_package_resolution.dart';
import 'package:linter/src/rules.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart';

export 'package:analyzer/src/error/codes.dart';
export 'package:analyzer_testing/analysis_rule/analysis_rule.dart' show error;
export 'package:linter/src/lint_names.dart';

mixin LanguageVersion219Mixin on PubPackageResolutionTest {
  @override
  String? get testPackageLanguageVersion => '2.19';
}

/// A base test class for all of the "built-in" lint rules.
abstract class LintRuleTest extends AnalysisRuleTest {
  static bool _lintRulesAreRegistered = false;

  @override
  String get analysisRule => lintRule;

  /// The lint rule being tested.
  String get lintRule;

  /// Asserts that the given [content] has diagnostics at the marked ranges.
  ///
  /// See the [TestCode] class for more information about the markup format.
  Future<void> assertDiagnosticsFromMarkup(String content) {
    // TODO(brianwilkerson): Generalize this method and remove the specialized
    //  methods below in favor of this one.
    var testCode = TestCode.parse(content);
    if (testCode.ranges.isEmpty) {
      fail('Either ranges or expected diagnostics must be provided.');
    }
    var expectedDiagnostics = [
      for (var range in testCode.ranges)
        lint(range.sourceRange.offset, range.sourceRange.length),
    ];
    return super.assertDiagnostics(testCode.code, expectedDiagnostics);
  }

  Future<void> assertDiagnosticsInBinFromMarkup(String content) async {
    var testCode = TestCode.parse(content);
    var filePath = '$testPackageRootPath/bin/bin.dart';
    newFile(filePath, testCode.code);
    var expectedDiagnostics = [
      for (var range in testCode.ranges)
        lint(range.sourceRange.offset, range.sourceRange.length),
    ];
    await assertDiagnosticsInFile(filePath, expectedDiagnostics);
  }

  Future<void> assertDiagnosticsInFileNameFromMarkup(
    String fileName,
    String content,
  ) async {
    var testCode = TestCode.parse(content);
    var filePath = '$testPackageLibPath/$fileName';
    newFile(filePath, testCode.code);
    var expectedDiagnostics = [
      for (var range in testCode.ranges)
        lint(range.sourceRange.offset, range.sourceRange.length),
    ];
    await assertDiagnosticsInFile(filePath, expectedDiagnostics);
  }

  Future<void> assertDiagnosticsInHookFromMarkup(
    String fileName,
    String content,
  ) async {
    var testCode = TestCode.parse(content);
    var filePath = '$testPackageRootPath/hook/$fileName';
    newFile(filePath, testCode.code);
    var expectedDiagnostics = [
      for (var range in testCode.ranges)
        lint(range.sourceRange.offset, range.sourceRange.length),
    ];
    await assertDiagnosticsInFile(filePath, expectedDiagnostics);
  }

  /// Asserts that the given [content] has diagnostics at the marked ranges when
  /// the file is in the `test` directory of the test package.
  ///
  /// See the [TestCode] class for more information about the markup format.
  Future<void> assertDiagnosticsInTestDirFromMarkup(String content) async {
    var testCode = TestCode.parse(content);
    var filePath = '$testPackageRootPath/test/test.dart';
    newFile(filePath, testCode.code);
    var expectedDiagnostics = [
      for (var range in testCode.ranges)
        lint(range.sourceRange.offset, range.sourceRange.length),
    ];
    await assertDiagnosticsInFile(filePath, expectedDiagnostics);
  }

  Future<void> assertNoDiagnosticsInFileName(
    String fileName,
    String content,
  ) async {
    var filePath = '$testPackageLibPath/$fileName';
    newFile(filePath, content);
    await assertNoDiagnosticsInFile(filePath);
  }

  Future<void> assertNoDiagnosticsInHook(
    String fileName,
    String content,
  ) async {
    var filePath = '$testPackageRootPath/hook/$fileName';
    newFile(filePath, content);
    await assertNoDiagnosticsInFile(filePath);
  }

  /// Assert that the given [content] has no diagnostics when the file is in the
  /// `test` directory of the test package.
  Future<void> assertNoDiagnosticsInTestDir(String content) async {
    var filePath = '$testPackageRootPath/test/test.dart';
    newFile(filePath, content);
    await assertNoDiagnosticsInFile(filePath);
  }

  @mustCallSuper
  @override
  void setUp() {
    if (!_lintRulesAreRegistered) {
      registerLintRules();
      _lintRulesAreRegistered = true;
    }
    rule = Registry.ruleRegistry.rules.firstWhere(
      (r) => r.name == analysisRule,
    );
    super.setUp();
  }
}
