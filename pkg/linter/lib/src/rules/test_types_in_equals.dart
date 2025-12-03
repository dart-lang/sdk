// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../diagnostic.dart' as diag;

const _desc = r'Test type of argument in `operator ==(Object other)`.';

class TestTypesInEquals extends AnalysisRule {
  TestTypesInEquals()
    : super(name: LintNames.test_types_in_equals, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => diag.testTypesInEquals;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addAsExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

  _Visitor(this.rule);

  @override
  void visitAsExpression(AsExpression node) {
    var declaration = node.thisOrAncestorOfType<MethodDeclaration>();
    var expression = node.expression;
    if (!_isEqualsOverride(declaration) || expression is! SimpleIdentifier) {
      return;
    }

    var parameters = declaration?.parameters;
    var parameterName = parameters?.parameterFragments.first?.name;
    if (expression.name == parameterName) {
      var typeName = _getTypeName(declaration!);
      rule.reportAtNode(node, arguments: [typeName]);
    }
  }

  String _getTypeName(MethodDeclaration method) {
    var parent = method.parent;
    if (parent is ClassDeclaration) {
      return parent.namePart.typeName.lexeme;
    } else if (parent is EnumDeclaration) {
      return parent.namePart.typeName.lexeme;
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
