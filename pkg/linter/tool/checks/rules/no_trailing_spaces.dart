// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:linter/src/analyzer.dart';

const _desc = r"Don't create string literals with trailing spaces in tests.";

class NoTrailingSpaces extends LintRule {
  static const LintCode code = LintCode('no_trailing_spaces', _desc,
      correctionMessage: 'Try removing the trailing spaces.',
      hasPublishedDocs: true);

  NoTrailingSpaces()
      : super(
          name: 'no_trailing_spaces',
          description: _desc,
        );

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    if (context.definingUnit.unit.inTestDir) {
      var visitor = _Visitor(this);
      registry.addMethodInvocation(this, visitor);
    }
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    var arguments = node.argumentList.arguments;
    for (var sourceString in arguments) {
      if (sourceString is! SimpleStringLiteral) return;

      var literal = sourceString.literal;
      if (literal is! StringToken) return;

      if (literal.lexeme.contains(' \n')) {
        rule.reportLintForToken(literal);
      }
    }
  }
}
