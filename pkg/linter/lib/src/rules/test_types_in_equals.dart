// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r'Test type of argument in `operator ==(Object other)`.';

class TestTypesInEquals extends LintRule {
  TestTypesInEquals()
      : super(
          name: LintNames.test_types_in_equals,
          description: _desc,
        );

  @override
  LintCode get lintCode => LinterLintCode.test_types_in_equals;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addAsExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitAsExpression(AsExpression node) {
    var declaration = node.thisOrAncestorOfType<MethodDeclaration>();
    var expression = node.expression;
    if (!_isEqualsOverride(declaration) || expression is! SimpleIdentifier) {
      return;
    }

    var parameters = declaration?.parameters;
    var parameterName = parameters?.parameterFragments.first?.name2;
    if (expression.name == parameterName) {
      var typeName = _getTypeName(declaration!);
      rule.reportLint(node, arguments: [typeName]);
    }
  }

  String _getTypeName(MethodDeclaration method) {
    var parent = method.parent;
    if (parent is ClassDeclaration) {
      return parent.name.lexeme;
    } else if (parent is EnumDeclaration) {
      return parent.name.lexeme;
    } else if (parent is MixinDeclaration) {
      return parent.name.lexeme;
    } else if (parent is ExtensionDeclaration) {
      if (parent.onClause case var onClause?) {
        return onClause.extendedType.toSource();
      }
    }
    return 'unknown';
  }

  bool _isEqualsOverride(MethodDeclaration? declaration) =>
      declaration != null &&
      declaration.isOperator &&
      declaration.name.lexeme == '==' &&
      declaration.parameters?.parameterFragments.length == 1;
}
