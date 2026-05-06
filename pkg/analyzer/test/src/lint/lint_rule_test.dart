// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/source/file_source.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer_testing/resource_provider_mixin.dart';
import 'package:test/test.dart';

import '../../generated/test_support.dart';

main() {
  var testSources = _TestSources();

  group('lint rule', () {
    group('error code reporting', () {
      test('reportLintForToken (custom)', () {
        var rule = TestRule();
        var listener = GatheringDiagnosticListener();
        var reporter = DiagnosticReporter(listener, testSources.source('mock'));
        rule.reporter = reporter;

        rule.reportAtToken(
          SimpleToken(TokenType.SEMICOLON, 0),
          diagnosticCode: TestRule.customCode,
        );
        expect(listener.diagnostics.single.diagnosticCode, TestRule.customCode);
      });
      test('reportLintForToken (default)', () {
        var rule = TestRule();
        var listener = GatheringDiagnosticListener();
        var reporter = DiagnosticReporter(listener, testSources.source('mock'));
        rule.reporter = reporter;

        rule.reportAtToken(
          SimpleToken(TokenType.SEMICOLON, 0),
          diagnosticCode: TestRule.code,
        );
        expect(listener.diagnostics.single.diagnosticCode, TestRule.code);
      });
      test('reportLint (custom)', () {
        var rule = TestRule();
        var listener = GatheringDiagnosticListener();
        var reporter = DiagnosticReporter(listener, testSources.source('mock'));
        rule.reporter = reporter;

        var node = EmptyStatementImpl(
          semicolon: SimpleToken(TokenType.SEMICOLON, 0),
        );
        rule.reportAtNode(node, diagnosticCode: TestRule.customCode);
        expect(listener.diagnostics.single.diagnosticCode, TestRule.customCode);
      });
      test('reportLint (default)', () {
        var rule = TestRule();
        var listener = GatheringDiagnosticListener();
        var reporter = DiagnosticReporter(listener, testSources.source('mock'));
        rule.reporter = reporter;

        var node = EmptyStatementImpl(
          semicolon: SimpleToken(TokenType.SEMICOLON, 0),
        );
        rule.reportAtNode(node, diagnosticCode: TestRule.code);
        expect(listener.diagnostics.single.diagnosticCode, TestRule.code);
      });
    });
  });
}

class TestRule extends MultiAnalysisRule {
  static const LintCode code = LintCode(
    'test_rule',
    'Test rule.',
    correctionMessage: 'Try test rule.',
    uniqueName: 'LintCode.test_rule',
  );

  static const LintCode customCode = LintCode(
    'hash_and_equals',
    'Override `==` if overriding `hashCode`.',
    correctionMessage: 'Implement `==`.',
    uniqueName: 'LintCode.hash_and_equals',
  );

  TestRule() : super(name: 'test_rule', description: '');

  @override
  List<DiagnosticCode> get diagnosticCodes => [code, customCode];
}

class _TestSources with ResourceProviderMixin {
  FileSource source(String name) => FileSource(newFile('/$name.dart', ''));
}
