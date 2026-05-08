// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/dart/ast/token.dart'; // ignore: implementation_imports

import '../analyzer.dart';
import '../diagnostic.dart' as diag;

const _desc = r'Avoid using braces in interpolation when not needed.';

final RegExp identifierPart = RegExp('[a-zA-Z0-9_]');

bool isIdentifierPart(Token? token) =>
    token is StringToken && token.lexeme.startsWith(identifierPart);

class UnnecessaryBraceInStringInterps extends AnalysisRule {
  UnnecessaryBraceInStringInterps()
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

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

  _Visitor(this.rule);

  @override
  void visitStringInterpolation(StringInterpolation node) {
    var expressions = node.elements.whereType<InterpolationExpression>();
    for (var expression in expressions) {
      var exp = expression.expression;
      if (exp is SimpleIdentifier) {
        var identifier = exp;
        if (!identifier.name.contains('\$')) {
          _check(expression);
        }
      } else if (exp is ThisExpression) {
        _check(expression);
      } else if (exp is TypeLiteral) {
        var type = exp.type;
        if (type.typeArguments == null &&
            type.importPrefix == null &&
            type.question == null &&
            !type.name.lexeme.contains('\$')) {
          _check(expression);
        }
      }
    }
  }

  void _check(InterpolationExpression expression) {
    var bracket = expression.rightBracket;
    if (bracket != null && !isIdentifierPart(bracket.next)) {
      rule.reportAtNode(expression);
    }
  }
}
