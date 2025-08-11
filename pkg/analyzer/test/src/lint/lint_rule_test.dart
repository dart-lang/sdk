// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/source/source.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:test/test.dart';

import '../../generated/test_support.dart';

main() {
  group('lint rule', () {
    group('error code reporting', () {
      test('reportLintForToken (custom)', () {
        var rule = TestRule();
        var listener = GatheringDiagnosticListener();
        var reporter = DiagnosticReporter(listener, _MockSource('mock'));
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
        var reporter = DiagnosticReporter(listener, _MockSource('mock'));
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
        var reporter = DiagnosticReporter(listener, _MockSource('mock'));
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
        var reporter = DiagnosticReporter(listener, _MockSource('mock'));
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
  );

  static const LintCode customCode = LintCode(
    'hash_and_equals',
    'Override `==` if overriding `hashCode`.',
    correctionMessage: 'Implement `==`.',
  );

  TestRule() : super(name: 'test_rule', description: '');

  @override
  List<DiagnosticCode> get diagnosticCodes => [code, customCode];
}

class _MockSource implements Source {
  @override
  final String fullName;

  _MockSource(this.fullName);

  @override
  noSuchMethod(Invocation invocation) {
    throw StateError('Unexpected invocation of ${invocation.memberName}');
  }
}
