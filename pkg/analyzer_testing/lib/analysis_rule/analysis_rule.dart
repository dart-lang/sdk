// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/pubspec.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/source/file_source.dart';
import 'package:analyzer/src/lint/linter.dart'; // ignore: implementation_imports
import 'package:analyzer/src/lint/pub.dart'; // ignore: implementation_imports
import 'package:analyzer/src/lint/registry.dart'; // ignore: implementation_imports
import 'package:analyzer_testing/src/analysis_rule/pub_package_resolution.dart';
import 'package:analyzer_testing/utilities/utilities.dart';
import 'package:meta/meta.dart';

/// Returns an [ExpectedDiagnostic] with the given arguments.
///
/// Just a short-named helper for use in the `assert*Diagnostics` methods.
ExpectedDiagnostic error(
  DiagnosticCode code,
  int offset,
  int length, {
  Pattern? messageContains,
}) => ExpectedError(code, offset, length, messageContains: messageContains);

/// A base class for analysis rule tests that use test_reflective_loader.
abstract class AnalysisRuleTest extends PubPackageResolutionTest {
  /// The name of the analysis rule which this test is concerned with.
  String get analysisRule;

  /// Asserts that no diagnostics are reported when resolving [content].
  Future<void> assertNoPubspecDiagnostics(String content) async {
    newFile(testPackagePubspecPath, content);
    var errors = await _analyzePubspecFile(content);
    assertDiagnosticsIn(errors, []);
  }

  /// Asserts that [expectedDiagnostics] are reported when resolving [content].
  Future<void> assertPubspecDiagnostics(
    String content,
    List<ExpectedDiagnostic> expectedDiagnostics,
  ) async {
    newFile(testPackagePubspecPath, content);
    var errors = await _analyzePubspecFile(content);
    assertDiagnosticsIn(errors, expectedDiagnostics);
  }

  /// Returns an "expected diagnostic" for [analysisRule] (or [name], if given)
  /// at [offset] and [length].
  ///
  /// If given, [messageContains] is used to match against a diagnostic's
  /// message, and [correctionContains] is used to match against a diagnostic's
  /// correction message.
  ExpectedDiagnostic lint(
    int offset,
    int length, {
    Pattern? messageContains,
    Pattern? correctionContains,
    String? name,
  }) => ExpectedLint(
    name ?? analysisRule,
    offset,
    length,
    messageContains: messageContains,
    correctionContains: correctionContains,
  );

  @mustCallSuper
  @override
  void setUp() {
    if (!Registry.ruleRegistry.any((r) => r.name == analysisRule)) {
      throw Exception("Unrecognized rule: '$analysisRule'");
    }
    super.setUp();
    newAnalysisOptionsYamlFile(
      testPackageRootPath,
      analysisOptionsContent(experiments: experiments, rules: [analysisRule]),
    );
  }

  Future<List<Diagnostic>> _analyzePubspecFile(String content) async {
    var path = convertPath(testPackagePubspecPath);
    var pubspecRules = <AbstractAnalysisRule, PubspecVisitor<Object?>>{};
    var rules = Registry.ruleRegistry.where((r) => analysisRule == r.name);
    for (var rule in rules) {
      var visitor = rule.pubspecVisitor;
      if (visitor != null) {
        pubspecRules[rule] = visitor;
      }
    }

    if (pubspecRules.isEmpty) {
      throw UnsupportedError(
        'Resolving pubspec files only supported with rules with '
        'PubspecVisitors.',
      );
    }

    var sourceUri = resourceProvider.pathContext.toUri(path);
    var pubspecAst = Pubspec.parse(
      content,
      sourceUrl: sourceUri,
      resourceProvider: resourceProvider,
    );
    var listener = RecordingDiagnosticListener();
    var file = resourceProvider.getFile(path);
    var reporter = DiagnosticReporter(listener, FileSource(file, sourceUri));
    for (var entry in pubspecRules.entries) {
      entry.key.reporter = reporter;
      pubspecAst.accept(entry.value);
    }
    return [...listener.diagnostics];
  }
}
