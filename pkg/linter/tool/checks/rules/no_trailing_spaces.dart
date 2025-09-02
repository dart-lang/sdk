// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:linter/src/analyzer.dart';

class NoTrailingSpaces extends LintRule {
  static const LintCode code = LinterLintCode.noTrailingSpaces;

  NoTrailingSpaces()
    : super(
        name: 'no_trailing_spaces',
        description:
            "Don't create string literals with trailing spaces in tests.",
      );

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    if (context.isInTestDirectory) {
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
        rule.reportAtToken(literal);
      }
    }
  }
}
