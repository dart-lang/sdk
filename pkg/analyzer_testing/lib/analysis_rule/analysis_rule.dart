// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// @docImport 'package:analyzer/dart/analysis/results.dart';
library;

import 'dart:convert' show json;

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/pubspec.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/file_source.dart';
import 'package:analyzer/src/lint/pub.dart'; // ignore: implementation_imports
import 'package:analyzer/src/lint/registry.dart'; // ignore: implementation_imports
import 'package:analyzer_testing/src/analysis_rule/pub_package_resolution.dart';
import 'package:analyzer_testing/utilities/extensions/diagnostic_code.dart';
import 'package:analyzer_testing/utilities/utilities.dart';
import 'package:meta/meta.dart';

export 'package:analyzer_testing/src/analysis_rule/pub_package_resolution.dart'
    show PackageBuilder;

ExpectedContextMessage contextMessage(
  File file,
  int offset,
  int length, {
  @Deprecated('Use textContains instead') String? text,
  List<Pattern> textContains = const [],
}) {
  assert(
    text == null || textContains.isEmpty,
    'Use only one of text or textContains',
  );
  if (text != null) {
    textContains = [text];
  }
  return ExpectedContextMessage(
    file,
    offset,
    length,
    textContains: textContains,
  );
}

/// Returns an [ExpectedDiagnostic] with the given arguments.
///
/// Just a short-named helper for use in the `assert*Diagnostics` methods.
ExpectedDiagnostic error(
  DiagnosticCode code,
  int offset,
  int length, {
  @Deprecated('Use messageContainsAll instead') Pattern? messageContains,
  List<Pattern> messageContainsAll = const [],
  Pattern? correctionContains,
  List<ExpectedContextMessage>? contextMessages,
}) {
  assert(
    messageContains == null || messageContainsAll.isEmpty,
    'Use only one of messageContains or messageContainsAll',
  );
  if (messageContains != null) {
    messageContainsAll = [messageContains];
  }
  return ExpectedError(
    code,
    offset,
    length,
    messageContainsAll: messageContainsAll,
    correctionContains: correctionContains,
    contextMessages: contextMessages,
  );
}

/// A base class for analysis rule tests that use test_reflective_loader.
abstract class AnalysisRuleTest extends PubPackageResolutionTest {
  /// The [AbstractAnalysisRule] under test.
  ///
  /// In a test class that extends [AnalysisRuleTest], this field must be set
  /// from within [setUp], before calling `super.setUp`.
  AbstractAnalysisRule rule = _SentinelRule();

  /// The name of the analysis rule which this test is concerned with.
  late String _analysisRule;

  /// The name of the analysis rule which this test is concerned with.
  // TODO(srawlins): In a major release, remove this getter, and implement
  // `_analysisRule` as `=> rule.name;`.
  @Deprecated("Set 'rule' in 'setUp' instead")
  String get analysisRule => 'sentinel';

  /// Asserts that no diagnostics are reported when resolving [content].
  ///
  /// Note: Be sure to `await` any use of this API, to avoid stale analysis
  /// results (See [DisposedAnalysisContextResult]).
  Future<void> assertNoPubspecDiagnostics(String content) async {
    newFile(testPackagePubspecPath, content);
    var errors = await _analyzePubspecFile(content);
    assertDiagnosticsIn(errors, []);
  }

  /// Asserts that [expectedDiagnostics] are reported when resolving [content].
  ///
  /// Note: Be sure to `await` any use of this API, to avoid stale analysis
  /// results (See [DisposedAnalysisContextResult]).
  Future<void> assertPubspecDiagnostics(
    String content,
    List<ExpectedDiagnostic> expectedDiagnostics,
  ) async {
    newFile(testPackagePubspecPath, content);
    var errors = await _analyzePubspecFile(content);
    assertDiagnosticsIn(errors, expectedDiagnostics);
  }

  @override
  String correctionMessage(List<Diagnostic> diagnostics) {
    var buffer = StringBuffer();
    diagnostics.sort((first, second) => first.offset.compareTo(second.offset));
    buffer.writeln();
    buffer.writeln('To accept the current state, expect:');
    for (var actual in diagnostics) {
      if (actual.diagnosticCode is LintCode) {
        buffer.write('  lint(');
      } else {
        buffer.write('  error(${actual.diagnosticCode.constantName}, ');
      }
      buffer.write('${actual.offset}, ${actual.length}');
      buffer.writeln('),');
    }

    return buffer.toString();
  }

  /// Returns an "expected diagnostic" for [rule] (or [name], if given)
  /// at [offset] and [length].
  ///
  /// If given, [messageContains] is used to match against a diagnostic's
  /// message, and [correctionContains] is used to match against a diagnostic's
  /// correction message.
  ExpectedDiagnostic lint(
    int offset,
    int length, {
    Pattern? correctionContains,
    @Deprecated('Use messageContainsAll instead') Pattern? messageContains,
    List<Pattern> messageContainsAll = const [],
    String? name,
    List<ExpectedContextMessage>? contextMessages,
  }) {
    assert(
      messageContains == null || messageContainsAll.isEmpty,
      'Use only one of messageContains or messageContainsAll',
    );
    if (messageContains != null) {
      messageContainsAll = [messageContains];
    }
    return ExpectedLint(
      name ?? _analysisRule,
      offset,
      length,
      messageContainsAll: messageContainsAll,
      correctionContains: correctionContains,
      contextMessages: contextMessages,
    );
  }

  @mustCallSuper
  @override
  void setUp() {
    // TODO(srawlins): In a major release, change this logic to just ensure that
    // `rule` has been set to an analysis rule instance other than
    // `_SentinelRule`.
    if (rule is _SentinelRule) {
      if (analysisRule == 'sentinel') {
        throw StateError('The `rule` field must be set in the `setUp` method.');
      }
      // The developer is using the deprecated `analysisRule` to set the
      // rule-under-test.
      _analysisRule = analysisRule;
    } else {
      _analysisRule = rule.name;
      Registry.ruleRegistry.registerLintRule(rule);
    }
    super.setUp();
    newAnalysisOptionsYamlFile(
      testPackageRootPath,
      analysisOptionsContent(experiments: experiments, rules: [_analysisRule]),
    );
  }

  @override
  String unexpectedMessage(List<Diagnostic> unmatchedActual) {
    var buffer = StringBuffer();
    if (buffer.isNotEmpty) {
      buffer.writeln();
    }
    buffer.writeln('Found but did not expect:');
    for (var actual in unmatchedActual) {
      buffer.write('  $_analysisRule.${actual.diagnosticCode.lowerCaseName} [');
      buffer.write('${actual.offset}, ${actual.length}, ${actual.message}');
      if (actual.correctionMessage case Pattern correctionMessage) {
        buffer.write(', ');
        buffer.write(json.encode(correctionMessage));
      }
      buffer.writeln(']');
    }
    return buffer.toString();
  }

  Future<List<Diagnostic>> _analyzePubspecFile(String content) async {
    var path = convertPath(testPackagePubspecPath);
    var pubspecRules = <AbstractAnalysisRule, PubspecVisitor<Object?>>{};
    var rules = Registry.ruleRegistry.where((r) => _analysisRule == r.name);
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

/// A sentinel [AnalysisRule] for use while [AnalysisRuleTest.analysisRule] is
/// still available but deprecated, and using it's replacement,
/// [AnalysisRuleTest.rule], is not yet mandatory.
final class _SentinelRule extends AnalysisRule {
  _SentinelRule() : super(name: 'sentinel', description: 'sentinel');

  @override
  dynamic noSuchMethod(invocation) => super.noSuchMethod(invocation);
}
