// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';

const _desc =
    r"Don't reassign references to parameters of functions or methods.";

bool _isDefaultFormalParameterWithDefaultValue(FormalParameter parameter) =>
    parameter is DefaultFormalParameter && parameter.defaultValue != null;

bool _isFormalParameterReassigned(
  FormalParameter parameter,
  AssignmentExpression assignment,
) {
  var leftHandSide = assignment.leftHandSide;
  return leftHandSide is SimpleIdentifier &&
      leftHandSide.element == parameter.declaredFragment?.element;
}

class ParameterAssignments extends AnalysisRule {
  ParameterAssignments()
    : super(name: LintNames.parameter_assignments, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => LinterLintCode.parameterAssignments;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addFunctionDeclaration(this, visitor);
    registry.addMethodDeclaration(this, visitor);
  }
}

class _DeclarationVisitor extends RecursiveAstVisitor<void> {
  final FormalParameter parameter;
  final AnalysisRule rule;
  final bool paramIsNotNullByDefault;
  final bool paramDefaultsToNull;
  bool hasBeenAssigned = false;

  _DeclarationVisitor(
    this.parameter,
    this.rule, {
    required this.paramIsNotNullByDefault,
    required this.paramDefaultsToNull,
  });

  Element? get parameterElement => parameter.declaredFragment?.element;

  void checkPatternElements(DartPattern node) {
    NodeList<PatternField>? fields;
    if (node is RecordPattern) fields = node.fields;
    if (node is ObjectPattern) fields = node.fields;
    if (fields != null) {
      for (var field in fields) {
        if (field.pattern.element == parameterElement) {
          reportLint(node);
        }
      }
    } else {
      List<AstNode>? elements;
      if (node is ListPattern) elements = node.elements;
      if (node is MapPattern) elements = node.elements;
      if (elements == null) return;
      for (var element in elements) {
        if (element is MapPatternEntry) {
          element = element.value;
        }
        if (element.element == parameterElement) {
          reportLint(node);
        }
      }
    }
  }

  void reportLint(AstNode node) {
    rule.reportAtNode(node, arguments: [parameter.name!.lexeme]);
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    if (!_isFormalParameterReassigned(parameter, node)) return;

    if (paramIsNotNullByDefault) {
      reportLint(node);
      return;
    }

    if (paramDefaultsToNull) {
      if (node.operator.type.lexeme == '??=') {
        if (hasBeenAssigned) {
          reportLint(node);
        }
        hasBeenAssigned = true;
      } else {
        reportLint(node);
      }
    }

    super.visitAssignmentExpression(node);
  }

  @override
  visitPatternAssignment(PatternAssignment node) {
    checkPatternElements(node.pattern);

    super.visitPatternAssignment(node);
  }

  @override
  visitPostfixExpression(PostfixExpression node) {
    if (paramIsNotNullByDefault) {
      var operand = node.operand;
      if (operand is SimpleIdentifier && operand.element == parameterElement) {
        reportLint(node);
      }
    }

    super.visitPostfixExpression(node);
  }

  @override
  visitPrefixExpression(PrefixExpression node) {
    if (paramIsNotNullByDefault) {
      var operand = node.operand;
      if (operand is SimpleIdentifier && operand.element == parameterElement) {
        reportLint(node);
      }
    }

    super.visitPrefixExpression(node);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

  _Visitor(this.rule);

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    _checkParameters(
      node.functionExpression.parameters,
      node.functionExpression.body,
    );
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    _checkParameters(node.parameters, node.body);
  }

  void _checkParameters(FormalParameterList? parameterList, FunctionBody body) {
    if (parameterList == null) return;

    for (var parameter in parameterList.parameters) {
      var declaredElement = parameter.declaredFragment?.element;
      if (declaredElement != null &&
          body.isPotentiallyMutatedInScope(declaredElement)) {
        var paramIsNotNullByDefault =
            parameter is SimpleFormalParameter ||
            _isDefaultFormalParameterWithDefaultValue(parameter);
        var paramDefaultsToNull =
            parameter is DefaultFormalParameter &&
            parameter.defaultValue == null;
        if (paramDefaultsToNull || paramIsNotNullByDefault) {
          body.accept(
            _DeclarationVisitor(
              parameter,
              rule,
              paramDefaultsToNull: paramDefaultsToNull,
              paramIsNotNullByDefault: paramIsNotNullByDefault,
            ),
          );
        }
      }
    }
  }
}

extension on AstNode {
  Element? get element => switch (this) {
    AssignedVariablePattern(:var element) => element,
    _ => null,
  };
}
