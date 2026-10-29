// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/utilities/extensions/ast.dart'; // ignore: implementation_imports

import '../analyzer.dart';
import '../diagnostic.dart' as diag;

const _desc = r'Avoid using braces in interpolation when not needed.';

class UnnecessaryBraceInStringInterps extends AnalysisRule {
  new()
    : super(
        name: LintNames.unnecessary_brace_in_string_interps,
        description: _desc,
      );

  @override
  DiagnosticCode get diagnosticCode => diag.unnecessaryBraceInStringInterps;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addStringInterpolation(this, visitor);
  }
}

class _Visitor(final AnalysisRule rule) extends SimpleAstVisitor<void> {
  @override
  void visitStringInterpolation(StringInterpolation node) {
    var expressions = node.elements.whereType<InterpolationExpression>();
    for (var expression in expressions) {
      var exp = expression.expression;
      var name = switch (exp) {
        SimpleIdentifier() => exp.name,
        ThisExpression() => 'this',
        TypeLiteral(:var type)
            when type.typeArguments == null &&
                type.importPrefix == null &&
                type.question == null =>
          type.name.lexeme,
        _ => null,
      };
      if (name != null && expression.canRemoveBracesAround(name)) {
        rule.reportAtNode(expression);
      }
    }
  }
}
