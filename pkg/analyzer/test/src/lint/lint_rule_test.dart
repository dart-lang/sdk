// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/source/source.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:test/test.dart';

import '../../generated/test_support.dart';

main() {
  group('lint rule', () {
    group('error code reporting', () {
      test('reportLintForToken (custom)', () {
        var rule = TestRule();
        var reporter = CollectingReporter(
          GatheringDiagnosticListener(),
          _MockSource('mock'),
        );
        rule.reporter = reporter;

        rule.reportAtToken(
          SimpleToken(TokenType.SEMICOLON, 0),
          diagnosticCode: TestRule.customCode,
        );
        expect(reporter.code, TestRule.customCode);
      });
      test('reportLintForToken (default)', () {
        var rule = TestRule();
        var reporter = CollectingReporter(
          GatheringDiagnosticListener(),
          _MockSource('mock'),
        );
        rule.reporter = reporter;

        rule.reportAtToken(
          SimpleToken(TokenType.SEMICOLON, 0),
          diagnosticCode: TestRule.code,
        );
        expect(reporter.code, TestRule.code);
      });
      test('reportLint (custom)', () {
        var rule = TestRule();
        var reporter = CollectingReporter(
          GatheringDiagnosticListener(),
          _MockSource('mock'),
        );
        rule.reporter = reporter;

        var node = EmptyStatementImpl(
          semicolon: SimpleToken(TokenType.SEMICOLON, 0),
        );
        rule.reportAtNode(node, diagnosticCode: TestRule.customCode);
        expect(reporter.code, TestRule.customCode);
      });
      test('reportLint (default)', () {
        var rule = TestRule();
        var reporter = CollectingReporter(
          GatheringDiagnosticListener(),
          _MockSource('mock'),
        );
        rule.reporter = reporter;

        var node = EmptyStatementImpl(
          semicolon: SimpleToken(TokenType.SEMICOLON, 0),
        );
        rule.reportAtNode(node, diagnosticCode: TestRule.code);
        expect(reporter.code, TestRule.code);
      });
    });
  });
}

class CollectingReporter extends DiagnosticReporter {
  DiagnosticCode? code;

  CollectingReporter(super.listener, super.source);

  @override
  void atElement2(
    Element element,
    DiagnosticCode diagnosticCode, {
    List<Object>? arguments,
    List<DiagnosticMessage>? contextMessages,
    Object? data,
  }) {
    code = diagnosticCode;
  }

  @override
  void atNode(
    AstNode node,
    DiagnosticCode diagnosticCode, {
    List<Object>? arguments,
    List<DiagnosticMessage>? contextMessages,
    Object? data,
  }) {
    code = diagnosticCode;
  }

  @override
  void atToken(
    Token token,
    DiagnosticCode diagnosticCode, {
    List<Object>? arguments,
    List<DiagnosticMessage>? contextMessages,
    Object? data,
  }) {
    code = diagnosticCode;
  }
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
