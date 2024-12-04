// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';

import '../analyzer.dart';
import '../extensions.dart';

const _desc =
    r'Start the name of the method with to/_to or as/_as if applicable.';

bool _beginsWithAsOrTo(String name) {
  var regExp = RegExp(r'(to|as|_to|_as)[A-Z]');
  return regExp.matchAsPrefix(name) != null;
}

bool _isVoid(TypeAnnotation? returnType) =>
    returnType is NamedType && returnType.type is VoidType;

class UseToAndAsIfApplicable extends LintRule {
  UseToAndAsIfApplicable()
      : super(
          name: LintNames.use_to_and_as_if_applicable,
          description: _desc,
        );

  @override
  LintCode get lintCode => LinterLintCode.use_to_and_as_if_applicable;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addMethodDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    var nodeParameters = node.parameters;
    if (!node.isGetter &&
        nodeParameters != null &&
        nodeParameters.parameters.isEmpty &&
        !_isVoid(node.returnType) &&
        !_beginsWithAsOrTo(node.name.lexeme) &&
        !node.hasInheritedMethod &&
        _checkBody(node.body)) {
      rule.reportLintForToken(node.name);
    }
  }

  bool _checkBody(FunctionBody body) {
    if (body is ExpressionFunctionBody) {
      return _checkExpression(body.expression);
    } else if (body is BlockFunctionBody && body.block.statements.length == 1) {
      var statement = body.block.statements.first;
      if (statement is ReturnStatement) {
        return _checkExpression(statement.expression);
      }
    }
    return false;
  }

  bool _checkExpression(Expression? rawExpression) {
    var expression = rawExpression?.unParenthesized;
    return expression is InstanceCreationExpression &&
        expression.argumentList.arguments.length == 1 &&
        expression.argumentList.arguments.first is ThisExpression;
  }
}
