// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';

const _desc = r"Don't use constant patterns with type literals.";

class TypeLiteralInConstantPattern extends LintRule {
  TypeLiteralInConstantPattern()
    : super(
        name: LintNames.type_literal_in_constant_pattern,
        description: _desc,
      );

  @override
  DiagnosticCode get diagnosticCode =>
      LinterLintCode.typeLiteralInConstantPattern;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this, context);
    registry.addConstantPattern(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;
  final RuleContext context;

  _Visitor(this.rule, this.context);

  @override
  visitConstantPattern(ConstantPattern node) {
    // `const (MyType)` is fine.
    if (node.constKeyword != null) {
      return;
    }

    var expressionType = node.expression.staticType;
    if (expressionType != null && expressionType.isDartCoreType) {
      rule.reportAtNode(node);
    }
  }
}
