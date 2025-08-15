// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';

const _desc =
    r'Use a non-nullable type for a final variable initialized '
    'with a non-nullable value.';

class UnnecessaryNullableForFinalVariableDeclarations extends LintRule {
  UnnecessaryNullableForFinalVariableDeclarations()
    : super(
        name: LintNames.unnecessary_nullable_for_final_variable_declarations,
        description: _desc,
      );

  @override
  DiagnosticCode get diagnosticCode =>
      LinterLintCode.unnecessaryNullableForFinalVariableDeclarations;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this, context);
    registry.addFieldDeclaration(this, visitor);
    registry.addPatternVariableDeclaration(this, visitor);
    registry.addTopLevelVariableDeclaration(this, visitor);
    registry.addVariableDeclarationStatement(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  final RuleContext context;
  _Visitor(this.rule, this.context);

  void check(AstNode node) {
    if (node is! DeclaredVariablePattern) return;
    var type = node.declaredFragment?.element.type;
    if (type == null) return;
    if (type is DynamicType) return;
    var valueType = node.matchedValueType;
    if (valueType == null) return;
    if (context.typeSystem.isNullable(type) &&
        context.typeSystem.isNonNullable(valueType)) {
      rule.reportAtToken(node.name);
    }
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    for (var variable in node.fields.variables) {
      if (Identifier.isPrivateName(variable.name.lexeme) || node.isStatic) {
        _visit(variable);
      }
    }
  }

  @override
  void visitPatternVariableDeclaration(PatternVariableDeclaration node) {
    if (node.keyword.keyword != Keyword.FINAL) return;

    var pattern = node.pattern;
    if (pattern is RecordPattern) {
      for (var field in pattern.fields) {
        check(field.pattern);
      }
    }
    if (pattern is ListPattern) {
      pattern.elements.forEach(check);
    }
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    node.variables.variables.forEach(_visit);
  }

  @override
  void visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    node.variables.variables.forEach(_visit);
  }

  void _visit(VariableDeclaration variable) {
    if (!variable.isFinal && !variable.isConst) return;
    if (variable.isSynthetic) return;

    var initializerType = variable.initializer?.staticType;
    if (initializerType == null) return;

    var declaredElement = variable.declaredFragment?.element;
    if (declaredElement == null || declaredElement.type is DynamicType) {
      return;
    }

    if (context.typeSystem.isNullable(declaredElement.type) &&
        context.typeSystem.isNonNullable(initializerType)) {
      rule.reportAtToken(variable.name);
    }
  }
}
