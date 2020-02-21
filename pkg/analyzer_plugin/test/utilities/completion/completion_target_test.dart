// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_ast_factory.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/token.dart'
    show SyntheticBeginToken, SyntheticToken;
import 'package:analyzer/src/dart/scanner/reader.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/string_source.dart';
import 'package:analyzer_plugin/src/utilities/completion/completion_target.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CompletionTargetTest);
  });
}

@reflectiveTest
class CompletionTargetTest {
  /// Parse a dangling expression (no parent node). The angular plugin, for
  /// instance, does this.
  Expression parseDanglingDart(String code) {
    final reader = CharSequenceReader(code);
    var featureSet = FeatureSet.forTesting(sdkVersion: '2.2.2');
    final scanner = Scanner(null, reader, null)..configureFeatures(featureSet);
    final source = StringSource(code, 'test.dart');
    final listener = _ErrorCollector();
    final parser = Parser(
      source,
      listener,
      languageVersion: scanner.languageVersion,
      featureSet: featureSet,
    );

    return parser.parseExpression(scanner.tokenize());
  }

  void test_danglingExpressionCompletionIsValid() {
    // Test that users can parse dangling expressions of dart and autocomplete
    // them without crash/with the correct offset information.
    final snippet = wrapForCompliance(parseDanglingDart('identifier'));
    final completionTarget =
        // ignore: deprecated_member_use
        CompletionTarget.forOffset(null, 1, entryPoint: snippet);
    expect(completionTarget.offset, 1);
    final replacementRange = completionTarget.computeReplacementRange(1);
    expect(replacementRange.offset, 0);
    expect(replacementRange.length, 'identifier'.length);
  }

  Expression wrapForCompliance(Expression expression) {
    // TODO(mfairhurst) This should be performed for clients or the need should
    // be dropped. It's a fairly valid invariant that all autocompletion target
    // expressions should have parents, and one we can enforce via synthetics.
    // But clients should not be doing this ideally.
    return astFactory.parenthesizedExpression(
        SyntheticBeginToken(TokenType.OPEN_PAREN, expression.offset)
          ..next = expression.beginToken,
        expression,
        SyntheticToken(TokenType.CLOSE_PAREN, expression.end));
  }
}

/// A simple error listener that collects errors into an [AnalyzerErrorGroup].
class _ErrorCollector extends AnalysisErrorListener {
  final _errors = <AnalysisError>[];

  _ErrorCollector();

  /// Whether any errors where collected.
  bool get hasErrors => _errors.isNotEmpty;

  @override
  void onError(AnalysisError error) => _errors.add(error);
}
