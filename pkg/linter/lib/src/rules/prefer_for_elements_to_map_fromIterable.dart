// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: file_names
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';

const _desc = r'Prefer `for` elements when building maps from iterables.';

class PreferForElementsToMapFromIterable extends LintRule {
  PreferForElementsToMapFromIterable()
    : super(
        name: LintNames.prefer_for_elements_to_map_fromIterable,
        description: _desc,
      );

  @override
  DiagnosticCode get diagnosticCode =>
      LinterLintCode.preferForElementsToMapFromiterable;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this, context);
    registry.addInstanceCreationExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;
  final RuleContext context;

  _Visitor(this.rule, this.context);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression creation) {
    var element = creation.constructorName.element;
    if (element == null ||
        element.name != 'fromIterable' ||
        element.enclosingElement != context.typeProvider.mapElement) {
      return;
    }

    //
    // Ensure that the arguments have the right form.
    //
    var arguments = creation.argumentList.arguments;
    if (arguments.length != 3) {
      return;
    }

    // TODO(srawlins): Handle named arguments anywhere.
    var secondArg = arguments[1];
    var thirdArg = arguments[2];

    var keyClosure =
        _extractClosure('key', secondArg) ?? _extractClosure('key', thirdArg);
    var valueClosure =
        _extractClosure('value', thirdArg) ??
        _extractClosure('value', secondArg);
    if (keyClosure == null || valueClosure == null) {
      return;
    }

    rule.reportAtNode(creation);
  }

  FunctionExpression? _extractClosure(String name, Expression argument) {
    if (argument is NamedExpression && argument.name.label.name == name) {
      var expression = argument.expression.unParenthesized;
      if (expression is FunctionExpression) {
        var parameters = expression.parameters?.parameters;
        if (parameters != null &&
            parameters.length == 1 &&
            parameters.first.isRequired) {
          if (expression.hasSingleExpressionBody) {
            return expression;
          }
        }
      }
    }
    return null;
  }
}

extension on FunctionExpression {
  /// Whether this has a single expression body, which could be a single
  /// return statement in a block function body.
  bool get hasSingleExpressionBody {
    var body = this.body;
    if (body is ExpressionFunctionBody) {
      return true;
    } else if (body is BlockFunctionBody) {
      var statements = body.block.statements;
      if (statements.length == 1) {
        return statements.first is ReturnStatement;
      }
    }
    return false;
  }
}
